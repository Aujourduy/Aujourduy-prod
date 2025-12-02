require "test_helper"

class EventOccurrencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @event_occurrence = event_occurrences(:one)
    sign_in @user
  end

  test "should get edit" do
    get edit_event_occurrence_path(@event_occurrence)
    assert_response :success
  end

  test "should update event_occurrence" do
    patch event_occurrence_path(@event_occurrence), params: {
      event_occurrence: {
        override_description: "Updated description",
        start_date: @event_occurrence.start_date,
        end_date: @event_occurrence.end_date
      },
      update_option: "this_only"
    }
    assert_redirected_to event_path(@event_occurrence.event)
  end
end
