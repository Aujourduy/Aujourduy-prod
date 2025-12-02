require "test_helper"

class RecurrenceServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @teacher = teachers(:one)
    @practice = practices(:one)
    @venue = venues(:one)
  end

  test "initializes with event" do
    event = events(:one)
    service = RecurrenceService.new(event)

    assert_equal event, service.event
    assert_empty service.errors
  end

  test "create_recurring_event creates event with occurrences" do
    event_params = {
      title: "Weekly Yoga",
      description: "Regular class",
      principal_teacher_id: @teacher.id,
      practice_id: @practice.id,
      source_url: "https://example.com/yoga"
    }

    occurrence_params = {
      venue_id: @venue.id,
      start_date: 1.week.from_now.to_date.to_s,
      start_time: "10:00",
      end_time: "11:00"
    }

    recurrence_params = {
      frequency: "weekly",
      interval: 1,
      days_of_week: [1], # Monday
      end_date: 2.months.from_now.to_date
    }

    event = RecurrenceService.create_recurring_event(@user, event_params, occurrence_params, recurrence_params)

    assert_not_nil event
    assert event.is_recurring
    assert event.event_occurrences.count > 0
  end

  test "create_recurring_event handles errors" do
    event_params = { title: nil } # Invalid
    occurrence_params = {}
    recurrence_params = {}

    event = RecurrenceService.create_recurring_event(@user, event_params, occurrence_params, recurrence_params)

    assert_nil event
  end
end
