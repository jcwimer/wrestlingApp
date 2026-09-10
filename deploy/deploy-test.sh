#!/bin/bash
project_dir="$(dirname $( dirname $(readlink -f ${BASH_SOURCE[0]})))"
COMPOSE="${project_dir}/bin/docker-compose"

# Stop existing services
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml kill

# Build images
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml build

# Start the database service first and wait for it
echo "Starting database service..."
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml up -d db
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml up -d otel-collector
echo "Waiting for database to be ready..."
sleep 15 # Adjust sleep time if needed

# <<< Run migrations BEFORE starting the main services >>>
echo "Making sure databases exist..."
# DISABLE_DATABASE_ENVIRONMENT_CHECK=1 is needed because this is "destructive" action on production
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:create
echo Resetting the db with seed data
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:reset"
echo "Running database migrations..."
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:cache
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:queue
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml run --rm app bin/rails db:migrate:cable

echo "Stopping all services..."
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml down

echo "Starting application services..."
${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml up --force-recreate --remove-orphans -d

# echo Simulating tournament 204
# ${COMPOSE} -f ${project_dir}/deploy/docker-compose-test.yml exec -T app rails tournament:assign_random_wins
