# frozen_string_literal: true

require 'test_helper'

class ApplicationJobTest < ActiveSupport::TestCase
  class EnqueueRetryJob < ApplicationJob
    class << self
      attr_accessor :outcomes

      def perform_later(*)
        outcome = outcomes.shift
        raise outcome if outcome.is_a?(StandardError)

        outcome
      end
    end
  end

  test 'retries a deadlocked queue enqueue' do
    EnqueueRetryJob.outcomes = [deadlocked_enqueue_error, deadlocked_enqueue_error, :enqueued]

    assert_equal :enqueued, EnqueueRetryJob.perform_later_with_enqueue_retry(:argument)
    assert_empty EnqueueRetryJob.outcomes
  end

  test 'does not retry other enqueue errors' do
    error = SolidQueue::Job::EnqueueError.new(ActiveRecord::RecordInvalid.new(Tournament.new))

    EnqueueRetryJob.outcomes = [error]

    assert_raises(SolidQueue::Job::EnqueueError) do
      EnqueueRetryJob.perform_later_with_enqueue_retry(:argument)
    end

    assert_empty EnqueueRetryJob.outcomes
  end

  private

  def deadlocked_enqueue_error
    raise ActiveRecord::Deadlocked, 'deadlock'
  rescue ActiveRecord::Deadlocked => e
    begin
      raise SolidQueue::Job::EnqueueError, e.message
    rescue SolidQueue::Job::EnqueueError => enqueue_error
      enqueue_error
    end
  end
end
