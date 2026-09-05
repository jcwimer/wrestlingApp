# Deployment

- The only rails envs I use are TEST DEVELOPMENT and PRODUCTION.
  - test is obviously to run tests locally and uses sqlite
  - development is for running the application locally and uses sqlite
  - production is for all of my SDLC environments and uses mariadb
    - this is to make sure my dev environment and production environments are the same
    - I utilize docker images for my dev and production environments you can see these in `deploy/`
    - I often test this setup locally too with `deploy/deploy-test.sh`
- My SDLC is as follows:
  - I develop on the development branch
  - When things are pushed to the branch, I run all tests and run `deploy/deploy-test.sh` on my dev server
  - To release to production, I rebase development with master to make sure everything is good to go. Then I merge the development branch with master and push to master.
  - Currently, I'm using docker compose for production and kubernetes for my DR environment. You can see this in `ci_cd/Jenkinsfile` on the deploy-production stage.

# Development
- `BOOTSTRAP_TO_TAILWIND.md` documents the planned Bootstrap-to-Tailwind migration and visual parity checks; it does not describe an already completed migration.
- Rails is pinned to 8.1.3.1 in `Gemfile` and `Gemfile.lock`.
- I use rbenv locally if that is not available use docker with `docker run -it -v $(pwd):/rails wrestlingdev-dev <rails command>`
  - If the docker image doesn't exist, use the build command: `docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .`
  - If the Gemfile changes, you need to rebuild the docker image: `docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .`
- Do not add unnecessary comments to the code where you remove things.
- Write as little code as possible. I do not want crazy non standard rails implementations.
- This project is using propshaft and importmap.
- Stimulus is used for javascript.
- javascript tests are through vitest. See `vitest.config.js`. Run `npm run test:js`
- Vitest 5 requires Node.js 22.12+, 24, or 26+; both Rails Docker images use Node.js 24 from the official Node image.
- Load-test Playwright is pinned to 1.63.0, matching `loadtests/Dockerfile`. Keep its package lockfile current; the image installs dependencies with `npm ci`.
- importmap pins in `importmap.rb` and aliases in `vitest.config.js` need to match.
- Tournament index ordering uses `tournaments.date_sort_key` (`Date#jd`) so closest-date pagination remains database-neutral between SQLite and MariaDB.
- Prosopite scans controller actions in development and test. Development detections are logged, detections in controller tests raise errors, and inline jobs are excluded from the parent request scan.
- SQLite prepared statements are disabled in development and test so Prosopite can fingerprint the SQL emitted by Rails 8.1. Production MariaDB configuration is unchanged.
- Collection fragment caches use Rails collection rendering so Solid Cache reads and writes their entries in batches.
- Tournament show and bout-board requests use action-specific preloads. Bracket data is loaded inside the cached partial; all-brackets loads its associations in one batch on the first miss. School and weight roster data is loaded inside spectator fragment blocks, with uncached director/key views retaining their controls. School roster and stats use separate preload graphs.
- Popular read-only pages use deterministic domain keys and targeted `Rails.cache.delete_multi` calls instead of `updated_at` fan-out. Brackets are cached per weight, team scores per tournament, school stats per school, and wrestler roster/profile fragments independently. Cache invalidation is coordinated by `TournamentCacheInvalidator`; bulk generation and advancement must delete affected keys after persistence.
- Completed matches enqueue one serialized advancement job. That job completes both wrestler branches and any cascading advancement synchronously, updates bout-board queues, calculates tournament scores once, and only then invalidates affected caches.
- Live stat websocket writes use callback-free column updates and must not invalidate fragment cache versions. Match finalization is guarded by `matches.finalized_at`.
- Queue assignment, movement, advancement, refill, and clearing go through `MatQueueOperation`, which locks mats by ID and publishes topology changes after commit. Scoreboard selection uses compact, idempotent cache-backed broadcasts and never renders the legacy mat partial.
- Solid Cable uses its default automatic trimming behavior. Broadcast telemetry records per-stream message counts and payload sizes.
- Dockerized load tests live in `loadtests/`. Gatling prepares seeded tournament 204, drives spectator traffic, verifies Action Cable subscriptions, follows mat-to-match subscription changes, and measures websocket sync round trips. Five staggered Playwright Chromium contexts execute the real state-page JavaScript for mat operators, and a browser observer records operator-action-to-live-score delivery and DOM latency. Preparation creates five named mats and regenerates matches before load begins. Target URL, ramp, websocket thresholds, and load parameters are environment-configurable; see `loadtests/README.md`.

# Telemetry
- Docker compose tracing uses OpenTelemetry, not InfluxDB.
  - Rails tracing is enabled by `config/initializers/opentelemetry.rb` only when `OTEL_EXPORTER_OTLP_ENDPOINT` is set.
  - `deploy/docker-compose-test.yml` runs `otel-collector`, `jaeger`, `prometheus`, and `grafana`.
  - `deploy/docker-compose-prod.yml` also runs `otel-collector`, `jaeger`, `prometheus`, and `grafana`; production Grafana uses its built-in login and production Jaeger is protected by Traefik basic auth.
  - Kubernetes tracing is defined in `deploy/kubernetes/manifests/telemetry.yaml`; Rails pods in `deploy/kubernetes/manifests/wrestlingdev.yaml` export OTLP to `http://otel-collector:4318`.
  - Collector config lives in `deploy/otel-collector-config.yml`; Prometheus config lives in `deploy/prometheus.yml`.
  - Grafana datasource/dashboard provisioning lives under `deploy/grafana/provisioning`; dashboards live in `deploy/grafana/dashboards`.
  - Kubernetes Grafana downloads dashboards from `deploy/grafana/dashboards` with an init container; do not embed dashboard JSON in the telemetry ConfigMap.
  - Local URLs: Grafana `http://localhost:3000`, Jaeger `http://localhost:16686`, Prometheus `http://localhost:9090`.
  - Prometheus span metrics are `traces_span_metrics_calls_total` and `traces_span_metrics_duration_milliseconds_*`.
  - Compose and Kubernetes persist Jaeger Badger storage with seven-day retention (`--badger.span-store-ttl=168h`); Prometheus also retains seven days (`--storage.tsdb.retention.time=7d`). Compose uses a named volume and ownership initializer; Kubernetes uses a 15Gi PVC with fsGroup permissions and a Recreate deployment. No host filesystem setup is required.
  - Kubernetes node-exporter uses a DaemonSet and headless Service for per-node Prometheus discovery. Both alternative MariaDB manifests use the exporter sidecar and existing database Secret credentials, scraped through the internal mariadb-exporter Service. Grafana downloads the node and MariaDB dashboards with the Rails dashboards. Deploy only one MariaDB variant.
  - The collector filters successful Solid Queue polling queries/transactions under 100 ms while retaining slow polling, errors, and job execution spans.
  - Both Compose stacks include node-exporter and mariadb-exporter on the private internal `exporters` network with no published ports. Prometheus scrapes jobs `node` and `mariadb`; dashboards are `node-exporter.json` and `mariadb-exporter.json`. Host network counters are not provided by the private-network node exporter.
  - `mariadb-exporter-init` provisions the read/monitor database user on existing or new volumes. Production requires `MYSQLD_EXPORTER_PASSWORD` in `prod.env`; the local default is `exporter-local`. Database health checks execute an authenticated `SELECT 1` using `MYSQL_ROOT_PASSWORD`.
  - Puma worker and thread counts come from `WEB_CONCURRENCY`, `RAILS_MIN_THREADS`, and `RAILS_MAX_THREADS`. Local Compose defaults to 2 workers with 5 threads; production Compose defaults to 4 workers with 5 threads.

# CI/CD
- Jenkins CI/CD lives in `ci_cd/Jenkinsfile`.
  - The Jenkins job is named `wrestlingdev`.
  - The test stage is named `development-tests`.
  - The test deploy stage is named `deploy-test`.
  - The production deploy stage is named `deploy-production` and runs on SCM-triggered or manually triggered `master` builds.
  - Timer-triggered `master` builds skip production deploys.
  - Production deploy maps the Jenkins secret text credential `DOCKERHUB_PASSWORD` to the `DOCKERHUB_PASSWORD` environment variable.
  - Test and production deploy SSH use the Jenkins credential ID from the old freestyle job.

# Other
Cypress tests have been mostly deprecated in favor of vitest but they still exist:
- Cypress tests are created for js tests. They can be found in cypress-tests/cypress
- Cypress tests can be run with docker: bash cypress-tests/run-cypress-tests.sh

Please keep README.md and AGENTS.md up to date when making changes.

# Model Choices
Default to these model choices:
- Use Luna Medium for repository exploration, searching files, reading logs, running commands, gathering test output, and other simple support work.
- Use Terra Medium for normal coding tasks, bug fixes, tests, refactors, configuration changes, and straightforward implementation.
- Use Terra High when normal coding requires more careful reasoning or spans several interacting components.
- Use Sol Medium for difficult implementation, difficult debugging, complicated architecture, or when Terra has made a serious unsuccessful attempt.
- Use Sol High only for exceptionally difficult reasoning or when Sol Medium is struggling.
- Use Astra Low only for very difficult problems, subtle architectural decisions, or when Sol has made a serious attempt and still cannot solve the problem.
- Do not use Astra for routine coding, repository exploration, shell commands, tests, or straightforward implementation.
- Do not escalate just because a task is large. Large but straightforward work should stay on Luna or Terra.
- Prefer escalating because of reasoning difficulty or demonstrated failure.
- Before escalating, make sure the problem is not simply missing information or insufficient repository exploration.
- Delegate mechanical or investigative work to cheaper subagents whenever practical.
- Stronger models should focus only on the portions of the task that require stronger reasoning.
- After a stronger model solves the difficult part, delegate routine implementation, testing, and verification back to Terra or Luna when appropriate.
