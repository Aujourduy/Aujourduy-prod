ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Disable parallel tests due to PgBouncer configuration
    # (parallel tests create multiple test databases which need PgBouncer setup)
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Use English locale for tests to avoid translation issues
    setup do
      I18n.locale = :en
    end

    teardown do
      I18n.locale = I18n.default_locale
    end

    # Add more helper methods to be used by all tests here...

    # Custom assertion for query count with range support
    def assert_queries_count(expected_range, &block)
      queries = []
      counter = ->(*, payload) do
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)

      query_count = queries.size
      assert expected_range.include?(query_count),
             "#{query_count} instead of #{expected_range} queries were executed. Queries: #{queries.join("\n\n")}"
    end
  end
end

# Add Devise test helpers for controller tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
