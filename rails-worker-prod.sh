#!/bin/bash -e

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker kill $1
docker rm $1
docker build -t $1 -f rails-prod-Dockerfile .

docker run --name $1 -d --restart=always --env-file $WRESTLINGDEV_ENV_FILE $1 bundle exec rake jobs:work RAILS_ENV=production