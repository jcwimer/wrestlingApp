#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

#docker build -t wrestlingdev:test -f ${project_dir}/deploy/rails-prod-Dockerfile ${project_dir}
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml kill
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml build
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up -d
echo Make sure your local mysql database has a wrestlingtourney db
