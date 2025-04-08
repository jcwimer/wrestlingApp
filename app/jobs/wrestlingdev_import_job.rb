class WrestlingdevImportJob < ApplicationJob
  queue_as :default
  
  # Class method for direct execution in test environment
  def self.perform_sync(tournament, import_data = nil)
    # Execute directly on provided objects
    importer = WrestlingdevImporter.new(tournament)
    importer.import_data = import_data if import_data
    importer.import_raw
  end
  
  def perform(tournament, import_data = nil)
    # Log information about the job
    Rails.logger.info("Starting import for tournament ##{tournament.id} (#{tournament.name})")
    
    # Execute the import
    importer = WrestlingdevImporter.new(tournament)
    importer.import_data = import_data if import_data
    importer.import_raw
  end
end 