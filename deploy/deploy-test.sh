cd ..
bash rails-prod.sh wrestlingdev
cd deploy
docker-compose -f docker-compose-test.yml up -d
echo Make sure your local mysql database has a wrestlingtourney db