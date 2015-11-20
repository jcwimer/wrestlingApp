if [ -z "$1" ]
  then
    echo "usage) server-deploy-prod.sh user@server"
    exit 1
fi

echo "Copying your ssh key to ${1}"
ssh-copy-id $1
clear
ssh -t $1 bash -c "'
cd wrestlingApp
mv deploy/prod.env ../
git pull origin master
mv ../prod.env deploy/

#Kill all containers
docker kill $(docker ps -q)

bash rails-prod.sh wrestlingdev
cd deploy
docker-compose -f docker-compose-prod.yml up -d
'"