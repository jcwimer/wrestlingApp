# frozen_string_literal: true

class CalculateSchoolScoreJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: lambda { |school_data|
    "tournament:#{school_data[:tournament_id]}"
  }, group: 'tournament_updates'

  # Need for TournamentJobStatusIntegrationTest
  def self.perform_sync(school)
    # Execute directly on provided objects
    school.calculate_score_raw
  end

  def perform(school_data)
    school_id = school_data.fetch(:school_id)
    tournament = Tournament.preload(
      { schools: :deductedPoints },
      weights: [
        :matches,
        { wrestlers: [:deductedPoints, :matches_as_w1, :matches_as_w2, { weight: :tournament }] }
      ]
    ).find(school_data.fetch(:tournament_id))
    school = tournament.schools.find { |candidate| candidate.id == school_id }
    wrestlers = tournament.weights.flat_map(&:wrestlers).select { |wrestler| wrestler.school_id == school.id }

    # Log information about the job
    Rails.logger.info("Calculating score for school ##{school.id} (#{school.name})")

    # Create job status record
    tournament = school.tournament
    job_name = "Calculating team score for #{school.name}"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: 'Running',
      details: "School ID: #{school.id}"
    )

    begin
      # Execute the calculation
      school.calculate_score_raw(wrestlers: wrestlers)

      # Remove the job status record on success
      TournamentJobStatus.complete_job(tournament.id, job_name)
    rescue StandardError => e
      # Update status to errored
      job_status.update(status: 'Errored', details: "Error: #{e.message}")

      # Re-raise the error for SolidQueue to handle
      raise e
    end
  end
end
