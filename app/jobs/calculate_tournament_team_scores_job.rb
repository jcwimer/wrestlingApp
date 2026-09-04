class CalculateTournamentTeamScoresJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(tournament_id) { "tournament:#{tournament_id}" }, group: "tournament_updates"

  def perform(tournament_id)
    tournament = Tournament.preload(
      { schools: :deductedPoints },
      weights: [
        :matches,
        { wrestlers: [:deductedPoints, :matches_as_w1, :matches_as_w2] }
      ]
    ).find(tournament_id)
    wrestlers_by_school = tournament.weights.flat_map(&:wrestlers).group_by(&:school_id)
    timestamp = Time.current
    updates = tournament.schools.map do |school|
      wrestlers = wrestlers_by_school[school.id] || []
      {
        id: school.id,
        score: school.total_points_scored_by_wrestlers(wrestlers) - school.total_points_deducted,
        updated_at: timestamp
      }
    end

    School.upsert_all(updates) if updates.any?
    TournamentCacheInvalidator.team_scores_calculated(tournament.id)
  end
end
