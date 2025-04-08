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
    
    # Execute the calculation
    school.calculate_score_raw
  end
end 