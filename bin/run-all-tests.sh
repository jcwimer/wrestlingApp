#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

cd ${project_dir}
bundle exec rake db:migrate RAILS_ENV=test
CI=true brakeman
bundle exec bundle-audit check --update
bundle exec rake test
