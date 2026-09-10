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
    wrestler_ids = matches.flat_map { |match| [match.w1, match.w2] }.compact.uniq
    wrestlers_by_id = Wrestler.where(id: wrestler_ids).index_by(&:id)
    job_name = "Advancing #{matches.size == 1 ? "bout #{matches.first&.bout_number}" : "tournament byes"}"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "Match IDs: #{matches.map(&:id).join(', ')}"
    )
    
    begin
      tracker = { processed: Set.new, weight_ids: Set.new, wrestler_ids: Set.new, contexts: {} }
      matches.each do |match|
        [match.w1, match.w2].compact.uniq.each do |wrestler_id|
          wrestler = wrestlers_by_id[wrestler_id]
          BracketAdvancement::AdvanceWrestler.new(wrestler, match).advance_raw(tracker:, invalidate: false, reload: false) if wrestler
        end
      end

      CalculateTournamentTeamScoresJob.perform_now(tournament.id)
      TournamentCacheInvalidator.advancement_completed(tracker[:weight_ids].to_a, tracker[:wrestler_ids].to_a)
      TournamentJobStatus.complete_job(tournament.id, job_name)
    rescue => e
      job_status.update(status: "Errored", details: "Error: #{e.message}")
      raise
    end
  end
end 
