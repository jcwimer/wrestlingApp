#!/bin/bash
# This assumes prod.env exists in the folder where this is running

echo Checking for external docker networks
if ! docker network ls --format '{{.Name}}' | grep -q '^shared_monitoring$'; then
  docker network create shared_monitoring
fi

if ! docker network ls --format '{{.Name}}' | grep -q '^shared_traefik$'; then
  docker network create shared_traefik
fi

echo Downloading files needed from github
mkdir -p nginx
mkdir -p mariadb
mkdir -p grafana/dashboards
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/provisioning/datasources

githubraw_url=https://raw.githubusercontent.com/jcwimer/wrestlingApp/refs/heads/master
wget -O compose ${githubraw_url}/bin/docker-compose
chmod +x compose
COMPOSE=./compose
wget -O docker-compose.yml ${githubraw_url}/deploy/docker-compose-prod.yml
wget -O nginx/nginx.conf ${githubraw_url}/deploy/nginx/nginx.conf
wget -O nginx/nginx-entrypoint.sh ${githubraw_url}/deploy/nginx/nginx-entrypoint.sh
wget -O mariadb/70-mysettings.cnf ${githubraw_url}/deploy/mariadb/70-mysettings-master.cnf
wget -O otel-collector-config.yml ${githubraw_url}/deploy/otel-collector-config.yml
wget -O prometheus.yml ${githubraw_url}/deploy/prometheus.yml
wget -O mariadb/init-exporter.sh ${githubraw_url}/deploy/mariadb/init-exporter.sh
wget -O grafana/provisioning/dashboards/dashboards.yml ${githubraw_url}/deploy/grafana/provisioning/dashboards/dashboards.yml
wget -O grafana/provisioning/datasources/datasources.yml ${githubraw_url}/deploy/grafana/provisioning/datasources/datasources.yml
wget -O grafana/dashboards/rails-otel-activejob.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-activejob.json
wget -O grafana/dashboards/rails-otel-overview.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-overview.json
wget -O grafana/dashboards/rails-otel-performance-per-action.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-performance-per-action.json
wget -O grafana/dashboards/rails-otel-performance-per-request.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-performance-per-request.json
wget -O grafana/dashboards/rails-otel-performance.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-performance.json
wget -O grafana/dashboards/rails-otel-requests.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-requests.json
wget -O grafana/dashboards/rails-otel-slowlog-by-action.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-slowlog-by-action.json
wget -O grafana/dashboards/rails-otel-slowlog-by-request.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-slowlog-by-request.json
wget -O grafana/dashboards/rails-otel-slowlog-by-sql.json ${githubraw_url}/deploy/grafana/dashboards/rails-otel-slowlog-by-sql.json
wget -O grafana/dashboards/node-exporter.json ${githubraw_url}/deploy/grafana/dashboards/node-exporter.json
wget -O grafana/dashboards/mariadb-exporter.json ${githubraw_url}/deploy/grafana/dashboards/mariadb-exporter.json

set -a
. prod.env
set +a
: "${MYSQLD_EXPORTER_PASSWORD:?Set MYSQLD_EXPORTER_PASSWORD in prod.env}"
${COMPOSE} pull
${COMPOSE} down
echo "Waiting for db to be up..."
${COMPOSE} up -d wrestlingdev_db
sleep 30s
echo "Running database migrations..."
${COMPOSE} run --rm wrestlingdev bin/rails db:migrate
${COMPOSE} run --rm wrestlingdev bin/rails db:migrate:cache
${COMPOSE} run --rm wrestlingdev bin/rails db:migrate:queue
${COMPOSE} run --rm wrestlingdev bin/rails db:migrate:cable
echo "Bringing up the new containers..."
${COMPOSE} up -d
