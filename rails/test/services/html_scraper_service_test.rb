require "test_helper"
require "webmock/minitest"

class HtmlScraperServiceTest < ActiveSupport::TestCase
  test "initializes with url" do
    service = HtmlScraperService.new("https://example.com")
    assert_equal "https://example.com", service.url
    assert_nil service.html_content
    assert_nil service.error
  end

  test "scrape! returns HTML on success" do
    stub_request(:post, "http://playwright:3000/render")
      .with(body: { url: "https://example.com" }.to_json)
      .to_return(status: 200, body: "<html><body>Test</body></html>")

    service = HtmlScraperService.new("https://example.com")
    result = service.scrape!

    assert_not_nil result
    assert_equal "<html><body>Test</body></html>", service.html_content
    assert_nil service.error
  end

  test "scrape! handles API errors" do
    stub_request(:post, "http://playwright:3000/render")
      .to_return(status: 500, body: "Internal Error")

    service = HtmlScraperService.new("https://example.com")
    result = service.scrape!

    assert_nil result
    assert_not_nil service.error
    assert_includes service.error, "Erreur API Playwright"
  end

  test "scrape! validates URL format" do
    service = HtmlScraperService.new("not-a-url")

    assert_raises(ArgumentError) do
      service.scrape!
    end
  end
end
