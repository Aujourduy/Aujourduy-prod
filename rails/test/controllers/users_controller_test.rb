require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should show user profile when logged in" do
    sign_in @user
    get profile_path
    assert_response :success
  end

  test "should update user" do
    sign_in @user
    patch profile_path, params: { user: { first_name: "Updated", last_name: "Name" } }
    assert_response :redirect
  end

  test "should require authentication" do
    get profile_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should toggle filter mode" do
    sign_in @user
    assert_equal "union", @user.filter_mode

    patch toggle_filter_mode_path
    @user.reload
    assert_equal "intersection", @user.filter_mode
  end
end
