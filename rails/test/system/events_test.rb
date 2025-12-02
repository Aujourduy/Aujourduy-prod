require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    @event = events(:one)
  end

  test "visiting the index" do
    visit events_url
    assert_selector "h1", text: "Events"
  end

  test "should create event" do
    visit events_url
    click_on "New event"

    fill_in "Category", with: @event.category
    fill_in "Currency", with: @event.currency
    fill_in "Description", with: @event.description
    check "Is free" if @event.is_free
    check "Is in person" if @event.is_in_person
    check "Is online" if @event.is_online
    fill_in "Price normal", with: @event.price_normal
    fill_in "Price reduced", with: @event.price_reduced
    fill_in "Reduced price description", with: @event.reduced_price_description
    fill_in "Title", with: @event.title
    fill_in "User", with: @event.user_id
    click_on "Create Event"

    assert_text "Event was successfully created"
    click_on "Back"
  end

  test "should update Event" do
    visit event_url(@event)
    click_on "Edit this event", match: :first

    fill_in "Category", with: @event.category
    fill_in "Currency", with: @event.currency
    fill_in "Description", with: @event.description
    check "Is free" if @event.is_free
    check "Is in person" if @event.is_in_person
    check "Is online" if @event.is_online
    fill_in "Price normal", with: @event.price_normal
    fill_in "Price reduced", with: @event.price_reduced
    fill_in "Reduced price description", with: @event.reduced_price_description
    fill_in "Title", with: @event.title
    fill_in "User", with: @event.user_id
    click_on "Update Event"

    assert_text "Event was successfully updated"
    click_on "Back"
  end

  test "should destroy Event" do
    visit event_url(@event)
    click_on "Destroy this event", match: :first

    assert_text "Event was successfully destroyed"
  end
end
