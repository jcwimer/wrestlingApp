gpg prod.env.gpg
cd ..
bash rails-prod.sh wrestlingdev
cd deploy
docker-compose -f docker-compose-prod-full-stack.yml up -d
echo Make sure your local mysql database has a db for wrestlingdev called wrestlingtourney
echo "mysqldump -u guy -ppassword -h host database_name > database.sql"
echo "mysql -u guy -ppassword -h host database_name < database.sql"
