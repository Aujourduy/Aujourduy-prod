require "application_system_test_case"

class VenuesTest < ApplicationSystemTestCase
  setup do
    @venue = venues(:one)
  end

  test "visiting the index" do
    visit venues_url
    assert_selector "h1", text: "Venues"
  end

  test "should create venue" do
    visit venues_url
    click_on "New venue"

    fill_in "Address line1", with: @venue.address_line1
    fill_in "Address line2", with: @venue.address_line2
    fill_in "City", with: @venue.city
    fill_in "Country", with: @venue.country
    fill_in "Latitude", with: @venue.latitude
    fill_in "Longitude", with: @venue.longitude
    fill_in "Name", with: @venue.name
    fill_in "Postal code", with: @venue.postal_code
    fill_in "Region", with: @venue.region
    click_on "Create Venue"

    assert_text "Venue was successfully created"
    click_on "Back"
  end

  test "should update Venue" do
    visit venue_url(@venue)
    click_on "Edit this venue", match: :first

    fill_in "Address line1", with: @venue.address_line1
    fill_in "Address line2", with: @venue.address_line2
    fill_in "City", with: @venue.city
    fill_in "Country", with: @venue.country
    fill_in "Latitude", with: @venue.latitude
    fill_in "Longitude", with: @venue.longitude
    fill_in "Name", with: @venue.name
    fill_in "Postal code", with: @venue.postal_code
    fill_in "Region", with: @venue.region
    click_on "Update Venue"

    assert_text "Venue was successfully updated"
    click_on "Back"
  end

  test "should destroy Venue" do
    visit venue_url(@venue)
    click_on "Destroy this venue", match: :first

    assert_text "Venue was successfully destroyed"
  end
end
