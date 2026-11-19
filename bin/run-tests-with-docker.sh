#!/bin/bash
set -e

project_dir="$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))"

docker build -f "${project_dir}/deploy/rails-dev-Dockerfile" -t wrestlingdevtests "${project_dir}"
container_id=$(docker create --user 0:0 --workdir /rails \
  -e HOME=/tmp -e BUNDLE_WITHOUT=production \
  wrestlingdevtests bash /rails/bin/run-all-tests.sh)
trap 'docker rm --force --volumes "$container_id" >/dev/null || echo "Could not remove test container $container_id" >&2' EXIT

docker cp "${project_dir}/." "${container_id}:/rails"
docker start --attach "$container_id"
