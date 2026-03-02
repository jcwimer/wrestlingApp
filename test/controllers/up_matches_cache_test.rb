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

    third_events = cache_events_for_up_matches do
      mat.assign_match_to_queue!(movable_match, 4)
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_operator cache_writes(third_events), :>, 0, "Expected queue change to invalidate and rewrite at least one row fragment"
  end

  test "up_matches row fragments hit cache after queue clear rewrite" do
    first_events = cache_events_for_up_matches do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial render to write row fragments"

    mat = @tournament.mats.first
    clear_events = cache_events_for_up_matches do
      mat.clear_queue!
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(clear_events), :>, 0, "Expected queue clear to invalidate and rewrite at least one row fragment"

    repeat_events = cache_events_for_up_matches do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(repeat_events), "Expected subsequent render after queue clear rewrite to reuse cached row fragments"
    assert_operator cache_hits(repeat_events), :>, 0, "Expected cache hits after queue clear rewrite"
  end

  test "up_matches unassigned row fragments hit cache and invalidate after unassigned match update" do
    key_markers = %w[up_matches_unassigned_row]

    first_events = cache_events_for_up_matches(key_markers) do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial unassigned row render to write fragments"

    second_events = cache_events_for_up_matches(key_markers) do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat unassigned row render to reuse cached fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat unassigned row render to hit cache"

    unassigned_match = @tournament.up_matches_unassigned_matches.first
    assert unassigned_match, "Expected at least one unassigned match for cache invalidation test"

    third_events = cache_events_for_up_matches(key_markers) do
      unassigned_match.touch
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected unassigned match update to invalidate unassigned row fragment"
  end

  test "completing an on-mat match expires up_matches cached fragments" do
    warm_events = cache_events_for_up_matches(%w[up_matches_mat_row up_matches_unassigned_row]) do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(warm_events), :>, 0, "Expected initial up_matches render to warm caches"

    mat = @tournament.mats.detect { |m| m.queue1_match.present? }
    assert mat, "Expected a mat with a queued match"
    match = mat.queue1_match
    assert match, "Expected queue1 match to complete"

    post_action_events = cache_events_for_up_matches(%w[up_matches_mat_row up_matches_unassigned_row]) do
      match.update!(
        finished: 1,
        winner_id: match.w1 || match.w2,
        win_type: "Decision",
        score: "1-0"
      )
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_operator cache_writes(post_action_events), :>, 0, "Expected completed match to expire and rewrite up_matches caches"
  end

  test "manually assigning an unassigned match to a mat queue expires up_matches caches" do
    warm_events = cache_events_for_up_matches(%w[up_matches_mat_row up_matches_unassigned_row]) do
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(warm_events), :>, 0, "Expected initial up_matches render to warm caches"

    unassigned_match = @tournament.up_matches_unassigned_matches.first
    assert unassigned_match, "Expected at least one unassigned match to manually place on a mat"
    target_mat = @tournament.mats.first

    post_action_events = cache_events_for_up_matches(%w[up_matches_mat_row up_matches_unassigned_row]) do
      target_mat.assign_match_to_queue!(unassigned_match, 4)
      get :up_matches, params: { id: @tournament.id }
      assert_response :success
    end

    assert_operator cache_writes(post_action_events), :>, 0, "Expected manual mat assignment to expire and rewrite up_matches caches"
  end

  private

  def cache_events_for_up_matches(key_markers = %w[up_matches_mat_row up_matches_unassigned_row])
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key_markers.any? { |marker| key.include?(marker) }

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
