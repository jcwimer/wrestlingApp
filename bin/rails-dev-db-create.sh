#!/bin/bash
project_dir="$(git rev-parse --show-toplevel)"

cd ${project_dir}
rake db:setup
rake db:migrate RAILS_ENV=test
