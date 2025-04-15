class CalculateSchoolScoreJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(school)
    # Execute directly on provided objects
    school.calculate_score_raw
  end
  
  def perform(school)
    # Log information about the job
    Rails.logger.info("Calculating score for school ##{school.id} (#{school.name})")
    
    # Create job status record
    tournament = school.tournament
    job_name = "Calculating team score for #{school.name}"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "School ID: #{school.id}"
    )
    
    begin
      # Execute the calculation
      school.calculate_score_raw
      
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