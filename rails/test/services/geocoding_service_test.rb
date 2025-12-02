require "test_helper"
require "webmock/minitest"

class GeocodingServiceTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_api_key"
    ENV['GOOGLE_MAPS_API_KEY'] = @api_key
    @address = "1600 Amphitheatre Parkway, Mountain View, CA"
    @encoded_address = URI.encode_www_form_component(@address)
    @url = "#{GeocodingService::BASE_URL}?address=#{@encoded_address}&key=#{@api_key}"
  end

  teardown do
    WebMock.reset!
  end

  test "geocode returns success with valid address" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "OK",
        "results" => [
          {
            "geometry" => {
              "location" => {
                "lat" => 37.422408,
                "lng" => -122.084068
              }
            },
            "formatted_address" => "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA"
          }
        ]
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert result[:success]
    assert_equal 37.422408, result[:latitude]
    assert_equal -122.084068, result[:longitude]
    assert_equal "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA", result[:formatted_address]
  end

  test "geocode rounds coordinates to 6 decimals" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "OK",
        "results" => [
          {
            "geometry" => {
              "location" => {
                "lat" => 37.42240812345678,
                "lng" => -122.08406812345678
              }
            },
            "formatted_address" => "Test Address"
          }
        ]
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert_equal 37.422408, result[:latitude]  # round(6) gives 37.422408, not 37.42241
    assert_equal -122.084068, result[:longitude]
  end

  test "geocode returns error when address not found" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "ZERO_RESULTS",
        "results" => []
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "Adresse non trouvée"
  end

  test "geocode returns error when API key missing" do
    ENV.delete('GOOGLE_MAPS_API_KEY')

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_equal "API key manquante", result[:error]
  end

  test "geocode returns error on HTTP error" do
    stub_request(:get, @url).to_return(status: 500)

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "Erreur API : 500"
  end

  test "geocode returns error on network error" do
    stub_request(:get, @url).to_raise(SocketError.new("Failed to connect"))

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "Erreur réseau"
  end

  test "geocode handles OVER_QUERY_LIMIT status" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "OVER_QUERY_LIMIT",
        "results" => []
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "OVER_QUERY_LIMIT"
  end

  test "geocode handles INVALID_REQUEST status" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "INVALID_REQUEST",
        "results" => []
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "INVALID_REQUEST"
  end

  test "geocode encodes special characters in address" do
    special_address = "123 Rue de l'Église, Montréal, QC"
    encoded = URI.encode_www_form_component(special_address)
    url = "#{GeocodingService::BASE_URL}?address=#{encoded}&key=#{@api_key}"

    stub_request(:get, url).to_return(
      status: 200,
      body: {
        "status" => "OK",
        "results" => [
          {
            "geometry" => {
              "location" => { "lat" => 45.5017, "lng" => -73.5673 }
            },
            "formatted_address" => "Montreal, QC, Canada"
          }
        ]
      }.to_json
    )

    result = GeocodingService.geocode(special_address)

    assert result[:success]
    assert_requested :get, url
  end

  test "geocode handles empty results array" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: {
        "status" => "OK",
        "results" => []
      }.to_json
    )

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
  end

  test "geocode handles malformed JSON response" do
    stub_request(:get, @url).to_return(
      status: 200,
      body: "not json"
    )

    result = GeocodingService.geocode(@address)

    assert_not result[:success]
    assert_includes result[:error], "Erreur réseau"
  end

  test "geocode with real coordinates" do
    address = "Tour Eiffel, Paris"
    encoded_address = URI.encode_www_form_component(address)
    url = "#{GeocodingService::BASE_URL}?address=#{encoded_address}&key=#{@api_key}"

    stub_request(:get, url).to_return(
      status: 200,
      body: {
        "status" => "OK",
        "results" => [
          {
            "geometry" => {
              "location" => {
                "lat" => 48.856614,
                "lng" => 2.352222
              }
            },
            "formatted_address" => "Tour Eiffel, Paris, France"
          }
        ]
      }.to_json
    )

    result = GeocodingService.geocode(address)

    assert result[:success]
    assert_equal 48.856614, result[:latitude]
    assert_equal 2.352222, result[:longitude]
  end
end
