require "test_helper"

class WrestlerShowCacheTest < ActionController::TestCase
  tests WrestlersController

  setup do
    create_double_elim_tournament_single_weight_1_6(8)
    @tournament.update!(user_id: users(:one).id)
    @wrestler = @tournament.wrestlers.first

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "wrestler show cache hits and remains valid after match stat update" do
    first_events = cache_events_for_wrestler_show do
      get :show, params: { id: @wrestler.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial wrestler show render to write cache"

    second_events = cache_events_for_wrestler_show do
      get :show, params: { id: @wrestler.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat wrestler show render to reuse cache"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat wrestler show render to hit cache"

    match = @wrestler.all_matches.first
    third_events = cache_events_for_wrestler_show do
      match.update!(w1_stat: "T2")
      get :show, params: { id: @wrestler.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(third_events), "Expected live stats not to invalidate the wrestler show cache"
    assert_operator cache_hits(third_events), :>, 0, "Expected live stats to reuse the wrestler show cache"
  end

  private

  def cache_events_for_wrestler_show
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?("wrestler_profile")

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
