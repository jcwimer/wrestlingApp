if [ -z "$2" ]
  then
    echo "usage) server-deploy-prod.sh user@server docker-compose-file-name.yml"
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
docker-compose -f ${2} up -d
'"