require "application_system_test_case"

class EventOccurrencesTest < ApplicationSystemTestCase
  setup do
    @event_occurrence = event_occurrences(:one)
  end

  test "visiting the index" do
    visit event_occurrences_url
    assert_selector "h1", text: "Event occurrences"
  end

  test "should create event occurrence" do
    visit event_occurrences_url
    click_on "New event occurrence"

    fill_in "End time", with: @event_occurrence.end_time
    fill_in "Event", with: @event_occurrence.event_id
    fill_in "Start time", with: @event_occurrence.start_time
    fill_in "Venue", with: @event_occurrence.venue_id
    click_on "Create Event occurrence"

    assert_text "Event occurrence was successfully created"
    click_on "Back"
  end

  test "should update Event occurrence" do
    visit event_occurrence_url(@event_occurrence)
    click_on "Edit this event occurrence", match: :first

    fill_in "End time", with: @event_occurrence.end_time.to_s
    fill_in "Event", with: @event_occurrence.event_id
    fill_in "Start time", with: @event_occurrence.start_time.to_s
    fill_in "Venue", with: @event_occurrence.venue_id
    click_on "Update Event occurrence"

    assert_text "Event occurrence was successfully updated"
    click_on "Back"
  end

  test "should destroy Event occurrence" do
    visit event_occurrence_url(@event_occurrence)
    click_on "Destroy this event occurrence", match: :first

    assert_text "Event occurrence was successfully destroyed"
  end
end
