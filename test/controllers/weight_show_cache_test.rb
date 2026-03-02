require "test_helper"

class WeightShowCacheTest < ActionController::TestCase
  tests WeightsController

  setup do
    create_a_tournament_with_single_weight("Regular Double Elimination 1-6", 8)
    @tournament.update!(user_id: users(:one).id)
    @weight = @tournament.weights.first

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "weight show readonly row fragments hit cache and invalidate after wrestler update" do
    first_events = cache_events_for_weight_show do
      get :show, params: { id: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial weight show render to write readonly row fragments"

    second_events = cache_events_for_weight_show do
      get :show, params: { id: @weight.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat weight show render to reuse readonly row fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat weight show render to hit readonly row cache"

    wrestler = @weight.wrestlers.first
    third_events = cache_events_for_weight_show do
      wrestler.touch
      get :show, params: { id: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected wrestler update to invalidate weight show readonly row cache"
  end

  test "weight show does not leak manage-only controls from cache across users" do
    sign_in users(:one)
    get :show, params: { id: @weight.id }
    assert_response :success
    assert_includes response.body, "Save Seeds"
    assert_match(/fa-trash-alt/, response.body)
    assert_match(/name="wrestler\[\d+\]\[original_seed\]"/, response.body)

    sign_out

    get :show, params: { id: @weight.id }
    assert_response :success
    assert_not_includes response.body, "Save Seeds"
    assert_no_match(/fa-trash-alt/, response.body)
    assert_no_match(/name="wrestler\[\d+\]\[original_seed\]"/, response.body)

    spectator_cache_events = cache_events_for_weight_show do
      get :show, params: { id: @weight.id }
      assert_response :success
    end
    assert_operator cache_hits(spectator_cache_events), :>, 0, "Expected repeat spectator request to hit readonly wrestler row cache"
    assert_not_includes response.body, "Save Seeds"
    assert_no_match(/fa-trash-alt/, response.body)
    assert_no_match(/name="wrestler\[\d+\]\[original_seed\]"/, response.body)
  end

  private

  def sign_out
    @request.session[:user_id] = nil
    @controller.instance_variable_set(:@current_user, nil)
    @controller.instance_variable_set(:@current_ability, nil)
  end

  def cache_events_for_weight_show
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?("weight_show_wrestler_row")

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
