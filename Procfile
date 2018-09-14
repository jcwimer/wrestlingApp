worker: bundle exec bin/delayed_job -n 1 run
#worker: bundle exec rake jobs:work
web: bundle exec puma -w 3 -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
#web: bundle exec passenger start -p $PORT --max-pool-size 3
