# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  ENQUEUE_MAX_ATTEMPTS = 3

  around_perform :detect_n_plus_one_queries unless Rails.env.production?

  class << self
    def perform_later_with_enqueue_retry(...)
      attempts = 0

      begin
        perform_later(...)
      rescue SolidQueue::Job::EnqueueError => e
        attempts += 1
        raise unless e.cause.is_a?(ActiveRecord::Deadlocked) && attempts < ENQUEUE_MAX_ATTEMPTS

        sleep(rand * attempts * 0.05)
        retry
      end
    end
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def detect_n_plus_one_queries(&)
    return Prosopite.pause(&) if Prosopite.scan?

    Prosopite.scan(&)
  end
end
