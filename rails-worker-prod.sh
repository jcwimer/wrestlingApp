#!/bin/bash -e
docker pull ruby:2.2.3

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker kill $1
docker rm $1
docker build -t $1 -f rails-prod-Dockerfile .

docker run -h $HOSTNAME --name $1 -d --restart=always --env-file $WRESTLINGDEV_ENV_FILE -v /etc/localtime:/etc/localtime $1 bundle exec rake jobs:work RAILS_ENV=production