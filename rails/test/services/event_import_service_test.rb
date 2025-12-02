require "test_helper"

class EventImportServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email: 'bonjour.duy@gmail.com', password: 'password123')

    @practice = practices(:one)
    @practice.update!(name: "Yoga")

    @teacher = teachers(:one)
    @teacher.practices << @practice unless @teacher.practices.include?(@practice)
    @teacher.update!(first_name: "Jane", last_name: "Doe")

    @valid_json = {
      "teacher" => {
        "first_name" => @teacher.first_name,
        "last_name" => @teacher.last_name
      },
      "event" => {
        "title" => "Yoga Workshop",
        "description" => "Great workshop",
        "practice" => @practice.name,
        "source_url" => "https://example.com/event",
        "start_date" => 1.month.from_now.to_date.to_s
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

  test "initializes with admin user" do
    service = EventImportService.new
    assert_equal @admin, service.admin_user
    assert_empty service.errors
    assert_empty service.imported_events
    assert_empty service.skipped_events
  end

  test "raises if admin user not found" do
    @admin.destroy

    assert_raises(RuntimeError, match: /admin.*introuvable/) do
      EventImportService.new
    end
  end

  test "import_from_json succeeds with valid hash" do
    service = EventImportService.new
    result = service.import_from_json(@valid_json)

    assert result
    assert_empty service.errors
    assert_equal 1, service.imported_events.count
    assert_empty service.skipped_events

    event = service.imported_events.first
    assert_equal "Yoga Workshop", event.title
    assert_equal @teacher, event.principal_teacher
    assert_equal @practice, event.practice
  end

  test "import_from_json succeeds with valid JSON string" do
    service = EventImportService.new
    result = service.import_from_json(@valid_json.to_json)

    assert result
    assert_equal 1, service.imported_events.count
  end

  test "import_from_json succeeds with array of events" do
    events = [
      @valid_json,
      @valid_json.deep_dup.tap { |h| h["event"]["source_url"] = "https://example.com/event2" }
    ]

    service = EventImportService.new
    result = service.import_from_json(events)

    assert result
    assert_equal 2, service.imported_events.count
  end

  test "import_from_json fails with invalid JSON string" do
    service = EventImportService.new
    result = service.import_from_json("invalid json")

    assert_not result
    assert service.errors.any?
    assert_includes service.errors.first, "parsing JSON"
  end

  test "import_from_json skips event with missing teacher" do
    invalid_json = @valid_json.deep_dup
    invalid_json["teacher"] = {"first_name" => "NonExistent", "last_name" => "Teacher"}

    service = EventImportService.new
    result = service.import_from_json(invalid_json)

    assert_not result
    assert service.errors.any?
    assert_equal 1, service.skipped_events.count
    assert_includes service.skipped_events.first[:reason], "Teacher"
  end

  test "import_from_json skips event with missing practice" do
    invalid_json = @valid_json.deep_dup
    invalid_json["event"]["practice"] = "NonExistentPractice"

    service = EventImportService.new
    result = service.import_from_json(invalid_json)

    assert_not result
    assert_equal 1, service.skipped_events.count
    assert_includes service.skipped_events.first[:reason], "Practice"
  end

  test "import_from_json creates new venue if not exists" do
    new_venue_json = @valid_json.deep_dup
    new_venue_json["venue"]["name"] = "New Studio #{SecureRandom.hex(4)}"

    service = EventImportService.new
    result = service.import_from_json(new_venue_json)

    assert result
    event = service.imported_events.first
    assert_not_nil event.event_occurrences.first.venue
    # Venue name is normalized with titleize in before_save callback
    assert_equal new_venue_json["venue"]["name"].titleize, event.event_occurrences.first.venue.name
  end

  test "import_from_json reuses existing venue" do
    existing_venue = Venue.create!(
      name: "Existing Studio",
      city: "Paris",
      postal_code: "75001",
      address_line1: "123 Test",
      country: "France",
      user: @admin
    )

    venue_json = @valid_json.deep_dup
    venue_json["venue"] = {
      "name" => existing_venue.name,
      "city" => existing_venue.city,
      "postal_code" => existing_venue.postal_code
    }

    initial_venue_count = Venue.count

    service = EventImportService.new
    service.import_from_json(venue_json)

    assert_equal initial_venue_count, Venue.count # No new venue created
    event = service.imported_events.first
    assert_equal existing_venue.id, event.event_occurrences.first.venue.id
  end

  test "import_from_json handles online events without venue" do
    online_json = @valid_json.deep_dup
    online_json.delete("venue")
    online_json["event"]["is_online"] = true
    online_json["event"]["online_url"] = "https://zoom.us/j/123456"

    service = EventImportService.new
    result = service.import_from_json(online_json)

    assert result
    event = service.imported_events.first
    assert event.is_online
    assert_equal "https://zoom.us/j/123456", event.online_url
    assert_nil event.event_occurrences.first.venue
  end

  test "import_from_json creates event occurrence with correct dates" do
    service = EventImportService.new
    service.import_from_json(@valid_json)

    event = service.imported_events.first
    occurrence = event.event_occurrences.first

    assert_equal Date.parse(@valid_json["event"]["start_date"]), occurrence.start_date
    assert_not_nil occurrence.recurrence_id
  end

  test "import_from_json handles multi-day events" do
    multi_day_json = @valid_json.deep_dup
    start_date = 1.month.from_now.to_date
    multi_day_json["event"]["start_date"] = start_date.to_s
    multi_day_json["event"]["end_date"] = (start_date + 3.days).to_s

    service = EventImportService.new
    service.import_from_json(multi_day_json)

    event = service.imported_events.first
    occurrence = event.event_occurrences.first

    assert_equal start_date, occurrence.start_date
    assert_equal start_date + 3.days, occurrence.end_date
  end

  test "import_from_json handles times when provided" do
    with_times_json = @valid_json.deep_dup
    with_times_json["event"]["start_time"] = "10:00"
    with_times_json["event"]["end_time"] = "12:00"

    service = EventImportService.new
    service.import_from_json(with_times_json)

    event = service.imported_events.first
    occurrence = event.event_occurrences.first

    assert_equal 10, occurrence.start_time.hour
    assert_equal 12, occurrence.end_time.hour
  end

  test "import_from_json uses default times when not provided" do
    service = EventImportService.new
    service.import_from_json(@valid_json)

    event = service.imported_events.first
    occurrence = event.event_occurrences.first

    assert_not_nil occurrence.start_time
    assert_not_nil occurrence.end_time
  end

  test "import_from_json handles prices" do
    with_prices_json = @valid_json.deep_dup
    with_prices_json["event"]["price_normal"] = 100
    with_prices_json["event"]["price_reduced"] = 80
    with_prices_json["event"]["currency"] = "EUR"

    service = EventImportService.new
    service.import_from_json(with_prices_json)

    event = service.imported_events.first
    assert_equal 100.0, event.price_normal
    assert_equal 80.0, event.price_reduced
    assert_equal "EUR", event.currency
  end

  test "import_from_json uses default currency when not provided" do
    service = EventImportService.new
    service.import_from_json(@valid_json)

    event = service.imported_events.first
    assert_equal "EUR", event.currency
  end

  test "import_from_json skips event with missing required fields" do
    invalid_json = @valid_json.deep_dup
    invalid_json["event"].delete("title")

    service = EventImportService.new
    result = service.import_from_json(invalid_json)

    # Service returns true (no errors) even when skipping events
    assert result
    assert_equal 1, service.skipped_events.count
    assert_equal 0, service.imported_events.count
  end

  test "import_from_json handles transaction rollback on error" do
    invalid_json = @valid_json.deep_dup
    invalid_json["event"]["start_date"] = "invalid-date"

    initial_event_count = Event.count
    initial_occurrence_count = EventOccurrence.count

    service = EventImportService.new
    service.import_from_json(invalid_json)

    # Should not create any records due to rollback
    assert_equal initial_event_count, Event.count
    assert_equal initial_occurrence_count, EventOccurrence.count
  end
end
