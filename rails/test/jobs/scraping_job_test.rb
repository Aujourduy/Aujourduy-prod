require "test_helper"

class ScrapingJobTest < ActiveJob::TestCase
  setup do
    @teacher_url = teacher_urls(:one) if defined?(teacher_urls)
  end

  test "job is enqueued" do
    skip "Requires teacher_url fixture" unless @teacher_url

    assert_enqueued_with(job: ScrapingJob) do
      ScrapingJob.perform_later(@teacher_url.id)
    end
  end

  test "job processes scraping" do
    skip "Integration test - requires external services"
  end
end
