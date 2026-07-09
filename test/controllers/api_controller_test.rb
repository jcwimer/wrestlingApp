require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  setup do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(8, 1, 1)

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "tournament api cache expires after mat update" do
    first_events = cache_events_for_api_tournament do
      get :tournament, params: { tournament: @tournament.id }, format: :json
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial API render to write cache"

    second_events = cache_events_for_api_tournament do
      get :tournament, params: { tournament: @tournament.id }, format: :json
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat API render to reuse cache"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat API render to hit cache"

    mat = @tournament.mats.first
    third_events = cache_events_for_api_tournament do
      mat.update!(name: "Updated Mat")
      get :tournament, params: { tournament: @tournament.id }, format: :json
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected mat update to invalidate API cache"
  end

  private

  def cache_events_for_api_tournament
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?("api_tournament")

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
