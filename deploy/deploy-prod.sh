gpg prod.env.gpg
cd ..
bash rails-prod.sh wrestlingdev
cd deploy
sudo docker-compose -f docker-compose-prod.yml up -d
echo Make sure your local mysql database has a db for wrestlingdev
echo "mysqldump -u guy -ppassword -h host database_name > database.sql"
echo "mysql -u guy -ppassword -h host database_name < database.sql"
