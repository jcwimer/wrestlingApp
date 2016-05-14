cd ..
docker build -t wrestlingdev -f rails-prod-Dockerfile .
cd deploy
docker-compose -f docker-compose-test.yml kill
docker-compose -f docker-compose-test.yml up -d
echo Make sure your local mysql database has a wrestlingtourney db
