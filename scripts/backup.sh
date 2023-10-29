#!/bin/bash

BACKUP_DIR_PATH="/mnt/data/backup"
S3_BUCKET="911archive-mediawiki-backups"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
ZIP_FILE="backup-$TIMESTAMP.zip"

systemctl stop mediawiki

mkdir -p $BACKUP_DIR_PATH
cp -r /mnt/data/mediawiki $BACKUP_DIR_PATH
cp -r /mnt/data/mariadb $BACKUP_DIR_PATH
cp /mnt/data/LocalSettings.php $BACKUP_DIR_PATH

zip -r $BACKUP_DIR_PATH/$ZIP_FILE $BACKUP_DIR_PATH/*
aws s3 cp $BACKUP_DIR_PATH/$ZIP_FILE s3://$S3_BUCKET/
rm -rf $BACKUP_DIR_PATH/*

systemctl start mediawiki
