# README
This application is being created to run a wrestling tournament.

# Info
**License:** MIT License

**Public Production Url:** [https://wrestlingdev.com](https://wrestlingdev.com)

**App Info**
* Ruby 3.2.0
* Rails 8.0.0
* DB MySQL/MariaDB
* Memcached
* Solid Queue for background job processing

# Development

## Develop with docker
All dependencies are wrapped in docker. Tests can be run with `bash bin/run-tests-with-docker.sh`. That is the same command used in CI.

If you want to run a full rails environment shell in docker run: `bash bin/rails-dev-run.sh wrestlingdev-dev`
From here, you can run the normal rails commands.

Special rake tasks:
* `tournament:assign_random_wins` will complete all matches for tournament 204 from seed data. This task takes a while since it waits for the worker to complete tasks. In my testing, it takes about 3.5 hours to complete.
  * `rake tournament:assign_random_wins` to run locally
  * `docker-compose -f deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins` to run on the dev server

To deploy a full local version of the app `bash deploy/deploy-test.sh` (this requires docker-compose to be installed). This deploys a full version of the app including Rails app, Solid Queue background workers, Memcached, and MariaDB. Now, you can open [http://localhost](http://localhost).

In development environments, background jobs run inline (synchronously) by default. In production and staging environments, jobs are processed asynchronously by separate worker processes.

To run a single test file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb`

To run a single test inside a file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb TESTOPTS="--name='/test_Match_should_not_be_valid_if_an_incorrect_win_type_is_given/'"`

## Develop with rvm
With rvm installed, run `rvm install ruby-3.2.0`
Then, `cd ../; cd wrestlingApp`. This will load the gemset file in this repo.

## Quick Rails Commands Without Local Installation
You can run one-off Rails commands without installing Rails locally by using the development Docker image:

```bash
# Build the development image
docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .

# Run a specific Rails command
docker run -it -v $(pwd):/rails wrestlingdev-dev rails db:migrate

# Run the Rails console
docker run -it -v $(pwd):/rails wrestlingdev-dev rails console

# Run a custom Rake task
docker run -it -v $(pwd):/rails wrestlingdev-dev rake jobs:create_running
```

This approach is useful for quick commands without the need to set up a full development environment. The image contains all required dependencies for the application.

For a more convenient experience with a persistent shell, use the included wrapper script:

```bash
bash bin/rails-dev-run.sh wrestlingdev-dev
```

## Rails commands
Whether you have a shell from docker or are using rvm you can now run normal rails commands:
* `bundle config set --local without 'production'`
* `bundle install`
* `rake db:seed` Development login email from seed data: `test@test.com` password: `password`
* `rake test`
* `rails generate blah blah blah`
* ` rails s -b 0.0.0.0` port 3000 is exposed. You can open [http://localhost:3000](http://localhost:3000) after running that command
* etc.
* `rake finish_seed_tournaments` will complete all matches from the seed data. This command takes about 5 minutes to execute

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

See `SOLID_QUEUE.md` for more details about the job system.

## Update gems

1. `bash bin/rails-dev-run.sh wrestlingdev-dev` to open a contianer with a rails shell available
2. `bundle config --delete without` to remove the bundle config that ignores production gems
3. `bundle update`
4. `bundle config set --local without 'production'` to reset your without locally

Note: If updating rails, do not change the version in `Gemfile` until after you run `bash bin/rails-dev-run.sh wrestlingdev-dev`. Creating the container will fail due to a mismatch in Gemfile and Gemfile.lock.
Then run `rails app:update` to update rails.

# Deployment

The production version of this is currently deployed in Kubernetes. See [Deploying with Kubernetes](deploy/kubernetes/README.md)

## Server Configuration

### Puma and SolidQueue

The application uses an intelligent auto-scaling configuration for Puma (the web server) and SolidQueue (background job processing):

- **Auto Detection**: The server automatically detects available CPU cores and memory, and scales accordingly.
- **Worker Scaling**: In production, the number of Puma workers is calculated based on available memory (assuming ~400MB per worker) and CPU cores.
- **Thread Configuration**: Each Puma worker uses 5-12 threads by default, optimized for mixed I/O and CPU workloads.
- **SolidQueue Integration**: When `SOLID_QUEUE_IN_PUMA=true`, background jobs run within the Puma process.
- **Database Connection Pool**: Automatically sized based on the maximum number of threads across all workers.

The configuration is designed to adapt to different environments:
- Small servers: Uses fewer workers to avoid memory exhaustion
- Large servers: Scales up to utilize available CPU cores
- Development: Uses a single worker for simplicity

All of these settings can be overridden with environment variables if needed.

To see the current configuration in the logs, look for these lines on startup:
```
Puma starting with X worker(s), Y-Z threads per worker
Available system resources: X CPU(s), YMMMB RAM
SolidQueue plugin enabled in Puma
```

## Environment Variables

### Required Environment Variables
* `WRESTLINGDEV_DB_NAME` - Database name for the main application
* `WRESTLINGDEV_DB_USR` - Database username
* `WRESTLINGDEV_DB_PWD` - Database password
* `WRESTLINGDEV_DB_HOST` - Database hostname
* `WRESTLINGDEV_DB_PORT` - Database port
* `WRESTLINGDEV_DEVISE_SECRET_KEY` - Secret key for Devise (can be generated with `rake secret`)
* `WRESTLINGDEV_SECRET_KEY_BASE` - Rails application secret key (can be generated with `rake secret`)
* `WRESTLINGDEV_EMAIL` - Email address (currently must be a Gmail account)
* `WRESTLINGDEV_EMAIL_PWD` - Email password

### Optional Environment Variables
* `SOLID_QUEUE_IN_PUMA` - Set to "true" to run Solid Queue workers inside Puma (default in development)
* `WEB_CONCURRENCY` - Number of Puma workers (auto-detected based on CPU/memory if not specified)
* `RAILS_MIN_THREADS` - Minimum number of threads per Puma worker (defaults to 5)
* `RAILS_MAX_THREADS` - Maximum number of threads per Puma worker (defaults to 12)
* `DATABASE_POOL_SIZE` - Database connection pool size (auto-calculated if not specified)
* `SOLID_QUEUE_WORKERS` - Number of SolidQueue workers (auto-calculated if not specified)
* `SOLID_QUEUE_THREADS` - Number of threads per SolidQueue worker (auto-calculated if not specified)
* `PORT` - Port for Puma server to listen on (defaults to 3000)
* `RAILS_LOG_LEVEL` - Log level for Rails in production (defaults to "info")
* `PIDFILE` - PID file location for Puma
* `RAILS_SSL_TERMINATION` - Set to "true" to enable force_ssl in production (HTTPS enforcement)
* `REVERSE_PROXY_SSL_TERMINATION` - Set to "true" if the app is behind a SSL-terminating reverse proxy
* `CI` - Set in CI environments to enable eager loading in test environment
* `WRESTLINGDEV_NEW_RELIC_LICENSE_KEY` - New Relic license key for monitoring

### InfluxDB Configuration (all required if using InfluxDB)
* `WRESTLINGDEV_INFLUXDB_DATABASE` - InfluxDB database name
* `WRESTLINGDEV_INFLUXDB_HOST` - InfluxDB hostname
* `WRESTLINGDEV_INFLUXDB_PORT` - InfluxDB port
* `WRESTLINGDEV_INFLUXDB_USERNAME` - InfluxDB username (optional)
* `WRESTLINGDEV_INFLUXDB_PASSWORD` - InfluxDB password (optional)

See `SOLID_QUEUE.md` for details about the job system configuration.

This project provides multiple ways to develop and deploy, with Docker being the primary method.