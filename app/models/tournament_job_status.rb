# frozen_string_literal: true

class TournamentJobStatus < ApplicationRecord
  belongs_to :tournament, optional: false

  # Validations
  validates :job_name, presence: true
  validates :status, presence: true
  validates :status, inclusion: { in: %w[Queued Running Errored], allow_nil: false }

  # Scopes
  scope :active, -> { where.not(status: 'Errored') }

  # Class methods to find jobs for a tournament
  def self.for_tournament(tournament)
    where(tournament_id: tournament.id)
  end

  # Clean up completed jobs (should be called when job finishes successfully)
  def self.complete_job(tournament_id, job_name)
    where(tournament_id: tournament_id, job_name: job_name).destroy_all
  end
end
