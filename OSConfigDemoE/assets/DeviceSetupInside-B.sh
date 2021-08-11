#!/bin/bash

cd /var/tmp
touch DeviceSetupInsideBreadCrumb-B.txt 

## Experience has shown the container needs a few seconds to settle in
## FUTURE: Figure out how to test and wait for dependencies explicitly
## rather than sleep + hope
sleep 5s

CONN_STRING=$(cat DeviceConnectionString.txt)

echo $CONN_STRING

sudo aziotctl config mp --connection-string $CONN_STRING --force
sudo aziotctl config apply

sudo systemctl stop osconfig
sudo systemctl start osconfig
sleep 5s
systemctl --no-pager status osconfig


