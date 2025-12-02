require "test_helper"

class PracticesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @practice = practices(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get practices_path
    assert_response :success
  end

  test "should get show" do
    get practice_path(@practice)
    assert_response :success
  end

  test "should get new" do
    get new_practice_path
    assert_response :success
  end

  test "should get edit" do
    get edit_practice_path(@practice)
    assert_response :success
  end

  test "should create practice" do
    assert_difference('Practice.count', 1) do
      post practices_path, params: { practice: { name: "New Practice", description: "Test description" } }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "should update practice" do
    patch practice_path(@practice), params: { practice: { name: "Updated Name" } }
    assert_redirected_to practice_path(@practice)
    @practice.reload
    assert_equal "Updated Name", @practice.name
  end

  test "should destroy practice" do
    # Create a practice without events to allow deletion
    deletable_practice = Practice.create!(name: "Deletable", user: @user)

    assert_difference('Practice.count', -1) do
      delete practice_path(deletable_practice)
    end
    assert_redirected_to practices_path
  end
end
