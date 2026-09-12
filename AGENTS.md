# Development
- I use rbenv locally if that is not available use docker with `docker run -it -v $(pwd):/rails wrestlingdev-dev <rails command>`
  - If the docker image doesn't exist, use the build command: `docker build -t wrestlingdev-dev -f deploy/rails-dev-Dockerfile .`
- Do not add unnecessary comments to the code where you remove things.
- Write as little code as possible. I do not want a bunch of crazy non standard or non supported rails implementations or patterns. This will make rails upgrades in the future easier.
- javascript tests are through vitest. See `vitest.config.js`. Run `npm run test:js` or `npm run test:js:coverage`
- Ruby test coverage uses SimpleCov. Run `COVERAGE=true bin/rails test` (enabled automatically in `bin/run-all-tests.sh`)
- Ruby style is enforced with RuboCop (`rubocop`, `rubocop-rails`, `rubocop-performance`). Run `bundle exec rubocop app/ test/` or `bin/rubocop`.
- Load-tests are in `loadtests/` using gatling and playwright. They simulate traffic analyzed from my largest tournament to date.
- importmap pins in `importmap.rb` and aliases in `vitest.config.js` need to match.
- Unless explicitly told, tests should not be removed. If you need to remove a test because of a rewrite or any other reason you need to ask before you do so.
- Do not write junk tests that don't actually test for things. 
- Adhear to DRY and KISS principles
- CSS layouts should be responsive for mobile browsers
- When the db schema changes, always be cognizant of the tournament backup and import service. Continue to make sure these work.

# Accepted non standard and non supported rails or gem patterns and implementations
Keep this section updated whenever there's an accepted non standard or non supported rails or gem pattern. Be sure to check the versions of rails or gems when considering things that are non standard or non supported.

- Prepared statements are disabled locally and in test. This is specifically to let Prosopite fingerprint emitted SQL, which changes normal Active Record SQLite query behavior. This is required for prosopite to work with sqlite.
- Development Puma starts Solid Queue internally by default. Rather than requiring a separate bin/jobs worker process, the Puma process loads the Solid Queue plugin unless explicitly disabled. This is how I want to run the app for the time being until I need to scale workers separately.
- SQLite connection configuration: WAL, busy timeout, and related PRAGMAs are applied through `database.yml` to all SQLite databases in development (primary, queue, cache, cable).
- `secret_key_base` is set in `config/environments/*` (production uses `WRESTLINGDEV_SECRET_KEY_BASE`), not Rails credentials.
- The MariaDB Solid Queue connection uses `tx_isolation: READ-COMMITTED`. This avoids Solid Queue enqueue-vs-claim deadlocks caused by InnoDB gap locks under `REPEATABLE READ`; use MariaDB's `tx_isolation` name, not MySQL's `transaction_isolation`. See https://github.com/rails/solid_queue/issues/531#issuecomment-5464388820.
- Application-owned jobs enqueue through `perform_later_with_enqueue_retry`, which makes up to three jittered attempts for a `SolidQueue::Job::EnqueueError` caused by `ActiveRecord::Deadlocked`. This is an enqueue safety net, not job-execution retry behavior.

# Telemetry
- In production and test environments, OTEL is used for application traces.
- Grafana dashboards are maintained in `deploy/grafana`
- Prometheus stack is used for metrics

# CI/CD
- Jenkins CI/CD lives in `ci_cd/Jenkinsfile`.
  - The Jenkins job is named `wrestlingdev`.
  - The test stage is named `development-tests`.
  - The test deploy stage is named `deploy-test`.
  - The production deploy stage is named `deploy-production` and runs on SCM-triggered or manually triggered `master` builds.
  - Timer-triggered `master` builds skip production deploys.
  - Production deploy maps the Jenkins secret text credential `DOCKERHUB_PASSWORD` to the `DOCKERHUB_PASSWORD` environment variable.
  - Test and production deploy SSH use the Jenkins credential ID from the old freestyle job.
- My SDLC is as follows:
  - I develop on the development branch
  - When things are pushed to the branch, I run all tests and run `deploy/deploy-test.sh` on my dev server
  - To release to production, I rebase development with master to make sure everything is good to go. Then I merge the development branch with master and push to master.
  - Currently, I'm using docker compose for production and kubernetes for my DR environment. You can see this in `ci_cd/Jenkinsfile` on the deploy-production stage.

# Deployment
- The only rails envs I use are TEST DEVELOPMENT and PRODUCTION.
  - test is obviously to run tests locally and uses sqlite
  - development is for running the application locally and uses sqlite
  - production is for all of my SDLC environments and uses mariadb
    - this is to make sure my dev environment and production environments are the same
    - I utilize docker images for my test and production environments you can see these in `deploy/`
    - I often test this setup locally too with `deploy/deploy-test.sh`
- docker compose AND kubernetes deploys need to be kept in sync with each other for deployment flexibility
- when adding environment variables be sure to update the readme, update `deploy/prod.env.example`, update `deploy/kubernetes/secrets/secrets.yaml` and update the README. Be sure to also keep both compose files up to date and the kubernetes manifests.

# Other
- Please keep README.md and AGENTS.md up to date when making changes.
- The README should be relevant information for a developer and should not get bloated. What versions of stuff are running, how to get up and running locally as a dev, how to deploy and what variables are needed or optional.
- Make sure other README files in subfolders of this project are kept up to date as well if any changes are made.
- If something is added to .gitignore consider always consider if it should be added to .dockerignore as well.
