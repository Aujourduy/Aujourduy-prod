require "test_helper"

class HtmlCleanerServiceTest < ActiveSupport::TestCase
  test "clean! removes script tags" do
    html = "<html><script>alert('test')</script><p>Content</p></html>"
    service = HtmlCleanerService.new(html)
    result = service.clean!

    assert_not_includes result, "alert"
    assert_includes result, "Content"
  end

  test "clean! removes style tags" do
    html = "<style>.class { color: red; }</style><p>Content</p>"
    service = HtmlCleanerService.new(html)
    result = service.clean!

    assert_not_includes result, "color: red"
  end

  test "clean! keeps text content" do
    html = "<html><body><p>Important text</p></body></html>"
    service = HtmlCleanerService.new(html)
    result = service.clean!

    assert_includes result, "Important text"
  end

  test "clean! handles empty HTML" do
    service = HtmlCleanerService.new("")
    result = service.clean!

    assert_equal "", result
  end

  test "to_text class method works" do
    html = "<p>Test</p>"
    result = HtmlCleanerService.to_text(html)

    assert_includes result, "Test"
  end
end
