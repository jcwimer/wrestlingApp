#!/bin/bash -e

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker build -t $1 -f rails-prod-Dockerfile .
docker run -d --restart=always --env-file $WRESTLINGDEV_ENV_FILE $1 rake jobs:work