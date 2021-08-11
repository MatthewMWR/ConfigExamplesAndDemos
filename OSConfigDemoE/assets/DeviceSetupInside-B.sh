#!/bin/bash

cd /var/tmp
touch DeviceSetupInsideBreadCrumb-B.txt 

sleep 5s

CONN_STRING=$(cat DeviceConnectionString.txt)

echo $CONN_STRING

sudo aziotctl config mp --connection-string $CONN_STRING --force
sudo aziotctl config apply

sudo systemctl stop osconfig
sudo systemctl start osconfig
sleep 5s
systemctl --no-pager status osconfig


