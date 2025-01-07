# README
This application is being created to run a wrestling tournament.

### Current master status
[![Build Status](https://circleci.com/gh/jcwimer/wrestlingApp/tree/master.svg)](https://circleci.com/gh/jcwimer/wrestlingApp/tree/master)

### Current development status
[![Build Status](https://circleci.com/gh/jcwimer/wrestlingApp/tree/development.svg)](https://circleci.com/gh/jcwimer/wrestlingApp/tree/development)

# Info
**License:** MIT License

**Public Production Url:** [https://wrestlingdev.com](http://wrestlingdev.com)

**App Info**
* Ruby 3.1.4
* Rails 7.1.3.2
* DB mysql or mariadb
* Memcached
* Delayed Jobs

# Development
All dependencies are wrapped in docker. Tests can be run with `bash bin/run-tests-with-docker.sh`. That is the same command used in CI.

If you want to run a full rails environment shell in docker run: `bash bin/rails-dev-run.sh wrestlingapp-dev`

From here, you can run the normal rails commands.
* `rake db:seed` Development login email from seed data: `test@test.com` password: `password`
* `rake test`
* `rails generate blah blah blah`
* ` rails s -b 0.0.0.0` port 3000 is exposed. You can open [http://localhost:3000](http://localhost:3000) after running that command
* etc.
* `rake finish_seed_tournaments` will complete all matches from the seed data. This command takes about 5 minutes to execute
* `docker-compose -f deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins` will complete all matches for tournament 204 from seed data. This task takes a while since it waits for the worker to complete tasks. In my testing, it takes about 3.5 hours to complete.

To deploy a a full local version of the app `bash deploy/deploy-test.sh` (this requires docker-compose to be installed). This deploys a full version of the app. App, delayed job, memcached, and mariadb. Now, you can open [http://localhost](http://localhost). Delayed jobs are turned off in dev and everything that is a delayed job in prod just runs in browser.

To run a single test file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb`

To run a single test inside a file:
1. Get a shell with ruby and rails: `bash bin/rails-dev-run.sh wrestlingdev-development`
2. `rake test TEST=test/models/match_test.rb TESTOPTS="--name='/test_Match_should_not_be_valid_if_an_incorrect_win_type_is_given/'"`

## Update gems

1. `bash bin/rails-dev-run.sh wrestlingdev-dev` to open a contianer with a rails shell available
2. `bundle config --delete without` to remove the bundle config that ignores production gems
3. `bundle update`

Note: If updating rails, do not change the version in `Gemfile` until after you run `bash bin/run-rails-dev.sh wrestlingdev-dev`. Creating the container will fail due to a mismatch in Gemfile and Gemfile.lock.
Then run `rails app:update` to update rails.

# Deployment

The production version of this is currently deployed in Kubernetes. See [Deploying with Kubernetes](deploy/kubernetes/README.md)

**Required environment variables for deployment**
* `WRESTLINGDEV_DB_NAME=databasename`
* `WRESTLINGDEV_DB_USER=databaseusername`
* `WRESTLINGDEV_DB_PWD=databasepassword`
* `WRESTLINGDEV_DB_HOST=database.homename`
* `WRESTLINGDEV_DB_PORT=databaseport`
* `WRESTLINGDEV_DEVISE_SECRET_KEY=devise_key` can be generated with `rake secret`
* `WRESTLINGDEV_SECRET_KEY_BASE=secret_key` can be generated with `rake secret`
* `WRESTLINGDEV_EMAIL_PWD=emailpwd` Email has to be a gmail account for now.
* `WRESTLINGDEV_EMAIL=email address`

**Optional environment variables**
* `MEMCACHIER_PASSWORD=memcachier_password` needed for caching password
* `MEMCACHIER_SERVERS=memcachier_hostname:memcachier_port` needed for caching
* `MEMCACHIER_USERNAME=memcachier_username` needed for caching
* `WRESTLINGDEV_NEW_RELIC_LICENSE_KEY=new_relic_license_key` this is only needed to use new relic
* `WRESTLINGDEV_INFLUXDB_DATABASE=influx_db_name` to send metrics to influxdb this is required
* `WRESTLINGDEV_INFLUXDB_HOST=influx_db_ip_or_hostname` to send metrics to influxdb this is required
* `WRESTLINGDEV_INFLUXDB_PORT=influx_db_port` to send metrics to influxdb this is required
* `WRESTLINGDEV_INFLUXDB_USERNAME=influx_db_username` to send metrics to influxdb this is optional
* `WRESTLINGDEV_INFLUXDB_PASSWORD=influx_db_password` to send metrics to influxdb this is optional