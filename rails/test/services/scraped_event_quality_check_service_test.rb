require "test_helper"

class ScrapedEventQualityCheckServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)

    @practice = practices(:one)
    @practice.update!(name: "Yoga")

    @teacher = teachers(:one)
    @teacher.practices << @practice unless @teacher.practices.include?(@practice)
    @teacher.update!(first_name: "Jane", last_name: "Doe")

    @venue = venues(:one)
    @venue.update!(
      name: "Studio Harmony",
      address_line1: "123 Rue de la Paix",
      postal_code: "75001",
      city: "Paris",
      country: "France"
    )
  end

  # ========== Initialization & Basic Checks ==========

  test "initializes with scraped_event" do
    scraped_event = scraped_events(:pending_event)
    service = ScrapedEventQualityCheckService.new(scraped_event)

    assert_equal scraped_event, service.scraped_event
    assert_empty service.quality_flags
  end

  test "check! handles empty json_data" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: { "temp" => "data" },  # temporary data to pass validation
      status: "pending",
      scraped_at: Time.current
    )
    # Bypass validation to test empty json_data edge case
    scraped_event.update_column(:json_data, {})

    service = ScrapedEventQualityCheckService.new(scraped_event)
    # Empty json_data means no event data, so check! returns false
    # This is expected behavior - if there's no data to check, validation fails
    result = service.check!

    assert_not result  # No data = validation fails
  end

  test "check! updates quality_flags in database" do
    scraped_event = scraped_events(:pending_event)
    service = ScrapedEventQualityCheckService.new(scraped_event)

    service.check!
    scraped_event.reload

    assert_not_nil scraped_event.quality_flags
  end

  # ========== Teacher Checks ==========

  test "flags missing teacher as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => "NonExistent",
          "last_name" => "Teacher"
        },
        "event" => {
          "title" => "Test Event",
          "description" => "Description",
          "practice" => "Yoga",
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert_not result # Should return false due to critical error
    assert service.quality_flags.key?("teacher_not_found")
    assert_equal "error", service.quality_flags["teacher_not_found"][:severity]
    assert service.has_critical_errors?
  end

  test "passes when teacher exists" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Test Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert result
    assert_not service.quality_flags.key?("teacher_not_found")
  end

  # ========== Practice Checks ==========

  test "flags missing practice as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Test Event",
          "description" => "Description",
          "practice" => "NonExistentPractice",
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert_not result
    assert service.quality_flags.key?("practice_not_found")
    assert_equal "error", service.quality_flags["practice_not_found"][:severity]
  end

  test "practice check is case insensitive" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Test Event",
          "description" => "Description",
          "practice" => "YOGA", # uppercase
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert result
    assert_not service.quality_flags.key?("practice_not_found")
  end

  # ========== Venue Coherence Checks ==========

  test "flags online event without online_url as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Online Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "is_online" => true
          # missing online_url
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("missing_online_url")
    assert_equal "error", service.quality_flags["missing_online_url"][:severity]
  end

  test "flags in-person event without venue as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "In-Person Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "is_online" => false
          # missing venue
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("missing_venue")
    assert_equal "error", service.quality_flags["missing_venue"][:severity]
  end

  test "flags incomplete venue as warning" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s
        },
        "venue" => {
          "name" => "Studio",
          # missing address_line1, postal_code, city, country
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("incomplete_venue")
    assert_equal "warning", service.quality_flags["incomplete_venue"][:severity]
  end

  # ========== Date Validity Checks ==========

  test "flags date in past as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Past Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.ago.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert_not result
    assert service.quality_flags.key?("date_in_past")
    assert_equal "error", service.quality_flags["date_in_past"][:severity]
    assert service.has_critical_errors?
  end

  test "flags date too far in future as warning" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Far Future Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => (Date.today + 2.years).to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("date_too_far")
    assert_equal "warning", service.quality_flags["date_too_far"][:severity]
  end

  test "flags invalid date range when end before start" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Invalid Range Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => "2025-12-31",
          "end_date" => "2025-12-01"
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("invalid_date_range")
    assert_equal "error", service.quality_flags["invalid_date_range"][:severity]
  end

  test "flags invalid date format" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Invalid Date Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => "not-a-date"
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("invalid_date_format")
    assert_equal "error", service.quality_flags["invalid_date_format"][:severity]
  end

  # ========== Price Coherence Checks ==========

  test "flags negative price as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "price_normal" => -50
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("negative_price")
    assert_equal "error", service.quality_flags["negative_price"][:severity]
  end

  test "flags anomalously high price as warning" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Expensive Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "price_normal" => 1000
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("price_anomaly")
    assert_equal "warning", service.quality_flags["price_anomaly"][:severity]
  end

  test "flags reduced price higher than normal as warning" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "price_normal" => 100,
          "price_reduced" => 150
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("price_incoherence")
    assert_equal "warning", service.quality_flags["price_incoherence"][:severity]
  end

  test "flags invalid currency as warning" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.from_now.to_s,
          "price_normal" => 100,
          "currency" => "XYZ" # invalid currency
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    assert service.quality_flags.key?("invalid_currency")
    assert_equal "warning", service.quality_flags["invalid_currency"][:severity]
  end

  # ========== Required Fields Check ==========

  test "flags missing required fields as error" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "practice" => "Yoga"  # Add at least practice so it's not completely empty, but still missing required fields
          # missing title, description, source_url, start_date
        }
      },
      status: "pending",
      scraped_at: Time.current
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert_not result, "check! should return false when required fields are missing"
    assert service.quality_flags.key?("missing_required_fields"), "Should have missing_required_fields flag"
    assert_equal "error", service.quality_flags["missing_required_fields"][:severity]
    assert service.has_critical_errors?, "Should have critical errors"
  end

  # ========== Counters ==========

  test "errors_count returns number of errors" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => "NonExistent",
          "last_name" => "Teacher"
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => "NonExistent",
          "source_url" => "https://example.com/event",
          "start_date" => 1.month.ago.to_s
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    # Should have at least: teacher_not_found, practice_not_found, date_in_past
    assert service.errors_count >= 3
  end

  test "warnings_count returns number of warnings" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Event",
          "description" => "Description",
          "practice" => @practice.name,
          "source_url" => "https://example.com/event",
          "start_date" => (Date.today + 2.years).to_s,
          "price_normal" => 1000
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    service.check!

    # Should have: date_too_far, price_anomaly
    assert service.warnings_count >= 2
  end

  # ========== Perfect Event ==========

  test "perfect event passes all checks" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com/perfect",
      json_data: {
        "teacher" => {
          "first_name" => @teacher.first_name,
          "last_name" => @teacher.last_name
        },
        "event" => {
          "title" => "Perfect Yoga Workshop",
          "description" => "A wonderful workshop",
          "practice" => @practice.name,
          "source_url" => "https://example.com/perfect",
          "start_date" => 1.month.from_now.to_s,
          "price_normal" => 50,
          "price_reduced" => 40,
          "currency" => "EUR"
        },
        "venue" => {
          "name" => @venue.name,
          "address_line1" => "123 Rue Example",
          "postal_code" => "75001",
          "city" => "Paris",
          "country" => "France"
        }
      },
      status: "pending"
    )

    service = ScrapedEventQualityCheckService.new(scraped_event)
    result = service.check!

    assert result
    assert_not service.has_critical_errors?
    assert_equal 0, service.errors_count
  end
end
