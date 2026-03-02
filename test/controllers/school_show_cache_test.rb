require "test_helper"

class SchoolShowCacheTest < ActionController::TestCase
  tests SchoolsController

  setup do
    create_double_elim_tournament_single_weight_1_6(8)
    @tournament.update!(user_id: users(:one).id)
    @school = @tournament.schools.first

    sign_in users(:one)

    @original_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ActionController::Base.perform_caching = @original_perform_caching
  end

  test "school show wrestler cell fragments hit cache and invalidate after wrestler update" do
    first_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(first_events), :>, 0, "Expected initial school show render to write wrestler cell fragments"

    second_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(second_events), "Expected repeat school show render to reuse wrestler cell fragments"
    assert_operator cache_hits(second_events), :>, 0, "Expected repeat school show render to hit wrestler cell cache"

    wrestler = @school.wrestlers.first
    third_events = cache_events_for_school_show do
      wrestler.touch
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(third_events), :>, 0, "Expected wrestler update to invalidate school show wrestler cell cache"
  end

  test "school show does not leak manage-only controls from cache across users" do
    get :show, params: { id: @school.id }
    assert_response :success
    assert_includes response.body, "New Wrestler"
    assert_match(/fa-trash-alt/, response.body)
    assert_match(/fa-edit/, response.body)

    sign_out

    spectator_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_hits(spectator_events), :>, 0, "Expected spectator request to hit wrestler cell cache warmed by owner"
    assert_not_includes response.body, "New Wrestler"
    assert_no_match(/fa-trash-alt/, response.body)
    assert_no_match(/fa-edit/, response.body)
  end

  test "school show with school_permission_key bypasses cached wrestler cell fragments" do
    @school.update!(permission_key: SecureRandom.uuid)
    sign_out

    key_request_events = cache_events_for_school_show do
      get :show, params: { id: @school.id, school_permission_key: @school.permission_key }
      assert_response :success
    end

    assert_equal 0, cache_writes(key_request_events), "Expected school_permission_key request to bypass cached wrestler cells"
    assert_equal 0, cache_hits(key_request_events), "Expected school_permission_key request to avoid reading cached wrestler cells"
  end

  test "completing a match expires school show wrestler cell caches" do
    warm_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(warm_events), :>, 0, "Expected initial school show render to warm wrestler cell cache"

    wrestler = @school.wrestlers.first
    assert wrestler, "Expected a wrestler for match-completion cache test"
    match = wrestler.unfinished_matches.first || wrestler.all_matches.first
    assert match, "Expected a match involving school wrestler"

    winner_id = match.w1 || match.w2
    assert winner_id, "Expected match to have at least one wrestler slot"
    match.update!(
      finished: 1,
      winner_id: winner_id,
      win_type: "Decision",
      score: "1-0"
    )

    post_action_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(post_action_events), :>, 0, "Expected completed match to expire school show wrestler cell cache"
  end

  private

  def sign_out
    @request.session[:user_id] = nil
    @controller.instance_variable_set(:@current_user, nil)
    @controller.instance_variable_set(:@current_ability, nil)
  end

  def cache_events_for_school_show
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?("school_show_wrestler_cells")

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
