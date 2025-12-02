require "test_helper"

class YearlyScrapingJobTest < ActiveJob::TestCase
  test "job is enqueued" do
    assert_enqueued_with(job: YearlyScrapingJob) do
      YearlyScrapingJob.perform_later
    end
  end
end
