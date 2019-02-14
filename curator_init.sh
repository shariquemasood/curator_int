#!/bin/bash

elastichost=10.1.204.99
reponame=backup_repo
bucketname=tatasky-portal-logs
timehour=3
timeminute=30
curatordir=/home/ubuntu/.curator_cron

dpkg -s elasticsearch-curator &> /dev/null
if [ $? -eq 0 ]; then
    echo "curator is installed! Skipping Installation"
else
    echo "Installing curator"
    sleep 1
    sudo wget -P /tmp/ https://packages.elastic.co/curator/5/debian/pool/main/e/elasticsearch-curator/elasticsearch-curator_5.6.0_amd64.deb  --no-check-certificate  
    sudo dpkg -i /tmp/elasticsearch-curator_5.6.0_amd64.deb
    sudo rm -rf /tmp/elasticsearch-curator_5.6.0_amd64.deb
    sleep 1
fi

echo "creating a repository to store snapshot"

status_code=$(curl --write-out %{http_code} --silent --output ./repo_error.log -X PUT "$elastichost:9200/_snapshot/$reponame" -H 'Content-Type: application/json' -d'
{
  "type": "s3",
  "settings": {
     "bucket": "'$bucketname'"
   }
}')

if [ $status_code = 200 ]
then	
	echo "The S3 repo $reponame is created"
	sleep 1

else
	echo "Some Error in creating repo exiting... Storing error log in repo_error.log"
	exit 1
fi

echo "making cron job everyday at $timehour:$timeminute UTC"

cron=$(crontab -l > curator_cron
echo "$timeminute $timehour * * *  curator --config $curatordir/config.yml $curatordir/action.yml" > curator_cron
crontab curator_cron
rm curator_cron)

if [ $? = 0 ]
then
	echo "cron installed successfully"
else
	echo "error in cron installaton"
fi
