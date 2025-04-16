#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

cd ${project_dir}
rake db:setup
rake db:migrate
rake db:migrate:cache
rake db:migrate:queue
rake db:migrate:cable
