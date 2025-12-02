require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
    @user = users(:one)
    @teacher = teachers(:one)
    @practice = practices(:one)
    @teacher.practices << @practice unless @teacher.practices.include?(@practice)
    sign_in @user
  end

  test "should get index" do
    get events_path
    assert_response :success
  end

  test "should get show" do
    get event_path(@event)
    assert_response :success
  end

  test "should get new" do
    get new_event_path
    assert_response :success
  end

  test "should get edit" do
    get edit_event_path(@event)
    assert_response :success
  end

  test "should create event" do
    assert_difference('Event.count', 1) do
      post events_path, params: {
        event: {
          title: "New Event",
          description: "Test description",
          practice_id: @practice.id,
          source_url: "https://example.com/new-event",
          principal_teacher_id: @teacher.id,
          is_recurring: '0'  # single event
        },
        occurrence: {
          start_date: 1.week.from_now.to_date,
          end_date: 1.week.from_now.to_date,
          venue_id: venues(:one).id
        }
      }
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "should update event" do
    patch event_path(@event), params: {
      event: { title: "Updated Title" }
    }
    assert_redirected_to event_path(@event)
    @event.reload
    assert_equal "Updated Title", @event.title
  end

  test "should destroy event" do
    deletable_event = @user.events.create!(
      title: "Deletable Event",
      description: "Test",
      practice: @practice,
      source_url: "https://example.com/deletable",
      principal_teacher: @teacher
    )

    # Create an occurrence too
    deletable_event.event_occurrences.create!(
      start_date: 1.week.from_now.to_date,
      end_date: 1.week.from_now.to_date,
      venue: venues(:one)
    )

    # Destroy actually cancels the event, doesn't delete it
    delete event_path(deletable_event)

    assert_redirected_to events_path
    deletable_event.reload
    assert_equal 'cancelled', deletable_event.status
  end
end
