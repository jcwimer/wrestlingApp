#!/bin/bash -e
docker pull ruby:2.2.3

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker build -t $1 -f rails-prod-Dockerfile .

#Kill and remove containers gracefully without error if none are running
docker ps | grep "Exit" | awk '{print $1}' | while read -r id ; do
  docker kill $id
done

docker run -h $HOSTNAME -d --restart=always --env-file $WRESTLINGDEV_ENV_FILE -v /etc/localtime:/etc/localtime $1 bundle exec rake jobs:work RAILS_ENV=production