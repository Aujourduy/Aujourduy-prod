require "test_helper"

class SearchableEventOccurrencesTest < ActiveSupport::TestCase
  setup do
    # Create test data with proper associations
    @user = users(:one)

    @practice_yoga = practices(:one)
    @practice_yoga.update!(name: "Yoga")

    @practice_dance = practices(:two)
    @practice_dance.update!(name: "Contemporary Dance")

    @venue_paris = venues(:one)
    @venue_paris.update!(
      name: "Studio Harmony",
      city: "Paris",
      country: "France",
      address_line1: "123 Rue de la Paix"
    )

    @venue_lyon = Venue.create!(
      name: "Space Dance",
      city: "Lyon",
      country: "France",
      address_line1: "456 Avenue des Arts",
      user: @user
    )

    @teacher_john = teachers(:one)
    @teacher_john.assign_attributes(
      first_name: "John",
      last_name: "Smith",
      practice_ids: [@practice_yoga.id]
    )
    @teacher_john.save!

    @teacher_jane = Teacher.create!(
      first_name: "Jane",
      last_name: "Doe",
      bio: "Experienced yoga instructor",
      user: @user,
      practice_ids: [@practice_dance.id]
    )

    # Create events with different characteristics
    @event_yoga = events(:one)
    @event_yoga.update!(
      title: "Morning Yoga Session",
      description: "Start your day with mindful movement",
      principal_teacher: @teacher_john,
      practice: @practice_yoga,
      user: @user
    )

    @occurrence_yoga_paris = event_occurrences(:one)
    @occurrence_yoga_paris.update!(
      event: @event_yoga,
      venue: @venue_paris,
      start_date: 1.week.from_now,
      end_date: 1.week.from_now
    )

    @event_dance = Event.create!(
      title: "Contemporary Dance Workshop",
      description: "Explore creative movement techniques",
      principal_teacher: @teacher_jane,
      practice: @practice_dance,
      user: @user,
      source_url: "https://example.com/dance"
    )

    @occurrence_dance_lyon = EventOccurrence.create!(
      event: @event_dance,
      venue: @venue_lyon,
      start_date: 2.weeks.from_now,
      end_date: 2.weeks.from_now
    )

    # Event with override title
    @event_meditation = Event.create!(
      title: "Meditation Class",
      description: "Inner peace session",
      principal_teacher: @teacher_john,
      practice: @practice_yoga,
      user: @user,
      source_url: "https://example.com/meditation"
    )

    @occurrence_meditation = EventOccurrence.create!(
      event: @event_meditation,
      venue: @venue_paris,
      start_date: 3.weeks.from_now,
      override_title: "Advanced Mindfulness Meditation",
      override_description: "Deep meditation practice for experienced practitioners"
    )
  end

  # ========== Basic Search Tests ==========

  test "search_by_keywords returns all when query is blank" do
    results = EventOccurrence.search_by_keywords("")
    assert_equal EventOccurrence.count, results.count
  end

  test "search_by_keywords returns all when query is nil" do
    results = EventOccurrence.search_by_keywords(nil)
    assert_equal EventOccurrence.count, results.count
  end

  test "search_by_keywords returns all when query is only whitespace" do
    results = EventOccurrence.search_by_keywords("   ")
    assert_equal EventOccurrence.count, results.count
  end

  # ========== Event Title Search ==========

  test "search_by_keywords finds event by title" do
    results = EventOccurrence.search_by_keywords("yoga")
    assert_includes results, @occurrence_yoga_paris
    assert_not_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by title case insensitive" do
    results = EventOccurrence.search_by_keywords("YOGA")
    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords finds event by partial title match" do
    results = EventOccurrence.search_by_keywords("Morning")
    assert_includes results, @occurrence_yoga_paris
  end

  # ========== Event Description Search ==========

  test "search_by_keywords finds event by description" do
    results = EventOccurrence.search_by_keywords("mindful")
    assert_includes results, @occurrence_yoga_paris
    assert_not_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by description keyword" do
    results = EventOccurrence.search_by_keywords("movement")
    # Both events have "movement" in description
    assert_includes results, @occurrence_yoga_paris
    assert_includes results, @occurrence_dance_lyon
  end

  # ========== Override Title/Description Search ==========

  test "search_by_keywords finds event by override_title" do
    results = EventOccurrence.search_by_keywords("Mindfulness")
    assert_includes results, @occurrence_meditation
  end

  test "search_by_keywords finds event by override_description" do
    results = EventOccurrence.search_by_keywords("experienced practitioners")
    assert_includes results, @occurrence_meditation
  end

  # ========== Venue Search ==========

  test "search_by_keywords finds event by venue name" do
    results = EventOccurrence.search_by_keywords("Harmony")
    assert_includes results, @occurrence_yoga_paris
    assert_not_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by venue city" do
    results = EventOccurrence.search_by_keywords("Lyon")
    assert_includes results, @occurrence_dance_lyon
    assert_not_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords finds event by venue country" do
    results = EventOccurrence.search_by_keywords("France")
    # Both venues are in France
    assert_includes results, @occurrence_yoga_paris
    assert_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by venue address" do
    results = EventOccurrence.search_by_keywords("Rue de la Paix")
    assert_includes results, @occurrence_yoga_paris
  end

  # ========== Practice Search ==========

  test "search_by_keywords finds event by practice name" do
    results = EventOccurrence.search_by_keywords("Dance")
    assert_includes results, @occurrence_dance_lyon
    assert_not_includes results, @occurrence_yoga_paris
  end

  # ========== Teacher Search ==========

  test "search_by_keywords finds event by principal teacher first name" do
    results = EventOccurrence.search_by_keywords("John")
    assert_includes results, @occurrence_yoga_paris
    assert_not_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by principal teacher last name" do
    results = EventOccurrence.search_by_keywords("Smith")
    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords finds event by principal teacher full name" do
    results = EventOccurrence.search_by_keywords("Jane Doe")
    assert_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords finds event by occurrence teacher" do
    # Add a teacher to occurrence
    @occurrence_yoga_paris.teachers << @teacher_jane

    results = EventOccurrence.search_by_keywords("Jane")
    assert_includes results, @occurrence_yoga_paris
  end

  # ========== Multi-keyword Search (AND logic) ==========

  test "search_by_keywords uses AND logic for multiple keywords" do
    # Should find yoga in Paris (both keywords present)
    results = EventOccurrence.search_by_keywords("yoga Paris")
    assert_includes results, @occurrence_yoga_paris
    assert_not_includes results, @occurrence_dance_lyon
  end

  test "search_by_keywords with multiple keywords all must match" do
    # "yoga Lyon" - yoga exists but not in Lyon
    results = EventOccurrence.search_by_keywords("yoga Lyon")
    assert_not_includes results, @occurrence_yoga_paris # wrong city
    assert_not_includes results, @occurrence_dance_lyon # wrong practice
  end

  test "search_by_keywords with multiple keywords can match different fields" do
    # "Morning Paris" - "Morning" in title, "Paris" in venue city
    results = EventOccurrence.search_by_keywords("Morning Paris")
    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords with three keywords" do
    # "yoga Paris John" - all three should be present
    results = EventOccurrence.search_by_keywords("yoga Paris John")
    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords with three keywords fails if one is missing" do
    results = EventOccurrence.search_by_keywords("yoga Paris Jane")
    # John is the teacher, not Jane
    assert_not_includes results, @occurrence_yoga_paris
  end

  # ========== Case Insensitivity ==========

  test "search_by_keywords is case insensitive for all fields" do
    results_lower = EventOccurrence.search_by_keywords("morning yoga")
    results_upper = EventOccurrence.search_by_keywords("MORNING YOGA")
    results_mixed = EventOccurrence.search_by_keywords("MoRnInG yOgA")

    assert_equal results_lower.to_a, results_upper.to_a
    assert_equal results_lower.to_a, results_mixed.to_a
  end

  # ========== Special Characters & SQL Injection ==========

  test "search_by_keywords handles special SQL characters safely" do
    # Should not break or cause SQL injection
    assert_nothing_raised do
      EventOccurrence.search_by_keywords("100% yoga")
      EventOccurrence.search_by_keywords("yoga_test")
      EventOccurrence.search_by_keywords("yoga'; DROP TABLE events;--")
    end
  end

  test "search_by_keywords sanitizes LIKE wildcards" do
    # Create event with literal underscore in title
    event = Event.create!(
      title: "yoga_class_2025",
      practice: @practice_yoga,
      principal_teacher: @teacher_john,
      user: @user,
      source_url: "https://example.com/yoga-class"
    )
    occurrence = EventOccurrence.create!(
      event: event,
      venue: @venue_paris,
      start_date: 1.week.from_now,
      end_date: 1.week.from_now
    )

    # Should find literal underscore, not use it as wildcard
    results = EventOccurrence.search_by_keywords("yoga_class")
    assert_includes results, occurrence
  end

  # ========== Distinct Results ==========

  test "search_by_keywords returns distinct results without duplicates" do
    # Add occurrence teacher (creates additional join)
    @occurrence_yoga_paris.teachers << @teacher_jane

    # Search that matches through multiple paths
    results = EventOccurrence.search_by_keywords("Paris")

    # Should appear only once despite multiple join paths
    assert_equal 1, results.where(id: @occurrence_yoga_paris.id).count
  end

  # ========== Empty Results ==========

  test "search_by_keywords returns empty when no match" do
    results = EventOccurrence.search_by_keywords("NonExistentKeyword12345")
    assert_empty results
  end

  test "search_by_keywords returns empty when all keywords must match but dont" do
    results = EventOccurrence.search_by_keywords("yoga Tokyo")
    assert_empty results # Yoga exists but not in Tokyo
  end

  # ========== Whitespace Handling ==========

  test "search_by_keywords handles extra whitespace" do
    results = EventOccurrence.search_by_keywords("  yoga   Paris  ")
    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords handles tabs and newlines" do
    results = EventOccurrence.search_by_keywords("yoga\t\nParis")
    assert_includes results, @occurrence_yoga_paris
  end

  # ========== Performance & Chaining ==========

  test "search_by_keywords can be chained with other scopes" do
    results = EventOccurrence.search_by_keywords("yoga")
                             .where("start_date > ?", Time.current)

    assert_includes results, @occurrence_yoga_paris
  end

  test "search_by_keywords includes necessary associations" do
    results = EventOccurrence.search_by_keywords("yoga")

    # Should not trigger N+1 queries (allow a few queries for associations)
    assert_queries_count(0..5) do
      results.each do |occurrence|
        occurrence.event.title
        occurrence.venue.name if occurrence.venue
        occurrence.event.principal_teacher&.first_name
      end
    end
  end
end
