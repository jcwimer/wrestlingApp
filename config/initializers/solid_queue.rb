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
