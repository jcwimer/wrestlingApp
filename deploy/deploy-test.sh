#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"

# Stop existing services
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml kill

# Build images
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml build

# Start the database service first and wait for it
echo "Starting database service..."
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up -d db
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up -d influxdb
echo "Waiting for database to be ready..."
sleep 15 # Adjust sleep time if needed

# <<< Run migrations BEFORE starting the main services >>>
echo "Making sure databases exist..."
# DISABLE_DATABASE_ENVIRONMENT_CHECK=1 is needed because this is "destructive" action on production
# docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:drop"
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:create
echo "Running database migrations..."
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:cache
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:queue
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:cable

echo "Stopping all services..."
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml down

echo "Starting application services..."
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml up --force-recreate --remove-orphans -d

# DISABLE_DATABASE_ENVIRONMENT_CHECK=1 is needed because this is "destructive" action on production
echo Resetting the db with seed data
docker-compose -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:reset"

# echo Simulating tournament 204
# docker-compose -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins
