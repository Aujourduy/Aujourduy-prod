require "test_helper"

class ScrapedEventTest < ActiveSupport::TestCase
  # ========== Validations ==========

  test "should be valid with all required attributes" do
    scraped_event = ScrapedEvent.new(
      source_url: "https://example.com/event",
      json_data: { "teacher" => { "first_name" => "John" }, "event" => { "title" => "Test" } },
      status: "pending"
    )
    assert scraped_event.valid?
  end

  test "should require source_url" do
    scraped_event = ScrapedEvent.new(
      json_data: { "test" => "data" },
      status: "pending"
    )
    assert_not scraped_event.valid?
    assert_includes scraped_event.errors[:source_url], "can't be blank"
  end

  test "should require json_data" do
    scraped_event = ScrapedEvent.new(
      source_url: "https://example.com",
      status: "pending"
    )
    assert_not scraped_event.valid?
    assert_includes scraped_event.errors[:json_data], "can't be blank"
  end

  test "should require status" do
    scraped_event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: { "test" => "data" },
      status: nil
    )
    assert_not scraped_event.valid?
    assert_includes scraped_event.errors[:status], "can't be blank"
  end

  test "should only allow valid status values" do
    valid_statuses = %w[pending validated rejected imported]
    invalid_statuses = %w[unknown processing failed]

    valid_statuses.each do |status|
      scraped_event = ScrapedEvent.new(
        source_url: "https://example.com",
        json_data: { "test" => "data" },
        status: status
      )
      assert scraped_event.valid?, "#{status} should be valid"
    end

    invalid_statuses.each do |status|
      scraped_event = ScrapedEvent.new(
        source_url: "https://example.com",
        json_data: { "test" => "data" },
        status: status
      )
      assert_not scraped_event.valid?, "#{status} should be invalid"
      assert_includes scraped_event.errors[:status], "is not included in the list"
    end
  end

  # ========== Callbacks ==========

  test "should set scraped_at on create if not provided" do
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: { "test" => "data" },
      status: "pending"
    )
    assert_not_nil scraped_event.scraped_at
    assert_in_delta Time.current, scraped_event.scraped_at, 1.second
  end

  test "should not override scraped_at if already set" do
    custom_time = 2.days.ago
    scraped_event = ScrapedEvent.create!(
      source_url: "https://example.com",
      json_data: { "test" => "data" },
      status: "pending",
      scraped_at: custom_time
    )
    assert_equal custom_time.to_i, scraped_event.scraped_at.to_i
  end

  # ========== Scopes ==========

  test "pending scope returns only pending events" do
    pending_events = ScrapedEvent.pending
    assert_includes pending_events, scraped_events(:pending_event)
    assert_not_includes pending_events, scraped_events(:validated_event)
    assert_not_includes pending_events, scraped_events(:rejected_event)
    assert_not_includes pending_events, scraped_events(:imported_event)
  end

  test "validated scope returns only validated events" do
    validated_events = ScrapedEvent.validated
    assert_includes validated_events, scraped_events(:validated_event)
    assert_not_includes validated_events, scraped_events(:pending_event)
    assert_not_includes validated_events, scraped_events(:rejected_event)
  end

  test "rejected scope returns only rejected events" do
    rejected_events = ScrapedEvent.rejected
    assert_includes rejected_events, scraped_events(:rejected_event)
    assert_not_includes rejected_events, scraped_events(:pending_event)
    assert_not_includes rejected_events, scraped_events(:validated_event)
  end

  test "imported scope returns only imported events" do
    imported_events = ScrapedEvent.imported
    assert_includes imported_events, scraped_events(:imported_event)
    assert_not_includes imported_events, scraped_events(:pending_event)
  end

  test "recent scope orders by scraped_at descending" do
    recent_events = ScrapedEvent.recent
    assert_equal scraped_events(:pending_event), recent_events.first
    assert_equal scraped_events(:event_with_quality_issues), recent_events.last
  end

  # ========== Instance Methods ==========

  test "validate! should change status to validated and set timestamps" do
    event = scraped_events(:pending_event)
    user = users(:one)

    event.validate!(user, "Approved by admin")

    assert_equal "validated", event.status
    assert_equal user, event.validated_by_user
    assert_not_nil event.validated_at
    assert_equal "Approved by admin", event.validation_notes
    assert_in_delta Time.current, event.validated_at, 1.second
  end

  test "validate! should work without notes" do
    event = scraped_events(:pending_event)
    user = users(:one)

    event.validate!(user)

    assert_equal "validated", event.status
    assert_equal user, event.validated_by_user
    assert_nil event.validation_notes
  end

  test "reject! should change status to rejected" do
    event = scraped_events(:pending_event)
    user = users(:one)

    event.reject!(user, "Invalid event")

    assert_equal "rejected", event.status
    assert_equal user, event.validated_by_user
    assert_not_nil event.validated_at
    assert_equal "Invalid event", event.validation_notes
  end

  test "reject! should require notes" do
    event = scraped_events(:pending_event)
    user = users(:one)

    assert_raises(ArgumentError) do
      event.reject!(user)
    end
  end

  test "mark_as_imported! should update status and set event reference on success" do
    event = scraped_events(:validated_event)
    imported_event = events(:one)
    user = users(:one)

    event.mark_as_imported!(imported_event, nil, user)

    assert_equal "imported", event.status
    assert_equal imported_event, event.imported_event
    assert_equal user, event.imported_by_user
    assert_not_nil event.imported_at
    assert_nil event.import_error
  end

  test "mark_as_imported! should set error and keep status pending on failure" do
    event = scraped_events(:validated_event)
    error_message = "Teacher not found"

    event.mark_as_imported!(nil, error_message)

    assert_equal "pending", event.status
    assert_nil event.imported_event
    assert_equal error_message, event.import_error
  end

  test "teacher_name should return formatted teacher name" do
    event = scraped_events(:pending_event)
    assert_equal "Jane Doe", event.teacher_name
  end

  test "teacher_name should return nil if json_data is empty" do
    event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: {},
      status: "pending"
    )
    assert_nil event.teacher_name
  end

  test "teacher_name should return nil if teacher data is missing" do
    event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: { "event" => { "title" => "Test" } },
      status: "pending"
    )
    assert_nil event.teacher_name
  end

  test "event_title should return event title from json_data" do
    event = scraped_events(:pending_event)
    assert_equal "Yoga Retreat 2025", event.event_title
  end

  test "event_title should return nil if json_data is empty" do
    event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: {},
      status: "pending"
    )
    assert_nil event.event_title
  end

  test "event_date should return start date from json_data" do
    event = scraped_events(:pending_event)
    assert_equal "2025-06-15", event.event_date
  end

  test "event_date should return nil if event data is missing" do
    event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: { "teacher" => { "first_name" => "John" } },
      status: "pending"
    )
    assert_nil event.event_date
  end

  test "has_quality_issues? should return true when quality_flags present" do
    event = scraped_events(:event_with_quality_issues)
    assert event.has_quality_issues?
  end

  test "has_quality_issues? should return false when quality_flags empty" do
    event = scraped_events(:pending_event)
    assert_not event.has_quality_issues?
  end

  test "has_quality_issues? should return false when quality_flags nil" do
    event = ScrapedEvent.new(
      source_url: "https://example.com",
      json_data: { "test" => "data" },
      status: "pending",
      quality_flags: nil
    )
    assert_not event.has_quality_issues?
  end

  test "quality_issues_list should return array of issue keys" do
    event = scraped_events(:event_with_quality_issues)
    issues = event.quality_issues_list

    assert_includes issues, "missing_start_date"
    assert_includes issues, "teacher_incomplete"
    assert_includes issues, "missing_description"
    assert_equal 3, issues.length
  end

  test "quality_issues_list should return empty array when no issues" do
    event = scraped_events(:pending_event)
    assert_equal [], event.quality_issues_list
  end

  # ========== Associations ==========

  test "should belong to teacher_url optionally" do
    event = scraped_events(:pending_event)
    assert_respond_to event, :teacher_url
    assert_nil event.teacher_url # optional
  end

  test "should belong to validated_by_user optionally" do
    event = scraped_events(:pending_event)
    assert_respond_to event, :validated_by_user
    assert_nil event.validated_by_user # not validated yet
  end

  test "should belong to imported_by_user optionally" do
    event = scraped_events(:pending_event)
    assert_respond_to event, :imported_by_user
    assert_nil event.imported_by_user
  end

  test "should belong to imported_event optionally" do
    event = scraped_events(:pending_event)
    assert_respond_to event, :imported_event
    assert_nil event.imported_event
  end

  # ========== JSON Data Handling ==========

  test "should store and retrieve complex json_data" do
    complex_data = {
      "teacher" => {
        "first_name" => "Jean",
        "last_name" => "Dupont",
        "email" => "jean@example.com",
        "phone" => "+33612345678",
        "bio" => "Experienced yoga teacher"
      },
      "event" => {
        "title" => "Advanced Yoga Workshop",
        "description" => "Three day intensive",
        "start_date" => "2025-08-15",
        "end_date" => "2025-08-17",
        "price" => 350,
        "currency" => "EUR",
        "max_participants" => 20
      },
      "venue" => {
        "name" => "Studio Harmony",
        "address" => "123 Rue de la Paix",
        "city" => "Paris",
        "country" => "France",
        "postal_code" => "75001"
      },
      "metadata" => {
        "scraper_version" => "2.0",
        "confidence_score" => 0.95
      }
    }

    event = ScrapedEvent.create!(
      source_url: "https://example.com/complex",
      json_data: complex_data,
      status: "pending"
    )

    event.reload
    assert_equal complex_data, event.json_data
    assert_equal "Jean Dupont", event.teacher_name
    assert_equal "Advanced Yoga Workshop", event.event_title
  end

  # ========== Edge Cases ==========

  test "should handle multiple status transitions" do
    event = scraped_events(:pending_event)
    user = users(:one)

    # pending -> validated
    event.validate!(user, "Initial approval")
    assert_equal "validated", event.status

    # validated -> rejected (if quality check fails later)
    event.update!(status: "pending")
    event.reject!(user, "Found issues on review")
    assert_equal "rejected", event.status
  end

  test "should handle import error then success" do
    event = scraped_events(:validated_event)
    imported_event = events(:one)
    user = users(:one)

    # First attempt fails
    event.mark_as_imported!(nil, "Database error")
    assert_equal "pending", event.status
    assert_equal "Database error", event.import_error

    # Second attempt succeeds
    event.mark_as_imported!(imported_event, nil, user)
    assert_equal "imported", event.status
    assert_nil event.import_error
    assert_equal imported_event, event.imported_event
  end
end
