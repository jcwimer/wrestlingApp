require "set"

class AdvanceWrestlerJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(*arguments) { "tournament:#{arguments.last}" }, group: "tournament_updates"
  
  def perform(match_ids, tournament_id, legacy_tournament_id = nil)
    if legacy_tournament_id
      match_ids = [tournament_id.id]
      tournament_id = legacy_tournament_id
    end

    tournament = Tournament.find(tournament_id)
    matches = Match.where(id: Array(match_ids)).to_a
    assigned_matches = matches.filter_map { |match| [match, match.mat] if match.mat }
    job_name = "Advancing #{matches.size == 1 ? "bout #{matches.first&.bout_number}" : "tournament byes"}"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "Match IDs: #{matches.map(&:id).join(', ')}"
    )
    
    begin
      tracker = { processed: Set.new, weight_ids: Set.new, wrestler_ids: Set.new }
      matches.each do |match|
        [match.w1, match.w2].compact.uniq.each do |wrestler_id|
          wrestler = Wrestler.find_by(id: wrestler_id)
          AdvanceWrestler.new(wrestler, match).advance_raw(tracker:, invalidate: false) if wrestler
        end
      end

      queue_operation = MatQueueOperation.new(tournament)
      assigned_matches.each do |match, mat|
        queue_operation.advance(
          mat,
          match,
          invalidate_cached_views: false,
          deferred_wrestler_ids: tracker[:wrestler_ids]
        )
      end
      queue_operation.refill(
        invalidate_cached_views: false,
        deferred_wrestler_ids: tracker[:wrestler_ids]
      )
      CalculateTournamentTeamScoresJob.perform_now(tournament.id)
      TournamentCacheInvalidator.advancement_completed(tracker[:weight_ids].to_a, tracker[:wrestler_ids].to_a)
      TournamentJobStatus.complete_job(tournament.id, job_name)
    rescue => e
      job_status.update(status: "Errored", details: "Error: #{e.message}")
      raise
    end
  end
end 
