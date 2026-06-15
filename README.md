# README
This application is being created to run a wrestling tournament.

# Info
**License:** MIT License

**Public Production Url:** [https://wrestlingdev.com](https://wrestlingdev.com)

**App Info**
* Ruby 4.0.1
* Rails 8.1.2
* DB MySQL/MariaDB
* Solid Cache -> MySQL/MariaDB for html partial caching
* Solid Queue -> MySQL/MariaDB for background job processing
* Solid Cable -> MySQL/MariaDB for websocket channels
* Hotwired Stimulus for client-side JavaScript

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

## Local tracing and performance dashboards

The local docker compose deployment includes an OpenTelemetry-based tracing and metrics stack. Rails sends OTLP traces to the OpenTelemetry Collector, the collector sends traces to Jaeger, and the collector's `span_metrics` connector converts those spans into Prometheus metrics for Grafana dashboards.

The local telemetry flow is:

```text
Rails
  -> OTLP HTTP http://otel-collector:4318
  -> OpenTelemetry Collector
    -> Jaeger for trace search/drill-down
    -> span_metrics connector
      -> Prometheus
        -> Grafana dashboards
```

Local URLs after running `bash deploy/deploy-test.sh`:

* App: [http://localhost](http://localhost)
* Grafana: [http://localhost:3000](http://localhost:3000)
* Jaeger: [http://localhost:16686](http://localhost:16686)
* Prometheus: [http://localhost:9090](http://localhost:9090)

Grafana is configured with `admin` / `admin`, and anonymous admin access is enabled for the local dev stack. Dashboards are provisioned from `deploy/grafana/dashboards` into the `WrestlingDev` folder. The dashboards mirror the old `influxdb-rails` sample dashboard set:

* Rails OpenTelemetry Overview
* Rails OpenTelemetry Performance
* Rails OpenTelemetry Requests
* Rails OpenTelemetry ActiveJob
* Rails OpenTelemetry Performance per Action
* Rails OpenTelemetry Performance per Request
* Rails OpenTelemetry Slowlog by Request
* Rails OpenTelemetry Slowlog by Action
* Rails OpenTelemetry Slowlog by SQL

Use Grafana to find slow routes/actions/jobs and Jaeger to inspect one specific slow trace. For example, if Grafana shows `GET /tournaments/:id` has a high p95, open Jaeger, select service `wrestlingdev`, filter to operation `GET /tournaments/:id`, and inspect a slow trace. Model/query spans such as `Tournament query`, `Match query`, `render_partial.action_view`, and ActiveJob spans appear under the parent request/job trace so you can correlate expensive work back to the controller action.

Important local telemetry files:

* Rails OpenTelemetry initializer: `config/initializers/opentelemetry.rb`
* Collector config: `deploy/otel-collector-config.yml`
* Prometheus config: `deploy/prometheus.yml`
* Grafana datasource provisioning: `deploy/grafana/provisioning/datasources/datasources.yml`
* Grafana dashboard provisioning: `deploy/grafana/provisioning/dashboards/dashboards.yml`
* Grafana dashboards: `deploy/grafana/dashboards/*.json`

The span metrics exported to Prometheus are named `traces_span_metrics_calls_total` and `traces_span_metrics_duration_milliseconds_*`. Common labels include `service_name`, `span_kind`, `span_name`, `code_namespace`, `http_route`, `http_request_method`, and `http_response_status_code`.

The production docker compose deployment uses the same collector, Jaeger, Prometheus, and Grafana setup. Grafana uses its built-in login, and Jaeger is protected at Traefik with basic auth because Jaeger does not provide its own login system.

To run a single test file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb` OR `rails test test/models/match_test.rb`

To run a single test inside a file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb TESTOPTS="--name='/test_Match_should_not_be_valid_if_an_incorrect_win_type_is_given/'"` OR `rails test test/models/match_test.rb --name=/test_Match_should_not_be_valid_if_an_incorrect_win_type_is_given/`

To run tests in verbose mode (outputs the time for each test file and the test file name)
`rails test -v`

## JavaScript tests with Vitest

Stimulus controllers and match-state JavaScript helpers are tested with Vitest. These tests live in `test/javascript`.

Run all JavaScript tests:

```bash
npm install
npm run test:js
```

Run one JavaScript test file:

```bash
npm run test:js -- test/javascript/match_state/engine.test.js
```

Run JavaScript tests in watch mode:

```bash
npm run test:js:watch
```

The full test runner also runs Vitest before Rails tests:

```bash
bash bin/run-all-tests.sh
```

Vitest currently covers client-side logic that is hard to test well with Minitest alone:

* The match-state rules engine: scoring, control changes, period choices, event replay, deletion, swapping, timers, accumulated match time, result defaults, and scoreboard payload generation.
* Stimulus controller behavior for the state page, legacy stat page, match result form, mat state page, scoreboard, spectate page, and live score updates.
* LocalStorage behavior for state/stat persistence, tournament-scoped keys, expiration timestamps, and cleanup of expired app-owned keys.
* Websocket payload handling at the JavaScript boundary, including deduped outbound state/stat messages and inbound scoreboard/spectate updates.

Minitest still owns the Rails side: controllers, permissions, models, channels, redirects, rendered ERB, and database behavior. Vitest fills the gap for logic that runs entirely in the browser without needing Cypress or a full browser session.

Cypress tests are deprecated for this project. Use Vitest for JavaScript unit coverage and Minitest for Rails behavior.

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
* `rake assets:clobber` - removes previously compiled assets stored in `public/assets` forcing Rails to recompile them from scratch the next time they are requested.
* `bundle-audit check --update` - check for vulnerabilities in Gemfile.lock

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

## Stimulus Controllers

The application uses Hotwired Stimulus for client-side JavaScript interactivity. Controllers can be found in `app/asssets/javascripts/controllers`

### Testing Stimulus Controllers

Stimulus controllers are tested with Vitest:

```bash
npm run test:js
```

# Deployment

The production version of this is currently deployed in Kubernetes (via K3s). See [Deploying with Kubernetes](deploy/kubernetes/README.md)

## CI/CD

The Jenkins pipeline definition for the `wrestlingdev` job lives in `ci_cd/Jenkinsfile`. On `development`, it checks out `origin/development`, rebuilds the production Docker image, runs `bin/run-all-tests.sh` inside the image in the `development-tests` stage, and deploys to the test host in the `deploy-test` stage after tests pass. On `master`, SCM-triggered and manually triggered builds run the `deploy-production` stage, map the `DOCKERHUB_PASSWORD` secret text credential into the `DOCKERHUB_PASSWORD` environment variable, push the production Docker image to Docker Hub, and deploy production. Timer-triggered `master` builds skip production deploys. Deploys use the Jenkins SSH credential used by the old freestyle job.

I'm using a Hetzner dedicated server with an i7-8700, 500GB NVME (RAID1), and 64GB ECC RAM. I have a hot standby (SQL read only replication) in my homelab.

## Server Configuration

### Puma and SolidQueue

The application uses an intelligent auto-scaling configuration for Puma (the web server) and SolidQueue (background job processing):

- **Auto Detection**: The server automatically detects available CPU cores and memory, and scales accordingly.
- **Worker Scaling**: In production, the number of Puma workers is calculated based on available memory (assuming ~400MB per worker) and CPU cores.
- **Thread Configuration**: Each Puma worker uses 5-12 threads by default, optimized for mixed I/O and CPU workloads.
- **SolidQueue Integration**: When `SOLID_QUEUE_IN_PUMA=true`, background jobs run within the Puma process.
- **Database Connection Pool**: Automatically sized based on the maximum number of threads across all workers.

All of these settings can be overridden with environment variables if needed.

To see the current configuration in the logs, look for these lines on startup:
```
Puma starting with X worker(s), Y-Z threads per worker
Available system resources: X CPU(s), YMMMB RAM
SolidQueue plugin enabled in Puma
```

I have deployed Mission Control as a UI for SolidQueue. The uri for mission control is `/jobs`.
For the development environment, the user/password is dev/secret. For the production environment, it is defined by environment variables WRESTLINGDEV_MISSION_CONTROL_USER/WRESTLINGDEV_MISSION_CONTROL_PASSWORD. You can see this in `config/environments/production.rb` and `config/environments/development.rb`.

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
* `WRESTLINGDEV_MISSION_CONTROL_USER` - mission control username
* `WRESTLINGDEV_MISSION_CONTROL_PASSWORD` - mission control password

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

### OpenTelemetry Configuration
* `OTEL_SERVICE_NAME` - Service name used in Jaeger, Prometheus labels, and Grafana dashboards. The local compose stack uses `wrestlingdev`.
* `OTEL_EXPORTER_OTLP_ENDPOINT` - OTLP endpoint for Rails traces. The local compose stack uses `http://otel-collector:4318`.
* `GRAFANA_HOST` - Production hostname for Grafana when using `deploy/docker-compose-prod.yml`.
* `GRAFANA_ADMIN_USER` - Production Grafana admin username.
* `GRAFANA_ADMIN_PASSWORD` - Production Grafana admin password.
* `JAEGER_HOST` - Production hostname for Jaeger when using `deploy/docker-compose-prod.yml`.
* `JAEGER_BASIC_AUTH_USERS` - Traefik basic-auth users for production Jaeger in `htpasswd` format. Quote this value in `prod.env` when using hashes that contain `$`, for example `JAEGER_BASIC_AUTH_USERS='admin:$apr1$...'`.

If `OTEL_EXPORTER_OTLP_ENDPOINT` is not set, the Rails OpenTelemetry initializer does not install tracing.

This project provides multiple ways to develop and deploy, with Docker being the primary method.

# Frontend Assets

## Sprockets to Propshaft Migration

- Propshaft will automatically include in its search paths the folders vendor/assets, lib/assets and app/assets of your project and of all the gems in your Gemfile. You can see all included files by using the reveal rake task: `rake assets:reveal`. When importing you'll use the relative path from this command.
- All css files are imported via `app/assets/stylesheets/application.css`. This is imported on `app/views/layouts/application.html.erb`.
  - Bootstrap and fontawesome have been downloaded locally to `vendor/`
- All js files are imported with a combination of "pinning" with `config/importmaps.rb` and `app/assets/javascript/application.js` and imported to `app/views/layouts/application.html.erb`
  - Jquery, bootstrap, datatables have been downloaded locally to `vendor/`
  - Turbo and action cable are gems and get pathed properly by propshaft.
- development is "nobuild" with `config.assets.build_assets = false` in `config/environments/development.rb`
- production needs to run rake assets:precompile. This is done in the `deploy/rails-prod-Dockerfile`.

## Stimulus Implementation

The application has been migrated from using vanilla JavaScript to Hotwired Stimulus. The Stimulus controllers are organized in:

- `app/assets/javascripts/controllers/` - Contains all Stimulus controllers
- `app/assets/javascripts/application.js` - Registers and loads all controllers

The importmap configuration in `config/importmap.rb` handles the loading of all JavaScript dependencies including Stimulus controllers.

# Using Repomix with LLMs
`npx repomix app test`
