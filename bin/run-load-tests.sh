#!/bin/bash
set -o pipefail
project_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/.."
COMPOSE="${project_dir}/bin/docker-compose"

cd ${project_dir}
bash deploy/deploy-test.sh

cd loadtests
${COMPOSE} build
BASE_URL=http://host.docker.internal TEST_DURATION_SECONDS=600 ${COMPOSE} run --rm gatling

cd ..
${COMPOSE} -f deploy/docker-compose-test.yml down
