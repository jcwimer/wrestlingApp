#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$(expr $RAM_KB / 1024)
RAM_GB=$(expr $RAM_MB / 1024)
RAM_WITHOUT_OTHER_SERVICES=$(expr $RAM_MB - 1024) # other services use ~1024MB of RAM
PASSENGER_POOL_FACTOR=$(expr $RAM_WITHOUT_OTHER_SERVICES / 256) # 1 pool worker uses ~256MB of RAM
export PASSENGER_POOL_SIZE=$(expr $PASSENGER_POOL_FACTOR '*' 1)

#docker build -t wrestlingdev:test -f ${project_dir}/deploy/rails-prod-Dockerfile ${project_dir}
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml kill
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml build
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up -d
# echo Make sure your local mysql database has a wrestlingtourney db
docker exec -it deploy_app_1 rake db:create
docker exec -it deploy_app_1 rake db:migrate

echo Resetting the db with seed data
docker exec -it deploy_app_1 bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:reset"