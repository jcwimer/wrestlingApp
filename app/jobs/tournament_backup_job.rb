class TournamentBackupJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(tournament, reason = nil)
    # Execute directly on provided objects
    service = TournamentBackupService.new(tournament, reason)
    service.create_backup_raw
  end
  
  def perform(tournament, reason = nil)
    # Log information about the job
    Rails.logger.info("Creating backup for tournament ##{tournament.id} (#{tournament.name}), reason: #{reason || 'manual'}")
    
    # Execute the backup
    service = TournamentBackupService.new(tournament, reason)
    service.create_backup_raw
  end
end 