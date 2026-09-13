# WrestlingDev

Web application for running wrestling tournaments.

**Production:** [https://wrestlingdev.com](https://wrestlingdev.com)  
**License:** MIT

## Stack

| Component | Version / notes |
|-----------|----------------|
| Ruby | 4.0.5 |
| Rails | 8.1.3.1 |
| Node.js | 24 in Docker images; Vitest requires 22.12+, 24, or 26+ |
| Database | SQLite (development/test), MariaDB (production) |
| Background jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS, Propshaft, importmap |

Rails environments: `test`, `development`, and `production`. Development and test use SQLite; all deployed environments use MariaDB.

## Repo layout
This is a rails application with standard rails folders.
Extra folders added:
- deploy - contains dockerfiles, docker compose configurations for test and production environments, and kubernetes manifsets for production environments
- loadtests - contains test files for load tests
- import_jsons - contains json data for importing tournaments for me to test all files except .keep are gitignored
- ci_cd - contains my ci cd files and scripts for my ci cd pipelines
- agent_prompts - are saved prompts for regular tasks I ask of agents
- test/javascript - contains vitest files for testing javascript functionality
- coverage

## Developer Quickstart

### Docker (recommended)

Build the development image and open a shell:

```bash
bash bin/rails-dev-run.sh wrestlingdev-dev
```

From the container shell:

```bash
bundle install
bin/rails db:setup    # or db:migrate && db:seed
bin/dev             # Rails + Tailwind watcher on http://localhost:3000
```

Run one-off commands without a persistent shell:

```bash
docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .
docker run -it -v $(pwd):/rails wrestlingdev-dev bin/rails db:migrate
```

### rbenv (local)

With rbenv installed:

```bash
rbenv install # this reads the .ruby-version file
bundle config set --local without 'production'
bundle install
bin/rails db:setup
bin/dev
```

Seed login: `test@test.com` / `password`

### Volta (local JavaScript)

```bash
volta install node@24
npm install
npm run test:js
```

Watch mode: `npm run test:js:watch`

Coverage reports:

```bash
COVERAGE=true bin/rails test          # Ruby: coverage/index.html
npm run test:js:coverage              # JavaScript: coverage/javascript/index.html
```

### Tests

CI runs the same suite as local Docker:

```bash
bash bin/run-tests-with-docker.sh
```

Or run tests directly:

```bash
# All tests (Vitest + Rails, with coverage)
bash bin/run-all-tests.sh

# Rails only
bin/rails test

# Rails with coverage
COVERAGE=true bin/rails test

# Single file
bin/rails test test/models/match_test.rb

# JavaScript (Vitest; use Volta section above for local Node setup)
npm install
npm run test:js
npm run test:js:coverage
```

### Common tasks

```bash
rake finish_seed_tournaments          # complete seeded tournament matches (~5 min)
rake jobs:create_running              # test job status UI
rake tournament:assign_random_wins    # complete tournament 204 via workers (~3.5 hours)
bundle-audit check --update
```

On the local full stack (`deploy-test.sh`):

```bash
docker compose -f deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins
```

Solid Queue runs inside Puma by default (`SOLID_QUEUE_IN_PUMA=true` in development and deployed environments). Set `SOLID_QUEUE_IN_PUMA=false` to run workers separately. The test environment uses the `:test` adapter, which runs jobs inline during tests.

Mission Control (Solid Queue UI) is at `/jobs`. Development credentials: `dev` / `secret`.

## Deployment

### CI/CD

Jenkins job `wrestlingdev` (`ci_cd/Jenkinsfile`):

| Branch | Behavior |
|--------|----------|
| `development` | Run tests, deploy to test server; also runs nightly |
| `master` | Deploy production (SCM-triggered or manual; timer builds skip deploy) |

**Release flow:** develop on `development` → rebase with `master` → merge to `master` and push.

Jenkins polls SCM every five minutes. Concurrent builds of the same branch are disabled.

Production images are pushed to Docker Hub (`jcwimer/wrestlingdev`). Test and production deploys use SSH credentials configured in Jenkins.

### Local full stack

Deploy a production-like stack locally (Rails, MariaDB, Solid Queue, telemetry):

```bash
bash deploy/deploy-test.sh
```

App: [http://localhost](http://localhost)  
Grafana: [http://localhost:3000](http://localhost:3000) (admin/admin)

Docker Compose telemetry includes cAdvisor for per-container CPU and memory metrics. It is used to attribute local load-generator overhead during load-test analysis and is intentionally not part of the Kubernetes deployment.

This resets the database with seed data on each deploy.

### Production (Docker Compose)

Primary production deployment uses Docker Compose with Traefik. On the server:

1. Copy `deploy/prod.env.example` to `prod.env` in the deploy working directory and fill in values.
2. Run `bash deploy/deploy-prod.sh` (downloads manifests from `master` and runs migrations).

`prod.env` keys map into the app container as `WRESTLINGDEV_*` variables (for example, `RAILS_SECRET_KEY` → `WRESTLINGDEV_SECRET_KEY_BASE`). `MYSQLD_EXPORTER_PASSWORD` is also required by `deploy-prod.sh`.

Keep `deploy/docker-compose-prod.yml` and `deploy/kubernetes/` in sync when changing deployment config.

### Kubernetes (DR)

Disaster-recovery environment on K3s. See [deploy/kubernetes/README.md](deploy/kubernetes/README.md).

### Environment variables

Production Docker Compose uses `prod.env` (see `deploy/prod.env.example`). Several keys are mapped into the Rails container as `WRESTLINGDEV_*` variables:

| `prod.env` | App container |
|------------|---------------|
| `RAILS_SECRET_KEY` | `WRESTLINGDEV_SECRET_KEY_BASE` |
| `GMAIL_PASSWORD` | `WRESTLINGDEV_EMAIL_PWD` |
| `MYSQL_PASSWORD` | `WRESTLINGDEV_DB_PWD` and MariaDB root password |
| `MISSION_CONTROL_PASSWORD` | `WRESTLINGDEV_MISSION_CONTROL_PASSWORD` |

Kubernetes and direct container configuration set the `WRESTLINGDEV_*` names below.

#### Required for Rails

| Variable | Purpose |
|----------|---------|
| `WRESTLINGDEV_DB_NAME` | Database name |
| `WRESTLINGDEV_DB_USR` | Database username |
| `WRESTLINGDEV_DB_PWD` | Database password |
| `WRESTLINGDEV_DB_HOST` | Database hostname |
| `WRESTLINGDEV_DB_PORT` | Database port |
| `WRESTLINGDEV_SECRET_KEY_BASE` | Rails `secret_key_base` (`rake secret`) |
| `WRESTLINGDEV_EMAIL` | Outbound email address (Gmail) |
| `WRESTLINGDEV_EMAIL_PWD` | Email password |
| `WRESTLINGDEV_MISSION_CONTROL_USER` | Mission Control username |
| `WRESTLINGDEV_MISSION_CONTROL_PASSWORD` | Mission Control password |

#### Optional for Rails

| Variable | Default / notes |
|----------|-----------------|
| `SOLID_QUEUE_IN_PUMA` | `true` in development and deployed environments (Solid Queue supervisor runs inside Puma) |
| `WEB_CONCURRENCY` | Puma workers (1 in local Puma, 2 in test Compose, 4 in production Compose) |
| `RAILS_MIN_THREADS` / `RAILS_MAX_THREADS` | Per-worker threads (default 5) |
| `DATABASE_POOL_SIZE` | Active Record pool size (auto-calculated from threads and workers if unset) |
| `JOB_CONCURRENCY` | Solid Queue worker processes per supervisor (`config/queue.yml`, default 1) |
| `RAILS_LOG_LEVEL` | `info` |
| `RAILS_SSL_TERMINATION` | `true` to enable `force_ssl` |
| `REVERSE_PROXY_SSL_TERMINATION` | `true` when SSL terminates at the reverse proxy |
| `PORT` | Puma listen port (default 3000) |
| `PIDFILE` | Puma PID file location |
| `CI` | Set in CI to enable eager loading in the test environment |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Enables OpenTelemetry tracing when set |
| `OTEL_SERVICE_NAME` | Trace service name (default `wrestlingdev`) |

#### Supporting services

Used by MariaDB, exporters, and the telemetry stack (Docker Compose `prod.env` or Kubernetes secrets):

| Variable | Purpose |
|----------|---------|
| `MYSQL_PASSWORD` | MariaDB root password (`prod.env`; also mapped to `WRESTLINGDEV_DB_PWD`) |
| `MYSQLD_EXPORTER_PASSWORD` | MariaDB exporter user password (required by `deploy-prod.sh`) |
| `GRAFANA_HOST` | Production Grafana hostname (Traefik) |
| `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` | Production Grafana login |
| `JAEGER_HOST` | Production Jaeger hostname (Traefik) |
| `JAEGER_BASIC_AUTH_USERS` | Jaeger Traefik basic auth (`htpasswd -nbB`; quote in `prod.env` if the hash contains `$`) |

## Further reading

- [deploy/kubernetes/README.md](deploy/kubernetes/README.md) — Kubernetes deployment
- [loadtests/README.md](loadtests/README.md) — Gatling/Playwright load tests
- `deploy/grafana/` — OpenTelemetry dashboards (local and production)
