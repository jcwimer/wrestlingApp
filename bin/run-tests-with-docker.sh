#!/bin/bash -e
project_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/.."

docker build -f ${project_dir}/deploy/rails-prod-Dockerfile -t wrestlingdevtests ${project_dir}/.
docker run --rm -it wrestlingdevtests bash /rails/bin/run-all-tests.sh
bash ${project_dir}/cypress-tests/run-cypress-tests.sh
