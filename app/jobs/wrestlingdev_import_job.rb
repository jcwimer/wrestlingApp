class WrestlingdevImportJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(tournament, import_data = nil)
    # Execute directly on provided objects
    importer = WrestlingdevImporter.new(tournament)
    importer.import_data = import_data if import_data
    importer.import_raw
  end
  
  def perform(tournament, import_data = nil)
    # Log information about the job
    Rails.logger.info("Starting import for tournament ##{tournament.id} (#{tournament.name})")
    
    # Create job status record
    job_name = "Importing tournament"
    job_status = TournamentJobStatus.create!(
      tournament: tournament,
      job_name: job_name,
      status: "Running",
      details: "Processing backup data"
    )
    
    begin
      # Execute the import
      importer = WrestlingdevImporter.new(tournament)
      importer.import_data = import_data if import_data
      importer.import_raw
      
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