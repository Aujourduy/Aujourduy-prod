require "application_system_test_case"

class FavoritesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @teacher = teachers(:one)
    sign_in_as @user
  end

  test "user can add teacher to favorites" do
    visit teacher_path(@teacher)
    click_on "Add to favorites"

    assert_text "Added to favorites"
  end

  test "user can remove teacher from favorites" do
    @user.favorite_teachers << @teacher

    visit teacher_path(@teacher)
    click_on "Remove from favorites"

    assert_text "Removed from favorites"
  end

  test "user can filter events by favorites" do
    visit dashboard_path
    check "Show only favorites"

    # Should show filtered results
    assert_selector ".event-card"
  end
end
