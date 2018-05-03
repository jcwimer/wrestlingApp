#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

docker build -f ${project_dir}/deploy/rails-prod-Dockerfile -t wrestlingdevtests ${project_dir}/.
docker run -it wrestlingdevtests bash /rails/bin/run-all-tests.sh
