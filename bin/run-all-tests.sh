#!/bin/bash
set -o pipefail
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

cd ${project_dir}
npm install
npm run test:js:coverage
bundle exec rake db:migrate RAILS_ENV=test
CI=true brakeman
bundle audit
COVERAGE=true rails test -v
