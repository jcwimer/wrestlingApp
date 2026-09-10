class ApplicationJob < ActiveJob::Base
  around_perform :detect_n_plus_one_queries unless Rails.env.production?

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def detect_n_plus_one_queries(&block)
    return Prosopite.pause(&block) if Prosopite.scan?

    Prosopite.scan(&block)
  end
end
