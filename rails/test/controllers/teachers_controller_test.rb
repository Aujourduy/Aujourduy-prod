require "test_helper"

class TeachersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = teachers(:one)
    @practice = practices(:one)
    @teacher.practices << @practice unless @teacher.practices.include?(@practice)
    sign_in @teacher.user
  end

  test "should get index" do
    get teachers_url
    assert_response :success
  end

  test "should get new" do
    get new_teacher_url
    assert_response :success
  end

  test "should create teacher" do
    assert_difference("Teacher.count") do
      post teachers_url, params: { teacher: {
        bio: @teacher.bio,
        contact_email: "new_teacher@example.com",  # unique email
        first_name: "New",
        last_name: "Teacher",
        phone: @teacher.phone,
        practice_ids: [@practice.id]
      } }
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "should show teacher" do
    get teacher_url(@teacher)
    assert_response :success
  end

  test "should get edit" do
    get edit_teacher_url(@teacher)
    assert_response :success
  end

  test "should update teacher" do
    patch teacher_url(@teacher), params: { teacher: { bio: @teacher.bio, contact_email: @teacher.contact_email, first_name: @teacher.first_name, last_name: @teacher.last_name, phone: @teacher.phone, photo_url: @teacher.photo_url, user_id: @teacher.user_id } }
    assert_redirected_to teacher_url(@teacher)
  end

  test "should destroy teacher" do
    assert_difference("Teacher.count", -1) do
      delete teacher_url(@teacher)
    end

    assert_redirected_to teachers_url
  end
end
