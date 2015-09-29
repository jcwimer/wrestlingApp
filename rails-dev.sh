#!/bin/bash -e

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

APPPATH="$(pwd)"

docker build -t $1 -f rails-dev-Dockerfile .
docker run -it -p 3000:3000 -v ${APPPATH}:/rails $1 /bin/bash