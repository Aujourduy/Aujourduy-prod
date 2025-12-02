require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "should get manifest" do
    get pwa_manifest_path
    assert_response :success
    assert_equal "application/json", @response.media_type
  end

  test "should get service worker" do
    get "/service-worker.js"
    assert_response :success
  end
end
