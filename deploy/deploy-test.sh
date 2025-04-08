#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

#docker build -t wrestlingdev:test -f ${project_dir}/deploy/rails-prod-Dockerfile ${project_dir}
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml kill
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml build
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up -d
sleep 30s
# echo Make sure your local mysql database has a wrestlingtourney db
# docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:drop"
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rake db:create
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rake db:migrate

echo Resetting the db with seed data
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:reset"

# echo Simulating tournament 204
# docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins
