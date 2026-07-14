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
- I have two ways to run rails commands in the repo. Either use rvm with `rvm use 4.0.5; rvm gemset use wrestlingdev;` or use docker with `docker run -it -v $(pwd):/rails wrestlingdev-dev <rails command>`
  - If the docker image doesn't exist, use the build command: `docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .`
  - If the Gemfile changes, you need to rebuild the docker image: `docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .`
- Do not add unnecessary comments to the code where you remove things.
- Write as little code as possible. I do not want crazy non standard rails implementations.
- This project is using propshaft and importmap.
- Stimulus is used for javascript.
- javascript tests are through vitest. See `vitest.config.js`. Run `npm run test:js`
- importmap pins in `importmap.rb` and aliases in `vitest.config.js` need to match.
- Tournament index ordering uses `tournaments.date_sort_key` (`Date#jd`) so closest-date pagination remains database-neutral between SQLite and MariaDB.

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
  - Jaeger all-in-one uses in-memory storage and is capped with `--memory.max-traces=50000` in compose and Kubernetes manifests.

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
