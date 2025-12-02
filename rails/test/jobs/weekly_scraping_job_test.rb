require "test_helper"

class WeeklyScrapingJobTest < ActiveJob::TestCase
  test "job is enqueued" do
    assert_enqueued_with(job: WeeklyScrapingJob) do
      WeeklyScrapingJob.perform_later
    end
  end

  test "job processes all teacher URLs" do
    skip "Integration test"
  end
end
