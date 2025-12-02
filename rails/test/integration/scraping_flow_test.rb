require "test_helper"

class ScrapingFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: 'bonjour.duy@gmail.com', password: 'password123', is_admin: true)
    @teacher = teachers(:one)
    @practice = practices(:one)
  end

  test "complete scraping to import flow" do
    # 1. Create scraped event
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com/test-event",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Integration Test Event",
          "description" => "Full flow test",
          "practice" => @practice.name,
          "source_url" => "https://example.com/test-event",
          "start_date" => 1.month.from_now.to_date.to_s
        },
        "venue" => {
          "name" => "Test Venue",
          "address_line1" => "123 Test St",
          "postal_code" => "75001",
          "city" => "Paris",
          "country" => "France"
        }
      },
      status: "pending",
      scraped_at: Time.current
    )

    # 2. Quality check
    quality_service = ScrapedEventQualityCheckService.new(scraped_event)
    assert quality_service.check!
    scraped_event.reload
    assert_empty scraped_event.quality_flags

    # 3. Validate
    scraped_event.validate!(@admin, "Approved for import")
    assert_equal "validated", scraped_event.status

    # 4. Import
    import_service = ScrapedEventImportService.new(scraped_event, @admin)
    assert import_service.import!

    # 5. Verify imported
    scraped_event.reload
    assert_equal "imported", scraped_event.status
    assert_not_nil scraped_event.imported_event
    assert_equal @admin, scraped_event.imported_by_user

    # 6. Verify event created
    imported_event = scraped_event.imported_event
    assert_equal "Integration Test Event", imported_event.title
    assert_equal @teacher, imported_event.principal_teacher
    assert_equal @practice, imported_event.practice
    assert imported_event.event_occurrences.any?
  end

  test "scraping flow with quality issues" do
    # Create event with missing data
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com/bad-event",
      json_data: {
        "teacher" => {
          "first_name" => "NonExistent",
          "last_name" => "Teacher"
        },
        "event" => {
          "title" => "Bad Event",
          "description" => "Missing info",
          "practice" => @practice.name,
          "source_url" => "https://example.com/bad",
          "start_date" => 1.month.ago.to_s # In past!
        }
      },
      status: "pending",
      scraped_at: Time.current
    )

    # Quality check should fail
    quality_service = ScrapedEventQualityCheckService.new(scraped_event)
    assert_not quality_service.check!

    scraped_event.reload
    assert scraped_event.has_quality_issues?
    assert_includes scraped_event.quality_flags.keys, "teacher_not_found"
    assert_includes scraped_event.quality_flags.keys, "date_in_past"
  end
end
