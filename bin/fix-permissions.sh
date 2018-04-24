#!/bin/bash
project_dir="$(git rev-parse --show-toplevel)"

USERNAME=$USER
sudo chown -R ${USERNAME}:${USERNAME} ${project_dir}/.
sudo chmod -R 774 ${project_dir}/.
