# Configuration for Solid Queue in Rails 8
# Documentation: https://github.com/rails/solid_queue

# Configure ActiveJob queue adapter based on environment
if ! Rails.env.test?
  # In production and development, use solid_queue with async execution
  Rails.application.config.active_job.queue_adapter = :solid_queue
  
  # Configure for regular async processing
  Rails.application.config.active_job.queue_adapter_options = {
    execution_mode: :async,
    logger: Rails.logger
  }
else
  # In test, use inline adapter for simplicity
  Rails.application.config.active_job.queue_adapter = :inline
end

# Register the custom attributes we want to track
module SolidQueueConfig
  mattr_accessor :job_owner_tracking_enabled, default: true
end

# Define ActiveJobExtensions - this should match what's already being used in ApplicationJob
module ActiveJobExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :job_owner_id, :job_owner_type
  end
end

# Solid Queue adapter hooks to save job owner info to columns
module SolidQueueAdapterExtensions
  def enqueue(job)
    job_data = job.serialize
    job_id = super
    
    # Store job owner info after job is created
    if defined?(SolidQueue::Job) && job_data["job_owner_id"].present?
      Rails.logger.info("Setting job_owner for SolidQueue job #{job_id}: #{job_data["job_owner_id"]}, #{job_data["job_owner_type"]}")
      begin
        # Use execute_query for direct SQL to bypass any potential ActiveRecord issues
        ActiveRecord::Base.connection.execute(
          "UPDATE solid_queue_jobs SET job_owner_id = #{ActiveRecord::Base.connection.quote(job_data["job_owner_id"])}, " +
          "job_owner_type = #{ActiveRecord::Base.connection.quote(job_data["job_owner_type"])} " +
          "WHERE id = #{job_id}"
        )
        Rails.logger.info("Successfully updated job_owner info for job #{job_id}")
      rescue => e
        Rails.logger.error("Error updating job_owner info: #{e.message}")
      end
    end
    
    job_id
  end
end

# Apply extensions 
Rails.application.config.after_initialize do
  # Add extensions to ActiveJob::QueueAdapters::SolidQueueAdapter if defined
  if defined?(ActiveJob::QueueAdapters::SolidQueueAdapter)
    Rails.logger.info("Applying SolidQueueAdapterExtensions")
    ActiveJob::QueueAdapters::SolidQueueAdapter.prepend(SolidQueueAdapterExtensions)
  end
end 