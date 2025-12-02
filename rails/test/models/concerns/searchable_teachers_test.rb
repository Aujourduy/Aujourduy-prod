require "test_helper"

class SearchableTeachersTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)

    @practice_yoga = practices(:one)
    @practice_yoga.update!(name: "Yoga")

    @practice_dance = Practice.create!(name: "Contemporary Dance", user: @user)
    @practice_meditation = Practice.create!(name: "Meditation", user: @user)

    @teacher_john = teachers(:one)
    @teacher_john.assign_attributes(
      first_name: "John",
      last_name: "Smith",
      bio: "Certified yoga instructor with 10 years of experience",
      practice_ids: [@practice_yoga.id]
    )
    @teacher_john.save!

    @teacher_jane = Teacher.create!(
      first_name: "Jane",
      last_name: "Doe",
      bio: "Professional contemporary dancer and choreographer",
      user: @user,
      practice_ids: [@practice_dance.id]
    )

    @teacher_alice = Teacher.create!(
      first_name: "Alice",
      last_name: "Johnson",
      bio: "Meditation teacher specializing in mindfulness",
      user: @user,
      practice_ids: [@practice_meditation.id, @practice_yoga.id]
    )

    @teacher_bob = Teacher.create!(
      first_name: "Bob",
      last_name: "Williams",
      bio: "Multi-disciplinary movement artist",
      user: @user
    )
    # Bob has no practices assigned initially
  end

  # ========== Basic Search Tests ==========

  test "search_by_keywords returns all when query is blank" do
    results = Teacher.search_by_keywords("")
    assert_equal Teacher.count, results.count
  end

  test "search_by_keywords returns all when query is nil" do
    results = Teacher.search_by_keywords(nil)
    assert_equal Teacher.count, results.count
  end

  test "search_by_keywords returns all when query is only whitespace" do
    results = Teacher.search_by_keywords("   ")
    assert_equal Teacher.count, results.count
  end

  # ========== First Name Search ==========

  test "search_by_keywords finds teacher by first name" do
    results = Teacher.search_by_keywords("John")
    assert_includes results, @teacher_john
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by first name case insensitive" do
    results = Teacher.search_by_keywords("JOHN")
    assert_includes results, @teacher_john
  end

  test "search_by_keywords finds teacher by partial first name" do
    results = Teacher.search_by_keywords("Joh")
    assert_includes results, @teacher_john
  end

  # ========== Last Name Search ==========

  test "search_by_keywords finds teacher by last name" do
    results = Teacher.search_by_keywords("Smith")
    assert_includes results, @teacher_john
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by last name case insensitive" do
    results = Teacher.search_by_keywords("SMITH")
    assert_includes results, @teacher_john
  end

  test "search_by_keywords finds teacher by partial last name" do
    results = Teacher.search_by_keywords("Smi")
    assert_includes results, @teacher_john
  end

  # ========== Full Name Search ==========

  test "search_by_keywords finds teacher by full name" do
    results = Teacher.search_by_keywords("Jane Doe")
    assert_includes results, @teacher_jane
    assert_not_includes results, @teacher_john
  end

  test "search_by_keywords finds teacher by full name with different order" do
    # "Doe Jane" should still match because each word is checked separately
    results = Teacher.search_by_keywords("Doe Jane")
    assert_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by full name case insensitive" do
    results = Teacher.search_by_keywords("john smith")
    assert_includes results, @teacher_john
  end

  # ========== Bio Search ==========

  test "search_by_keywords finds teacher by bio content" do
    results = Teacher.search_by_keywords("yoga instructor")
    assert_includes results, @teacher_john
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by single bio keyword" do
    results = Teacher.search_by_keywords("choreographer")
    assert_includes results, @teacher_jane
    assert_not_includes results, @teacher_john
  end

  test "search_by_keywords finds teacher by bio keyword case insensitive" do
    results = Teacher.search_by_keywords("CHOREOGRAPHER")
    assert_includes results, @teacher_jane
  end

  # ========== Practice Search ==========

  test "search_by_keywords finds teacher by practice name" do
    results = Teacher.search_by_keywords("Yoga")
    assert_includes results, @teacher_john
    assert_includes results, @teacher_alice # also teaches yoga
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by practice name case insensitive" do
    results = Teacher.search_by_keywords("YOGA")
    assert_includes results, @teacher_john
  end

  test "search_by_keywords finds teacher by partial practice name" do
    results = Teacher.search_by_keywords("Contemporary")
    assert_includes results, @teacher_jane
  end

  test "search_by_keywords finds teacher by practice with multiple practices" do
    results = Teacher.search_by_keywords("Meditation")
    assert_includes results, @teacher_alice
    assert_not_includes results, @teacher_john
  end

  # ========== Multi-keyword Search (AND logic) ==========

  test "search_by_keywords uses AND logic for multiple keywords" do
    # "John yoga" - both should be present
    results = Teacher.search_by_keywords("John yoga")
    assert_includes results, @teacher_john
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords with multiple keywords all must match" do
    # "John dance" - John exists but not teaching dance
    results = Teacher.search_by_keywords("John dance")
    assert_not_includes results, @teacher_john
    assert_not_includes results, @teacher_jane
  end

  test "search_by_keywords with multiple keywords can match different fields" do
    # "Jane choreographer" - Jane in name, choreographer in bio
    results = Teacher.search_by_keywords("Jane choreographer")
    assert_includes results, @teacher_jane
  end

  test "search_by_keywords with three keywords" do
    # "Alice Meditation mindfulness" - all three present
    results = Teacher.search_by_keywords("Alice Meditation mindfulness")
    assert_includes results, @teacher_alice
  end

  test "search_by_keywords with three keywords fails if one is missing" do
    # "Alice Meditation dancing" - Alice teaches meditation but not dancing
    results = Teacher.search_by_keywords("Alice Meditation dancing")
    assert_not_includes results, @teacher_alice
  end

  # ========== Multiple Matches ==========

  test "search_by_keywords finds multiple teachers when query matches multiple" do
    # Both John and Alice teach yoga
    results = Teacher.search_by_keywords("yoga")
    assert_includes results, @teacher_john
    assert_includes results, @teacher_alice
    assert_equal 2, results.count
  end

  test "search_by_keywords finds all teachers with common keyword in bio" do
    # Update bios to have common keyword
    @teacher_john.update!(bio: "Experienced teacher with international certification")
    @teacher_jane.update!(bio: "Professional teacher and performer")

    results = Teacher.search_by_keywords("teacher")
    assert_includes results, @teacher_john
    assert_includes results, @teacher_jane
  end

  # ========== Case Insensitivity ==========

  test "search_by_keywords is case insensitive for all fields" do
    results_lower = Teacher.search_by_keywords("john smith")
    results_upper = Teacher.search_by_keywords("JOHN SMITH")
    results_mixed = Teacher.search_by_keywords("JoHn SmItH")

    assert_equal results_lower.to_a, results_upper.to_a
    assert_equal results_lower.to_a, results_mixed.to_a
  end

  # ========== Special Characters & SQL Injection ==========

  test "search_by_keywords handles special SQL characters safely" do
    # Should not break or cause SQL injection
    assert_nothing_raised do
      Teacher.search_by_keywords("100% certified")
      Teacher.search_by_keywords("teacher_name")
      Teacher.search_by_keywords("'; DROP TABLE teachers;--")
    end
  end

  test "search_by_keywords sanitizes LIKE wildcards" do
    # Create teacher with literal underscore in name
    teacher = Teacher.create!(
      first_name: "Jean_Pierre",
      last_name: "Dubois",
      user: @user
    )

    # Should find literal underscore, not use it as wildcard
    results = Teacher.search_by_keywords("Jean_Pierre")
    assert_includes results, teacher
  end

  test "search_by_keywords handles percent sign in search" do
    teacher = Teacher.create!(
      first_name: "Marie",
      last_name: "Martin",
      bio: "Offers 20% discount for groups",
      user: @user
    )

    results = Teacher.search_by_keywords("20%")
    assert_includes results, teacher
  end

  # ========== Distinct Results ==========

  test "search_by_keywords returns distinct results without duplicates" do
    # Alice has multiple practices (creates multiple join paths)
    results = Teacher.search_by_keywords("Alice")

    # Should appear only once despite multiple practices
    assert_equal 1, results.where(id: @teacher_alice.id).count
  end

  test "search_by_keywords with practice returns distinct when teacher has multiple practices" do
    # Search for yoga - Alice teaches both yoga and meditation
    results = Teacher.search_by_keywords("yoga")

    # Alice should appear only once
    alice_count = results.where(id: @teacher_alice.id).count
    assert_equal 1, alice_count
  end

  # ========== Empty Results ==========

  test "search_by_keywords returns empty when no match" do
    results = Teacher.search_by_keywords("NonExistentKeyword12345")
    assert_empty results
  end

  test "search_by_keywords returns empty when all keywords must match but dont" do
    results = Teacher.search_by_keywords("John ballet")
    assert_empty results # John exists but doesn't teach ballet
  end

  # ========== Whitespace Handling ==========

  test "search_by_keywords handles extra whitespace" do
    results = Teacher.search_by_keywords("  John   Smith  ")
    assert_includes results, @teacher_john
  end

  test "search_by_keywords handles tabs and newlines" do
    results = Teacher.search_by_keywords("John\t\nSmith")
    assert_includes results, @teacher_john
  end

  test "search_by_keywords handles multiple consecutive spaces" do
    results = Teacher.search_by_keywords("John    Smith")
    assert_includes results, @teacher_john
  end

  # ========== Edge Cases ==========

  test "search_by_keywords works with teacher without practices" do
    results = Teacher.search_by_keywords("Bob Williams")
    assert_includes results, @teacher_bob
  end

  test "search_by_keywords works with teacher without bio" do
    teacher = Teacher.create!(
      first_name: "Charlie",
      last_name: "Brown",
      bio: nil,
      user: @user
    )

    results = Teacher.search_by_keywords("Charlie")
    assert_includes results, teacher
  end

  test "search_by_keywords matches practice even if teacher has no bio" do
    @teacher_bob.practices << @practice_yoga
    @teacher_bob.update!(bio: nil)

    results = Teacher.search_by_keywords("yoga")
    assert_includes results, @teacher_bob
  end

  # ========== Complex Scenarios ==========

  test "search_by_keywords with overlapping matches" do
    # "Smith yoga" matches John Smith who teaches yoga
    results = Teacher.search_by_keywords("Smith yoga")
    assert_includes results, @teacher_john
    assert_equal 1, results.count
  end

  test "search_by_keywords distinguishes between similar names" do
    # "Johnson" should only match Alice Johnson, not John Smith
    results = Teacher.search_by_keywords("Johnson")
    assert_includes results, @teacher_alice
    assert_not_includes results, @teacher_john
  end

  # ========== Performance & Chaining ==========

  test "search_by_keywords can be chained with other scopes" do
    # Assuming Teacher has a created_at timestamp
    results = Teacher.search_by_keywords("yoga")
                     .where("created_at > ?", 1.week.ago)

    # Should work without errors
    assert results.is_a?(ActiveRecord::Relation)
  end

  test "search_by_keywords includes necessary associations" do
    results = Teacher.search_by_keywords("yoga")

    # Should not trigger N+1 queries (allow a few queries for associations)
    assert_queries_count(0..5) do
      results.each do |teacher|
        teacher.practices.map(&:name)
      end
    end
  end

  test "search_by_keywords with order clause" do
    results = Teacher.search_by_keywords("yoga").order(:last_name)

    assert_equal 2, results.count
    # Alice Johnson comes before John Smith
    assert_equal @teacher_alice, results.first
    assert_equal @teacher_john, results.last
  end
end
