# SolidQueue, SolidCache, and SolidCable Setup

This application uses Rails 8's built-in background job processing, caching, and ActionCable features with separate dedicated databases.

## Database Configuration

We use separate databases for the main application, SolidQueue, SolidCache, and SolidCable. This ensures complete separation and avoids any conflicts or performance issues.

In `config/database.yml`, we have the following setup:

```yaml
development:
  primary:
    database: db/development.sqlite3
  queue:
    database: db/development-queue.sqlite3
  cache:
    database: db/development-cache.sqlite3
  cable:
    database: db/development-cable.sqlite3

test:
  primary:
    database: db/test.sqlite3
  queue:
    database: db/test-queue.sqlite3
  cache:
    database: db/test-cache.sqlite3
  cable:
    database: db/test-cable.sqlite3

production:
  primary:
    database: <%= ENV['WRESTLINGDEV_DB_NAME'] %>
  queue:
    database: <%= ENV['WRESTLINGDEV_DB_NAME'] %>-queue
  cache:
    database: <%= ENV['WRESTLINGDEV_DB_NAME'] %>-cache
  cable:
    database: <%= ENV['WRESTLINGDEV_DB_NAME'] %>-cable
```

## Migration Structure

Migrations for each database are stored in their respective directories:

- Main application migrations: `db/migrate/`
- SolidQueue migrations: `db/queue/migrate/`
- SolidCache migrations: `db/cache/migrate/`
- SolidCable migrations: `db/cable/migrate/`

## Running Migrations

When deploying the application, you need to run migrations for each database separately:

```bash
# Run main application migrations
rails db:migrate

# Run SolidQueue migrations
rails db:migrate:queue

# Run SolidCache migrations
rails db:migrate:cache

# Run SolidCable migrations
rails db:migrate:cable
```

## Environment Configuration

In the environment configuration files (`config/environments/*.rb`), we've configured the paths for migrations and set up the appropriate adapters:

```ruby
# SolidCache configuration
config.cache_store = :solid_cache_store
config.paths["db/migrate"] << "db/cache/migrate"

# SolidQueue configuration
config.active_job.queue_adapter = :solid_queue
config.paths["db/migrate"] << "db/queue/migrate"

# ActionCable configuration
config.paths["db/migrate"] << "db/cable/migrate"
```

The database connections are configured in their respective YAML files:

### config/cache.yml
```yaml
production:
  database: cache
  # other options...
```

### config/queue.yml
```yaml
production:
  database: queue
  # other options...
```

### config/cable.yml
```yaml
production:
  adapter: solid_cable
  database: cable
  # other options...
```

## SolidQueue Configuration

SolidQueue is used for background job processing in all environments except test. The application is configured to run jobs as follows:

### Development and Production
In both development and production environments, SolidQueue is configured to process jobs asynchronously. This provides consistent behavior across environments while maintaining performance.

### Test
In the test environment only, jobs are executed synchronously using the inline adapter. This makes testing more predictable and avoids the need for separate worker processes during tests.

Configuration is in `config/initializers/solid_queue.rb`:

```ruby
# Configure ActiveJob queue adapter based on environment
if Rails.env.test?
  # In test, use inline adapter for simplicity and predictability
  Rails.application.config.active_job.queue_adapter = :inline
else
  # In development and production, use solid_queue with async execution
  Rails.application.config.active_job.queue_adapter = :solid_queue
  
  # Configure for regular async processing
  Rails.application.config.active_job.queue_adapter_options = {
    execution_mode: :async,
    logger: Rails.logger
  }
end
```

## Running with Puma

By default, the application is configured to run SolidQueue workers within the Puma processes. This is done by setting the `SOLID_QUEUE_IN_PUMA` environment variable to `true` in the production Dockerfile, which enables the Puma plugin for SolidQueue.

This means you don't need to run separate worker processes in production - the same Puma processes that handle web requests also handle background jobs. This simplifies deployment and reduces resource requirements.

The application uses an intelligent auto-scaling configuration for SolidQueue when running in Puma:

1. **Auto Detection**: The Puma configuration automatically detects available CPU cores and memory
2. **Worker Scaling**: Puma workers are calculated based on available memory and CPU cores
3. **SolidQueue Integration**: When enabled, SolidQueue simply runs within the Puma process

You can enable SolidQueue in Puma by setting:
```bash
SOLID_QUEUE_IN_PUMA=true
```

In `config/puma.rb`:
```ruby
# Run the Solid Queue supervisor inside of Puma for single-server deployments
if ENV["SOLID_QUEUE_IN_PUMA"] == "true" && !Rails.env.test?
  # Simply load the SolidQueue plugin with default settings
  plugin :solid_queue
  
  # Log that SolidQueue is enabled
  puts "SolidQueue plugin enabled in Puma"
end
```

On startup, you'll see a log message confirming that SolidQueue is enabled in Puma.

## Job Owner Tracking

Jobs in this application include metadata about their owner (typically a tournament) to allow tracking and displaying job status to tournament directors. Each job includes:

- `job_owner_id`: Usually the tournament ID
- `job_owner_type`: A description of the job (e.g., "Create a backup")

This information is serialized with the job and can be used to filter and display jobs on tournament pages.

## Job Pattern: Simplified Job Enqueuing

Our job classes follow a simplified pattern that works consistently across all environments:

1. Service classes always use `perform_later` to enqueue jobs
2. The execution mode is determined centrally by the ActiveJob adapter configuration
3. Each job finds the needed records and calls the appropriate method on the service class or model

Example service class method:
```ruby
def create_backup
  # Set up job owner information for tracking
  job_owner_id = @tournament.id
  job_owner_type = "Create a backup"
  
  # Use perform_later which will execute based on centralized adapter config
  TournamentBackupJob.perform_later(@tournament.id, @reason, job_owner_id, job_owner_type)
end
```

Example job class:
```ruby
class TournamentBackupJob < ApplicationJob
  queue_as :default
  
  # For storing job owner metadata
  attr_accessor :job_owner_id, :job_owner_type
  
  # For execution via job queue with IDs
  def perform(tournament_id, reason, job_owner_id = nil, job_owner_type = nil)
    # Store job owner metadata
    self.job_owner_id = job_owner_id
    self.job_owner_type = job_owner_type
    
    # Find the record
    tournament = Tournament.find_by(id: tournament_id)
    return unless tournament
    
    # Create the service class and call the raw method
    TournamentBackupService.new(tournament, reason).create_backup_raw
  end
end
```

## Job Classes

The following job classes are available:

- `AdvanceWrestlerJob`: For advancing wrestlers in brackets
- `TournamentBackupJob`: For creating tournament backups
- `WrestlingdevImportJob`: For importing from wrestlingdev
- `GenerateTournamentMatchesJob`: For generating tournament matches
- `CalculateSchoolScoreJob`: For calculating school scores 

## Job Status

Jobs in this application can have the following statuses:

1. **Running**: Job is currently being executed. This is determined by checking if a record exists in the `solid_queue_claimed_executions` table for the job.

2. **Scheduled**: Job is scheduled to run at a future time. This is determined by checking if `scheduled_at` is in the future.

3. **Error**: Job has failed. This is determined by:
   - Checking if a record exists in the `solid_queue_failed_executions` table for the job
   - Checking if `failed_at` is present

4. **Completed**: Job has finished successfully. This is determined by checking if `finished_at` is present and no error records exist.

5. **Pending**: Job is waiting to be picked up by a worker. This is the default status when none of the above conditions are met.

## Testing Job Status

To help with testing the job status display in the UI, several rake tasks are provided:

```bash
# Create a test "Running" job for the first tournament
rails jobs:create_running

# Create a test "Completed" job for the first tournament
rails jobs:create_completed

# Create a test "Error" job for the first tournament
rails jobs:create_failed
```

## Troubleshooting

If you encounter issues with SolidQueue or the separate databases:

1. Make sure all databases exist:
   ```sql
   CREATE DATABASE IF NOT EXISTS wrestlingtourney;
   CREATE DATABASE IF NOT EXISTS wrestlingtourney-queue;
   CREATE DATABASE IF NOT EXISTS wrestlingtourney-cache;
   CREATE DATABASE IF NOT EXISTS wrestlingtourney-cable;
   ```

2. Ensure all migrations have been run for each database.

3. Check that environment configurations properly connect to the right databases.

4. Verify that the database user has appropriate permissions for all databases.

5. If jobs aren't processing in production, check that `SOLID_QUEUE_IN_PUMA` is set to `true` in your environment.

## References

- [SolidQueue README](https://github.com/rails/solid_queue)
- [Rails Multiple Database Configuration](https://guides.rubyonrails.org/active_record_multiple_databases.html) 