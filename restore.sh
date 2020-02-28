#!/bin/bash

set -x

if [ $# -lt 1 ]; then
    echo 'usage: redash-restore.sh <backup>'
    exit 1
fi
BACKUP_PATH=$(readlink --canonicalize $1)
if [ ! -f ${BACKUP_PATH} ]; then
    echo "${BACKUP_PATH} not exists."
    exit 1
fi

# Redash 公式 AMI は設定ファイルやボリュームは /opt/redash/ にある
#DOCKER_COMPOSE_YML=/opt/redash/docker-compose.yml

# 上記はEC2相当。Mac上ではよしなに
DOCKER_COMPOSE_YML=./docker-compose.yml

# Redash 絡みのコンテナを一旦止める
#sudo docker-compose --file ${DOCKER_COMPOSE_YML} down --remove-orphans

# PostgreSQL のバックアップを流し込む先の PostgreSQL コンテナを動かす
#sudo docker container run -d -v /usr/local/share/redash/postgres-data:/var/lib/postgresql/data -p 5432:5432 postgres:9.5.6-alpine

# PostgreSQL のバックアップファイルをホスト (EC2) から PostgreSQL コンテナへ持っていく
CID=$(sudo docker container ls | grep postgres | awk '{print $1}')
echo $CID
sudo docker container cp ${BACKUP_PATH} ${CID}:/usr/local/redash-backup.gz

# Redash のデータベースを削除 & 再作成
sudo docker container exec ${CID} /bin/bash -c 'psql -c "drop database if exists postgres" -U postgres template1'
sudo docker container exec ${CID} /bin/bash -c 'psql -c "create database postgres" -U postgres template1'

# バックアップを PostgreSQL へ流し込む
sudo docker container exec ${CID} /bin/bash -c 'zcat /usr/local/redash-backup.gz | psql -U postgres -d postgres'

# バックアップの流し込みに使った PostgreSQL のコンテナはもう使わないので止める
#sudo docker container stop ${CID}
#sudo docker container rm ${CID}

# Redash 絡みのコンテナを動かす
#sudo docker-compose --file ${DOCKER_COMPOSE_YML} up --detach
