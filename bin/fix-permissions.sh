#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

USERNAME=$USER
sudo chown -R ${USERNAME}:${USERNAME} ${project_dir}/.
sudo chmod -R 774 ${project_dir}/.
