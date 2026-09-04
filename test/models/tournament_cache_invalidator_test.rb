require "test_helper"

class TournamentCacheInvalidatorTest < ActiveSupport::TestCase
  setup do
    create_double_elim_tournament_single_weight_1_6(8)
    @weight = @tournament.weights.first
    @match = @weight.matches.where.not(w1: nil).where.not(w2: nil).first
    @wrestlers = Wrestler.where(id: [@match.w1, @match.w2]).to_a
    @schools = School.where(id: @wrestlers.map(&:school_id).uniq).to_a
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test "finished match explicitly deletes bracket stats and wrestler views and refreshes team scores" do
    seed_cache_entries

    @match.update!(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "1-0")

    assert_brackets_deleted
    assert_school_stats_deleted
    assert_affected_wrestler_views_deleted
    assert_team_scores_deleted
  end

  test "finished match keeps caches until queued advancement completes" do
    ActiveJob::Base.queue_adapter = :test
    seed_cache_entries

    @match.update!(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "1-0")

    assert_brackets_cached
    assert_rosters_cached
    assert_team_scores_cached

    AdvanceWrestlerJob.perform_now([@match.id], @tournament.id)

    assert_brackets_deleted
    assert_team_scores_deleted
  ensure
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
    ActiveJob::Base.queue_adapter = :inline
  end

  test "match invalidation does not evict school summaries" do
    seed_cache_entries

    TournamentCacheInvalidator.match_changed(
      wrestler_ids: @wrestlers.map(&:id),
      weight_ids: [@weight.id],
      tournament_ids: [@tournament.id]
    )

    @schools.each { |school| assert_fragment_cached(TournamentCacheInvalidator.school_summary_key(school.id)) }
    assert_team_scores_cached
  end

  test "unfinished live stats do not delete page caches" do
    keys = seed_cache_entries

    @match.update!(w1_stat: "T2")

    keys.each { |key| assert Rails.cache.exist?(key), "Expected #{key.inspect} to remain cached" }
  end

  test "finished stat correction deletes only school stats and wrestler profiles" do
    @match.update_columns(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "1-0")
    seed_cache_entries

    @match.update!(w1_stat: "T2")

    assert_school_stats_deleted
    @wrestlers.each { |wrestler| assert_fragment_deleted(TournamentCacheInvalidator.wrestler_profile_key(wrestler.id)) }
    assert_brackets_cached
    assert_team_scores_cached
    assert_rosters_cached
  end

  test "wrestler information changes explicitly delete affected caches without deleting team scores" do
    seed_cache_entries

    @wrestlers.first.update!(name: "Updated Wrestler")

    assert_brackets_deleted
    assert_school_stats_deleted([@wrestlers.first.school_id])
    assert_fragment_deleted(TournamentCacheInvalidator.school_roster_key(@wrestlers.first.school_id))
    assert_fragment_deleted(TournamentCacheInvalidator.weight_roster_key(@weight.id))
    assert_fragment_deleted(TournamentCacheInvalidator.wrestler_profile_key(@wrestlers.first.id))
    assert_team_scores_cached
  end

  test "wrestler updates do not fan out timestamps to cache dependents" do
    wrestler = @wrestlers.first
    timestamps = {
      school: wrestler.school.reload.updated_at,
      weight: wrestler.weight.reload.updated_at,
      tournament: @tournament.reload.updated_at
    }

    wrestler.update!(name: "Updated Without Touch Fanout")

    assert_equal timestamps[:school], wrestler.school.reload.updated_at
    assert_equal timestamps[:weight], wrestler.weight.reload.updated_at
    assert_equal timestamps[:tournament], @tournament.reload.updated_at
  end

  test "tournament name changes delete bracket and school summary caches" do
    seed_cache_entries

    @tournament.update!(name: "Updated Tournament")

    assert_brackets_deleted
    @schools.each { |school| assert_fragment_deleted(TournamentCacheInvalidator.school_summary_key(school.id)) }
    assert_rosters_cached
    assert_team_scores_cached
  end

  test "school score changes delete only that school summary and team scores" do
    seed_cache_entries
    changed_school = @schools.first
    unchanged_school = @schools.second

    changed_school.update!(score: changed_school.score.to_f + 1)

    assert_fragment_deleted(TournamentCacheInvalidator.school_summary_key(changed_school.id))
    assert_fragment_cached(TournamentCacheInvalidator.school_summary_key(unchanged_school.id)) if unchanged_school
    @schools.each { |school| assert_fragment_cached(TournamentCacheInvalidator.school_roster_key(school.id)) }
    assert_team_scores_deleted
  end

  test "generation completion explicitly deletes every tournament cache domain" do
    seed_cache_entries

    TournamentCacheInvalidator.generation_completed(@tournament.id)

    assert_brackets_deleted
    assert_school_stats_deleted
    assert_wrestler_views_deleted
    assert_team_scores_deleted
  end

  test "full team score calculation explicitly deletes score caches" do
    seed_cache_entries

    CalculateTournamentTeamScoresJob.perform_now(@tournament.id)

    assert_team_scores_deleted
  end

  test "advancement explicitly deletes the weight bracket after bulk persistence" do
    @match.update_columns(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "1-0")
    seed_cache_entries

    AdvanceWrestler.new(@match.wrestler1, @match).advance_raw

    assert_brackets_deleted
  end

  test "match generation explicitly deletes all page domains after bulk persistence" do
    seed_cache_entries

    GenerateTournamentMatches.new(@tournament).generate_raw

    assert_brackets_deleted
    assert_school_stats_deleted
    assert_team_scores_deleted
  end

  private

  def seed_cache_entries
    keys = cache_entry_keys
    Rails.cache.write_multi(keys.index_with { "cached" })
    keys
  end

  def cache_entry_keys
    keys = [
      TournamentCacheInvalidator.bracket_fragment_key(@weight.id),
      TournamentCacheInvalidator.bracket_fragment_key(@weight.id, print: true),
      fragment_key(TournamentCacheInvalidator.team_scores_key(@tournament.id)),
      TournamentCacheInvalidator.team_scores_data_key(@tournament.id),
      fragment_key(TournamentCacheInvalidator.weight_roster_key(@weight.id))
    ]
    keys.concat(@schools.flat_map do |school|
      [
        fragment_key(TournamentCacheInvalidator.school_stats_key(school.id)),
        TournamentCacheInvalidator.school_stats_data_key(school.id),
        fragment_key(TournamentCacheInvalidator.school_summary_key(school.id)),
        fragment_key(TournamentCacheInvalidator.school_roster_key(school.id))
      ]
    end)
    keys.concat(@wrestlers.map { |wrestler| fragment_key(TournamentCacheInvalidator.wrestler_profile_key(wrestler.id)) })
    keys
  end

  def fragment_key(key)
    ApplicationController.new.combined_fragment_cache_key(key)
  end

  def assert_fragment_deleted(key)
    assert_not Rails.cache.exist?(fragment_key(key)), "Expected #{key.inspect} to be deleted"
  end

  def assert_fragment_cached(key)
    assert Rails.cache.exist?(fragment_key(key)), "Expected #{key.inspect} to remain cached"
  end

  def assert_brackets_deleted
    assert_not Rails.cache.exist?(TournamentCacheInvalidator.bracket_fragment_key(@weight.id))
    assert_not Rails.cache.exist?(TournamentCacheInvalidator.bracket_fragment_key(@weight.id, print: true))
  end

  def assert_brackets_cached
    assert Rails.cache.exist?(TournamentCacheInvalidator.bracket_fragment_key(@weight.id))
    assert Rails.cache.exist?(TournamentCacheInvalidator.bracket_fragment_key(@weight.id, print: true))
  end

  def assert_school_stats_deleted(school_ids = @schools.map(&:id))
    school_ids.each do |school_id|
      assert_fragment_deleted(TournamentCacheInvalidator.school_stats_key(school_id))
      assert_not Rails.cache.exist?(TournamentCacheInvalidator.school_stats_data_key(school_id))
    end
  end

  def assert_wrestler_views_deleted
    @schools.each do |school|
      assert_fragment_deleted(TournamentCacheInvalidator.school_summary_key(school.id))
      assert_fragment_deleted(TournamentCacheInvalidator.school_roster_key(school.id))
    end
    assert_fragment_deleted(TournamentCacheInvalidator.weight_roster_key(@weight.id))
    @wrestlers.each { |wrestler| assert_fragment_deleted(TournamentCacheInvalidator.wrestler_profile_key(wrestler.id)) }
  end

  def assert_affected_wrestler_views_deleted
    @schools.each { |school| assert_fragment_deleted(TournamentCacheInvalidator.school_roster_key(school.id)) }
    assert_fragment_deleted(TournamentCacheInvalidator.weight_roster_key(@weight.id))
    @wrestlers.each { |wrestler| assert_fragment_deleted(TournamentCacheInvalidator.wrestler_profile_key(wrestler.id)) }
  end

  def assert_rosters_cached
    @schools.each { |school| assert_fragment_cached(TournamentCacheInvalidator.school_roster_key(school.id)) }
    assert_fragment_cached(TournamentCacheInvalidator.weight_roster_key(@weight.id))
  end

  def assert_team_scores_deleted
    assert_fragment_deleted(TournamentCacheInvalidator.team_scores_key(@tournament.id))
    assert_not Rails.cache.exist?(TournamentCacheInvalidator.team_scores_data_key(@tournament.id))
  end

  def assert_team_scores_cached
    assert_fragment_cached(TournamentCacheInvalidator.team_scores_key(@tournament.id))
    assert Rails.cache.exist?(TournamentCacheInvalidator.team_scores_data_key(@tournament.id))
  end
end
