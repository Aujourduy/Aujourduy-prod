require "test_helper"
require "webmock/minitest"

class VenuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @venue = venues(:one)
    @user = users(:one)
    sign_in @user

    # Stub geocoding API for all venue operations
    stub_request(:get, /maps\.googleapis\.com\/maps\/api\/geocode\/json/)
      .to_return(
        status: 200,
        body: {
          results: [{
            geometry: {
              location: { lat: 48.8566, lng: 2.3522 }
            }
          }],
          status: "OK"
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  test "should get index" do
    get venues_url
    assert_response :success
  end

  test "should get new" do
    get new_venue_url
    assert_response :success
  end

  test "should create venue" do
    assert_difference("Venue.count") do
      post venues_url, params: { venue: {
        address_line1: "New Address",
        city: "New City",
        country: "France",
        name: "New Venue",
        postal_code: "99999"
      } }
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "should show venue" do
    get venue_url(@venue)
    assert_response :success
  end

  test "should get edit" do
    get edit_venue_url(@venue)
    assert_response :success
  end

  test "should update venue" do
    patch venue_url(@venue), params: { venue: { address_line1: @venue.address_line1, address_line2: @venue.address_line2, city: @venue.city, country: @venue.country, latitude: @venue.latitude, longitude: @venue.longitude, name: @venue.name, postal_code: @venue.postal_code, region: @venue.region } }
    assert_redirected_to venue_url(@venue)
  end

  test "should destroy venue" do
    # Create a venue without event_occurrences to allow deletion
    deletable_venue = Venue.create!(
      name: "Deletable Venue",
      country: "France",
      user: @user
    )

    assert_difference("Venue.count", -1) do
      delete venue_url(deletable_venue)
    end

    assert_redirected_to venues_url
  end
end
