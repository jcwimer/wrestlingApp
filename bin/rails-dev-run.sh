#!/bin/bash -e
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

USER_ID=$(id -u ${USER})
# Get group id for username - fixed to correctly retrieve numeric GID
GROUP_ID=$(id -g ${USER})

if [ $# != 1 ]; then
  echo "Please enter docker image name for the rails development environment"
  exit 1
fi

docker build -t $1 -f ${project_dir}/deploy/rails-dev-Dockerfile \
  --build-arg USER_ID=$USER_ID \
  --build-arg GROUP_ID=$GROUP_ID \
  ${project_dir}

docker run --rm -it -p 3000:3000 \
  -v ${project_dir}:/rails \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  $1 /bin/bash