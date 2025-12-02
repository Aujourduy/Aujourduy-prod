require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit root_path
    click_on "Sign up"

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_on "Sign up"

    assert_text "Welcome"
  end

  test "user can sign in with email" do
    user = users(:one)

    visit root_path
    click_on "Sign in"

    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"

    click_on "Log in"

    assert_text "Signed in successfully"
  end

  test "user can sign out" do
    user = users(:one)
    sign_in_as user

    visit root_path
    click_on "Sign out"

    assert_text "Signed out successfully"
  end
end
