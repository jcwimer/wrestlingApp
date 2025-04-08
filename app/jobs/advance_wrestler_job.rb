class AdvanceWrestlerJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(wrestler, match)
    # Execute directly on provided objects
    service = AdvanceWrestler.new(wrestler, match)
    service.advance_raw
  end
  
  def perform(wrestler, match)
    # Execute the job
    service = AdvanceWrestler.new(wrestler, match)
    service.advance_raw
  end
end 