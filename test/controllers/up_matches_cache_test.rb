require "test_helper"

class UpMatchesCacheTest < ActionController::TestCase
  tests TournamentsController

  setup do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 4, 2)
    @tournament.update!(user_id: users(:one).id)
    @tournament.reset_and_fill_bout_board

    sign_in users(:one)

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "up_matches row fragments hit cache and invalidate when a mat queue changes" do
    first_events = cache_events_for_up_matches do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_operator cache_writes(first_events), :>, 0, "Expected initial render to write row fragments"

    second_events = cache_events_for_up_matches do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_equal 0, cache_writes(second_events), "Expected second render to reuse cached row fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected second render to have cache hits"

    mat = @tournament.mats.first
    mat.reload
    movable_match = mat.queue2_match || mat.queue1_match
    assert movable_match, "Expected at least one queued match to move"
    mat.assign_match_to_queue!(movable_match, 4)

    third_events = cache_events_for_up_matches do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_operator cache_writes(third_events), :>, 0, "Expected queue change to invalidate and rewrite at least one row fragment"
  end

  private

  def cache_events_for_up_matches
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?("up_matches_mat_row")

      events << { name: name, hit: payload[:hit] }
    end

    ActiveSupport::Notifications.subscribed(
      subscriber,
      /cache_(read|write|fetch_hit|generate)\.active_support/
    ) do
      yield
    end

    events
  end

  def cache_writes(events)
    events.count { |event| event[:name] == "cache_write.active_support" }
  end

  def cache_hits(events)
    events.count do |event|
      event[:name] == "cache_fetch_hit.active_support" ||
        (event[:name] == "cache_read.active_support" && event[:hit])
    end
  end
end
