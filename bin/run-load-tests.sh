#!/bin/bash
set -o pipefail
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

cd ${project_dir}
bash bin/deploy-test.sh

cd loadtests
docker-compose build
BASE_URL=http://host.docker.internal TEST_DURATION_SECONDS=600 docker-compose run --rm gatling

cd ..
docker-compose -f deploy/docker-compose-test.yml down
