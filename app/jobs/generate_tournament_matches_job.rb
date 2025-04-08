class GenerateTournamentMatchesJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(tournament)
    # Execute directly on provided objects
    generator = GenerateTournamentMatches.new(tournament)
    generator.generate_raw
  end
  
  def perform(tournament)
    # Log information about the job
    Rails.logger.info("Starting tournament match generation for tournament ##{tournament.id}")
    
    begin
      # Execute the job
      generator = GenerateTournamentMatches.new(tournament)
      generator.generate_raw
      
      Rails.logger.info("Completed tournament match generation for tournament ##{tournament.id}")
    rescue => e
      Rails.logger.error("Error generating tournament matches: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise # Re-raise the error so it's properly recorded
    end
  end
end 