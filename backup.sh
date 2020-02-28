#!/bin/bash
CID=$(sudo docker container ls | grep redash_postgres | awk '{print $1}')
echo CID=$CID

date=`date +"%Y%m%d_%H%M%S"`
backup_file="redash-backup.${date}.gz"
sudo docker container exec ${CID} /bin/bash -c "pg_dump -U postgres postgres | gzip > /usr/local/${backup_file}"
sudo docker container cp ${CID}:/usr/local/${backup_file} ${backup_file}

echo 'done!'
