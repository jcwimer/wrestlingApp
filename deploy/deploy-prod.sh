#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

gpg --output ${project_dir}/deploy/prod.env --decrypt ${project_dir}/deploy/prod.env.gpg
docker build -t wrestlingdev-prod -f ${project_dir}/deploy/rails-prod-Dockerfile ${project_dir}
docker-compose -f ${project_dir}/deploy/docker-compose-prod-full-stack.yml up -d
echo Make sure your local mysql database has a db for wrestlingdev called wrestlingtourney
echo "mysqldump -u guy -ppassword -h host database_name > database.sql"
echo "mysql -u guy -ppassword -h host database_name < database.sql"

rm ${project_dir}/deploy/prod.env
