#!/bin/bash
project_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/.."
cd ${project_dir}

cd deploy
bash deploy-test.sh

cd ../cypress-tests

# include ruby, mysql, memcached, and cypress in dockerfile to emulate prod?
# then cypress points to localhost within the docker

docker build -t wrestlingdev-cypress .

docker run -i --rm --network=host wrestlingdev-cypress
test_results=$?

cd ../deploy
docker-compose -f docker-compose-test.yml down
docker volume rm deploy_influxdb deploy_mysql

exit $?
