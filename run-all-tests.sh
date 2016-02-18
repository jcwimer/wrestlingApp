#!/bin/bash -e

docker build -t wrestlingdev-dev -f rails-dev-Dockerfile .

docker run -it -v $(pwd):/rails wrestlingdev-dev bash rails-dev-db.sh
docker run -it -v $(pwd):/rails wrestlingdev-dev rake test
