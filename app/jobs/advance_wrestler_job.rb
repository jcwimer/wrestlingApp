class AdvanceWrestlerJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(wrestler, match)
    # Execute directly on provided objects
    service = AdvanceWrestler.new(wrestler, match)
    service.advance_raw
  end
  
  def perform(wrestler, match)
    # Get tournament from wrestler
    tournament = wrestler.tournament
    
    # Create job status record
    job_name = "Advancing wrestler #{wrestler.name}"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "Match ID: #{match&.bout_number || 'No match'}"
    )
    
    begin
      # Execute the job
      service = AdvanceWrestler.new(wrestler, match)
      service.advance_raw
      
      # Remove the job status record on success
      TournamentJobStatus.complete_job(tournament.id, job_name)
    rescue => e
      # Update status to errored
      job_status.update(status: "Errored", details: "Error: #{e.message}")
      
      # Re-raise the error for SolidQueue to handle
      raise e
    end
  end
end 