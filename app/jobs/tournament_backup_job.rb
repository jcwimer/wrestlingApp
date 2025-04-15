class TournamentBackupJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(tournament, reason = nil)
    # Execute directly on provided objects
    service = TournamentBackupService.new(tournament, reason)
    service.create_backup_raw
  end
  
  def perform(tournament, reason = nil)
    # Log information about the job
    Rails.logger.info("Creating backup for tournament ##{tournament.id} (#{tournament.name}), reason: #{reason || 'manual'}")
    
    # Create job status record
    job_name = "Backing up tournament"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "Reason: #{reason || 'manual'}"
    )
    
    begin
      # Execute the backup
      service = TournamentBackupService.new(tournament, reason)
      service.create_backup_raw
      
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