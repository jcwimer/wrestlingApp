# Configure SQLite for better concurrency handling
# This applies only in development mode with SQLite

Rails.application.config.after_initialize do
  if Rails.env.development? && ActiveRecord::Base.connection.adapter_name == "SQLite"
    connection = ActiveRecord::Base.connection
    
    # 1. Configure SQLite behavior for better concurrency
    # Increase the busy timeout to 30 seconds (in milliseconds)
    connection.execute("PRAGMA busy_timeout = 30000;")
    
    # Set journal mode to WAL for better concurrency
    connection.execute("PRAGMA journal_mode = WAL;")
    
    # Configure synchronous mode for better performance
    connection.execute("PRAGMA synchronous = NORMAL;")
    
    # Temp store in memory for better performance
    connection.execute("PRAGMA temp_store = MEMORY;")
    
    # Use a larger cache size (8MB)
    connection.execute("PRAGMA cache_size = -8000;")
    
    # Set locking mode to NORMAL
    connection.execute("PRAGMA locking_mode = NORMAL;")
    
    # 2. Patch SQLite adapter with retry logic for development only
    if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
      module SQLite3RetryLogic
        MAX_RETRIES = 5
        RETRY_DELAY = 0.5 # seconds
        RETRIABLE_EXCEPTIONS = [
          SQLite3::BusyException, 
          ActiveRecord::StatementInvalid, 
          ActiveRecord::StatementTimeout
        ]
        
        def self.included(base)
          base.class_eval do
            alias_method :original_execute, :execute
            alias_method :original_exec_query, :exec_query
            
            def execute(*args)
              with_retries { original_execute(*args) }
            end
            
            def exec_query(*args)
              with_retries { original_exec_query(*args) }
            end
            
            private
              def with_retries
                retry_count = 0
                begin
                  yield
                rescue *RETRIABLE_EXCEPTIONS => e
                  if e.to_s.include?('database is locked') && retry_count < MAX_RETRIES
                    retry_count += 1
                    delay = RETRY_DELAY * retry_count
                    Rails.logger.warn "SQLite database locked, retry #{retry_count}/#{MAX_RETRIES} after #{delay}s: #{e.message}"
                    sleep(delay)
                    retry
                  else
                    raise
                  end
                end
              end
          end
        end
      end
      
      # Apply the patch only in development
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.include(SQLite3RetryLogic)
      Rails.logger.info "SQLite adapter patched with retry logic for database locks"
    end
    
    Rails.logger.info "SQLite configured for improved concurrency in development"
  end
end 