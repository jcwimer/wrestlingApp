#!/bin/bash -e
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker build -t $1 -f ${project_dir}/deploy/rails-dev-Dockerfile ${project_dir}
docker run -it -p 3000:3000 -v ${project_dir}:/rails $1 /bin/bash
