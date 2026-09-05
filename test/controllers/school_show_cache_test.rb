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
    sign_out
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
      wrestler.update!(name: "#{wrestler.name} Updated")
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

    spectator_warm_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(spectator_warm_events), :>, 0, "Expected spectator-safe wrestler rows to use a separate cache entry"

    spectator_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_hits(spectator_events), :>, 0, "Expected repeat spectator request to hit the spectator-safe wrestler row cache"
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
    sign_out
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

  test "assigning a mat expires school show wrestler cell caches" do
    sign_out
    warm_events = cache_events_for_school_show do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(warm_events), :>, 0, "Expected initial school show render to warm wrestler cell cache"

    wrestler = @school.wrestlers.first
    match = wrestler.unfinished_matches.first
    mat = @tournament.mats.create!(name: "Cache Test Mat")

    post_action_events = cache_events_for_school_show do
      mat.assign_match_to_queue!(match, 1)
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(post_action_events), :>, 0, "Expected mat assignment to expire school show wrestler cell cache"
  end

  test "match stat update reuses school stats cache" do
    warm_events = cache_events_for_school_stats do
      get :stats, params: { id: @school.id }
      assert_response :success
    end
    assert_operator cache_writes(warm_events), :>, 0, "Expected initial school stats render to warm cache"

    wrestler = @school.wrestlers.first
    match = wrestler.all_matches.first

    post_action_events = cache_events_for_school_stats do
      match.update!(w1_stat: "T2")
      get :stats, params: { id: @school.id }
      assert_response :success
    end
    assert_equal 0, cache_writes(post_action_events), "Expected live stats not to invalidate the school stats cache"
    assert_operator cache_hits(post_action_events), :>, 0, "Expected live stats to reuse the school stats cache"
  end

  test "finished match stat correction expires both schools stats caches" do
    wrestler = @school.wrestlers.first
    match = wrestler.all_matches.first
    match.update_columns(finished: 1, winner_id: match.w1 || match.w2, win_type: "Decision", score: "1-0")

    cache_events_for_school_stats { get :stats, params: { id: @school.id } }
    events = cache_events_for_school_stats do
      match.update!(w1_stat: "T2")
      get :stats, params: { id: @school.id }
      assert_response :success
    end

    assert_operator cache_writes(events), :>, 0
  end

  test "warm spectator roster does not instantiate wrestlers or matches" do
    sign_out
    get :show, params: { id: @school.id }
    assert_response :success
    loaded = []
    subscriber = ->(_name, _start, _finish, _id, payload) { loaded << payload[:class_name] }
    ActiveSupport::Notifications.subscribed(subscriber, "instantiation.active_record") do
      get :show, params: { id: @school.id }
      assert_response :success
    end
    assert_empty loaded & %w[Match Wrestler]
  end

  test "pool school roster and stats render with batched associations" do
    create_pool_tournament
    GenerateTournamentMatches.new(@tournament).generate
    sign_out
    @tournament.schools.each do |school|
      get :show, params: { id: school.id }
      assert_response :success
      school.wrestlers.each { |wrestler| assert_includes response.body, wrestler.name }
      get :stats, params: { id: school.id }
      assert_response :success
    end
  end

  private

  def sign_out
    @request.session[:user_id] = nil
    @controller.instance_variable_set(:@current_user, nil)
    @controller.instance_variable_set(:@current_ability, nil)
  end

  def cache_events_for_school_show(&block)
    cache_events_for("school_roster", &block)
  end

  def cache_events_for_school_stats(&block)
    cache_events_for("school_stats", &block)
  end

  def cache_events_for(key_marker)
    events = []
    subscriber = lambda do |name, _start, _finish, _id, payload|
      key = payload[:key].to_s
      next unless key.include?(key_marker)

      events << { name: name, hit: payload[:hit] || payload[:hits].present? }
    end

    ActiveSupport::Notifications.subscribed(
      subscriber,
      /cache_(read|write|fetch_hit|generate)(?:_multi)?\.active_support/
    ) do
      yield
    end

    events
  end

  def cache_writes(events)
    events.count { |event| event[:name].start_with?("cache_write") }
  end

  def cache_hits(events)
    events.count do |event|
      event[:name] == "cache_fetch_hit.active_support" ||
        (event[:name].start_with?("cache_read") && event[:hit])
    end
  end
end
