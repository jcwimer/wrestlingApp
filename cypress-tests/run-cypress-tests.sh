#!/bin/bash

#!/bin/bash
project_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/.."

cd ${project_dir}/cypress-tests

# include ruby, mysql, memcached, and cypress in dockerfile to emulate prod?
# then cypress points to localhost within the docker

docker build -t wrestlingdev-cypress .

docker run -it --rm wrestlingdev-cypress