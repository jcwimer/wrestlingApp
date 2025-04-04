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
sleep 30s
# echo Make sure your local mysql database has a wrestlingtourney db
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rake db:create
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rake db:migrate

echo Resetting the db with seed data
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:reset"

# echo Simulating tournament 204
# docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins
