require "application_system_test_case"

class AdminScrapingTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @admin.update!(admin: true)
    sign_in_as @admin
  end

  test "admin can view scraped events" do
    visit "/avo/resources/scraped_events"

    assert_text "Scraped events"
  end

  test "admin can validate scraped event" do
    scraped_event = scraped_events(:pending_event)

    visit "/avo/resources/scraped_events/#{scraped_event.id}"
    click_on "Validate"

    assert_text "validated"
  end

  test "admin can reject scraped event" do
    scraped_event = scraped_events(:pending_event)

    visit "/avo/resources/scraped_events/#{scraped_event.id}"
    click_on "Reject"

    fill_in "Notes", with: "Invalid event"
    click_on "Confirm"

    assert_text "rejected"
  end
end
