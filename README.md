# README
This application is being created to run a wrestling tournament.

### Current master status
[![Build Status](https://travis-ci.org/jcwimer/wrestlingApp.svg?branch=master)](https://travis-ci.org/jcwimer/wrestlingApp)

### Current development status
[![Build Status](https://travis-ci.org/jcwimer/wrestlingApp.svg?branch=development)](https://travis-ci.org/jcwimer/wrestlingApp)

# Info
**License:** MIT License

**Public Production Url:** [https://wrestlingdev.com](http://wrestlingdev.com)

**App Info**
* Ruby 2.6.5
* Rails 6.0.1
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
* `rake finish_seed_tournament` will complete all matches from the seed data. This command takes about 5 minutes to execute

To deploy a a full local version of the app `bash deploy/deploy-test.sh` (this requires docker-compose to be installed). This deploys a full version of the app. App, delayed job, memcached, and mariadb. Now, you can open [http://localhost](http://localhost). Delayed jobs are turned off in dev and everything that is a delayed job in prod just runs in browser.

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
