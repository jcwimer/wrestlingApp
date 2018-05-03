#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

cd ${project_dir}
rake db:migrate RAILS_ENV=test
CI=true brakeman
rake test
