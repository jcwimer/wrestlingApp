#!/bin/bash -e
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"
if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker build -t $1 -f ${project_dir}/deploy/rails-prod-Dockerfile ${project_dir}/.

#Kill and remove containers gracefully without error if none are running
docker ps | grep "Exit" | awk '{print $1}' | while read -r id ; do
  docker kill $id
done

