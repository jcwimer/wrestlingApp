#!/bin/bash
project_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/.."
cd ${project_dir}

cd deploy
docker-compose -f docker-compose-test.yml down --volumes

bash deploy-test.sh

cd ../cypress-tests

# include ruby, mysql, memcached, and cypress in dockerfile to emulate prod?
# then cypress points to localhost within the docker

docker build -t wrestlingdev-cypress .

docker run -i --rm --network=host \
-v ${project_dir}/cypress-tests/cypress/screenshots:/cypress/screenshots \
-v ${project_dir}/cypress-tests/cypress/videos:/cypress/videos \
wrestlingdev-cypress
test_results=$?

cd ../deploy
docker-compose -f docker-compose-test.yml down --volumes

exit $?
