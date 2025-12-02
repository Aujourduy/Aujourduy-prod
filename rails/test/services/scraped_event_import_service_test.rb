require "test_helper"

class ScrapedEventImportServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = User.create!(email: 'bonjour.duy@gmail.com', password: 'password123')

    @practice = practices(:one)
    @practice.update!(name: "Yoga")

    @teacher = teachers(:one)
    @teacher.practices << @practice unless @teacher.practices.include?(@practice)
    @teacher.update!(first_name: "Jane", last_name: "Doe")

    @valid_json_data = {
      "teacher" => {
        "first_name" => @teacher.first_name,
        "last_name" => @teacher.last_name
      },
      "event" => {
        "title" => "Yoga Workshop",
        "description" => "Great workshop",
        "practice" => @practice.name,
        "source_url" => "https://example.com/event",
        "start_date" => 1.month.from_now.to_s
      },
      "venue" => {
        "name" => "Studio Harmony",
        "address_line1" => "123 Rue Example",
        "postal_code" => "75001",
        "city" => "Paris",
        "country" => "France"
      }
    }
  end

  test "initializes correctly" do
    scraped_event = scraped_events(:validated_event)
    service = ScrapedEventImportService.new(scraped_event, @user)

    assert_equal scraped_event, service.scraped_event
    assert_equal @user, service.user
    assert_empty service.errors
  end

  test "import! fails if scraped_event not validated" do
    scraped_event = scraped_events(:pending_event)
    service = ScrapedEventImportService.new(scraped_event, @user)

    result = service.import!

    assert_not result
    assert_includes service.errors.first, "doit être validé"
  end

  test "import! fails if json_data missing" do
    scraped_event = scraped_events(:validated_event)
    scraped_event.update_column(:json_data, {})  # empty hash is not present
    service = ScrapedEventImportService.new(scraped_event, @user)

    result = service.import!

    assert_not result
    assert_includes service.errors.first, "json_data manquant"
  end

  test "import! succeeds with valid validated event" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com/test",
      json_data: @valid_json_data,
      status: "validated",
      scraped_at: Time.current
    )

    service = ScrapedEventImportService.new(scraped_event, @user)
    result = service.import!

    assert result
    assert_empty service.errors
    scraped_event.reload
    assert_equal "imported", scraped_event.status
    assert_not_nil scraped_event.imported_event
    assert_equal @user, scraped_event.imported_by_user
  end

  test "import! handles failure and sets error message" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com/test",
      json_data: {
        "teacher" => {
          "first_name" => "NonExistent",
          "last_name" => "Teacher"
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "validated",
      scraped_at: Time.current
    )

    service = ScrapedEventImportService.new(scraped_event, @user)
    result = service.import!

    assert_not result
    assert service.errors.any?
    scraped_event.reload
    assert_equal "pending", scraped_event.status
    assert_not_nil scraped_event.import_error
  end

  test "import_batch! processes multiple events" do
    event1 = ScrapedEvent.create!(
      source_url: "https://example.com/1",
      json_data: @valid_json_data,
      status: "validated",
      scraped_at: Time.current
    )

    event2 = ScrapedEvent.create!(
      source_url: "https://example.com/2",
      json_data: @valid_json_data.deep_dup.tap { |h| h["event"]["source_url"] = "https://example.com/2" },
      status: "validated",
      scraped_at: Time.current
    )

    results = ScrapedEventImportService.import_batch!([event1, event2], @user)

    assert_equal 2, results[:success].count
    assert_empty results[:failed]
    assert_empty results[:skipped]
  end

  test "import_batch! skips non-validated events" do
    event1 = scraped_events(:pending_event)
    event2 = scraped_events(:rejected_event)

    results = ScrapedEventImportService.import_batch!([event1, event2], @user)

    assert_empty results[:success]
    assert_empty results[:failed]
    assert_equal 2, results[:skipped].count
  end

  test "import_batch! separates success and failures" do
    valid_event = ScrapedEvent.create!(
      source_url: "https://example.com/valid",
      json_data: @valid_json_data,
      status: "validated",
      scraped_at: Time.current
    )

    invalid_event = ScrapedEvent.create!(
      source_url: "https://example.com/invalid",
      json_data: {
        "teacher" => {
          "first_name" => "NonExistent",
          "last_name" => "Teacher"
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/invalid",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "validated",
      scraped_at: Time.current
    )

    results = ScrapedEventImportService.import_batch!([valid_event, invalid_event], @user)

    assert_equal 1, results[:success].count
    assert_equal 1, results[:failed].count
    assert_empty results[:skipped]
  end

  test "import_all_validated! imports only validated not-yet-imported events" do
    # Create validated events
    event1 = ScrapedEvent.create!(
      source_url: "https://example.com/1",
      json_data: @valid_json_data,
      status: "validated",
      scraped_at: Time.current
    )

    event2 = ScrapedEvent.create!(
      source_url: "https://example.com/2",
      json_data: @valid_json_data.deep_dup.tap { |h| h["event"]["source_url"] = "https://example.com/2" },
      status: "validated",
      scraped_at: Time.current
    )

    # Already imported event
    imported_event = scraped_events(:imported_event)

    results = ScrapedEventImportService.import_all_validated!(@user)

    # Should import new validated events, skip already imported
    assert results[:success].count >= 2
    assert_not_includes results[:success].map(&:id), imported_event.id
  end

  test "import! handles exceptions gracefully" do
    scraped_event = scraped_events(:validated_event)
    service = ScrapedEventImportService.new(scraped_event, @user)

    # Mock import_service to raise an exception
    service.import_service.stubs(:import_from_json).raises(StandardError.new("Database error"))

    result = service.import!

    assert_not result
    assert_includes service.errors.first, "Database error"
    scraped_event.reload
    assert_equal "pending", scraped_event.status
    assert_not_nil scraped_event.import_error
  end
end
