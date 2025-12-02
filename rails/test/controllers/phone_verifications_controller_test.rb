require "test_helper"

class PhoneVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get new" do
    get new_phone_verification_path
    assert_response :success
  end

  test "should create verification and send OTP" do
    skip "Requires Twilio configuration" # Integration test
  end

  test "should verify code" do
    skip "Requires Twilio configuration" # Integration test
  end

  test "should handle invalid code" do
    skip "Requires Twilio configuration" # Integration test
  end
end
