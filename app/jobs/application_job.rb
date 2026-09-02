class ApplicationJob < ActiveJob::Base
  around_perform :pause_request_query_scan unless Rails.env.production?

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def pause_request_query_scan(&block)
    return block.call unless Prosopite.scan?

    Prosopite.pause(&block)
  end
end
