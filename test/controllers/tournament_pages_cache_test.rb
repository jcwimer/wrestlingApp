require "test_helper"

class TournamentPagesCacheTest < ActionController::TestCase
  tests TournamentsController

  setup do
    create_double_elim_tournament_single_weight_1_6(8)
    @tournament.update!(user_id: users(:one).id)
    @weight = @tournament.weights.first

    sign_in users(:one)

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "team_scores cache hits on repeat render and rewrites after school update" do
    first_events = cache_events_for(%w[team_scores team_score_row]) do
      get :team_scores, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial team_scores render to write fragments"

    second_events = cache_events_for(%w[team_scores team_score_row]) do
      get :team_scores, params: { id: @tournament.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat team_scores render to reuse fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat team_scores render to hit cache"

    school = @tournament.schools.first
    third_events = cache_events_for(%w[team_scores team_score_row]) do
      school.update!(score: (school.score || 0) + 1)
      get :team_scores, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected school score update to invalidate team_scores cache"
  end

  test "bracket cache hits on repeat render and rewrites after match update" do
    key_markers = [@weight.id.to_s + "_bracket", "bracket_round_match", "bracket_final_match"]

    first_events = cache_events_for(key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial bracket render to write fragments"

    second_events = cache_events_for(key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat bracket render to reuse fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat bracket render to hit cache"

    match = @weight.matches.first
    third_events = cache_events_for(key_markers) do
      match.touch
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected match update to invalidate bracket cache"
  end

  test "bracket cache separates print and non-print variants" do
    key_markers = [@weight.id.to_s + "_bracket"]

    non_print_events = cache_events_for(key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(non_print_events), :>, 0, "Expected non-print bracket render to write a page fragment"
    assert_match(%r{\/matches\/\d+\/spectate}, response.body, "Expected non-print bracket view to include spectate links")

    first_print_events = cache_events_for(key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id, print: true }
      assert_response :success
    end
    assert_operator cache_writes(first_print_events), :>, 0, "Expected first print bracket render to write a separate page fragment"
    assert_no_match(%r{\/matches\/\d+\/spectate}, response.body, "Expected print bracket view to omit spectate links")

    second_print_events = cache_events_for(key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id, print: true }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_print_events), "Expected repeat print bracket render to reuse print cache fragment"
    assert_operator cache_hits(second_print_events), :>, 0, "Expected repeat print bracket render to hit cache"
  end

  test "completing a match expires team_scores and bracket caches" do
    team_warm_events = cache_events_for(%w[team_scores team_score_row]) do
      get :team_scores, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(team_warm_events), :>, 0, "Expected initial team_scores render to warm cache"

    bracket_key_markers = [@weight.id.to_s + "_bracket", "bracket_round_match", "bracket_final_match"]
    bracket_warm_events = cache_events_for(bracket_key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(bracket_warm_events), :>, 0, "Expected initial bracket render to warm cache"

    match = @weight.matches.where(finished: [nil, 0]).first || @weight.matches.first
    assert match, "Expected a match to complete for expiration test"

    match.update!(
      finished: 1,
      winner_id: match.w1 || match.w2,
      win_type: "Decision",
      score: "1-0"
    )

    team_post_events = cache_events_for(%w[team_scores team_score_row]) do
      get :team_scores, params: { id: @tournament.id }
      assert_response :success
    end
    assert_operator cache_writes(team_post_events), :>, 0, "Expected completed match to expire team_scores cache"

    bracket_post_events = cache_events_for(bracket_key_markers) do
      get :bracket, params: { id: @tournament.id, weight: @weight.id }
      assert_response :success
    end
    assert_operator cache_writes(bracket_post_events), :>, 0, "Expected completed match to expire bracket cache"
  end

  private

  def cache_events_for(key_markers)
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
