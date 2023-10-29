#!/bin/bash

set -e

BACKUP_DIR_PATH="/mnt/data/backup"
S3_BUCKET="911archive-mediawiki-backups"
ZIP_FILE=$1

if [[ -z $ZIP_FILE ]]; then
  echo "The restore zip file must be provided as an argument"
  exit 1
fi

echo "Retrieving backup zip from S3..."
aws s3 cp s3://$S3_BUCKET/$ZIP_FILE $BACKUP_DIR_PATH/$ZIP_FILE
tmp_dir_path=$(mktemp -d)
unzip $BACKUP_DIR_PATH/$ZIP_FILE -d $tmp_dir_path

cp -r $tmp_dir_path/mnt/data/backup/** $BACKUP_DIR_PATH
cp -r $BACKUP_DIR_PATH/mediawiki /mnt/data/
cp -r $BACKUP_DIR_PATH/mariadb /mnt/data/
cp $BACKUP_DIR_PATH/LocalSettings.php /mnt/data/

rm -rf $BACKUP_DIR_PATH/*
