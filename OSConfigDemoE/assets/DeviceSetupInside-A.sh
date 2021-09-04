#!/bin/bash

cd /var/tmp
touch DeviceSetupInsideBreadCrumb-A.txt 

## Outbound network access can be unreliable during the first few seconds
## in the containers, which breaks the following, so we sleep.
## FUTURE: Instead of sleeping and hoping, implement a dependencies
## check/wait features
sleep 4s

sudo apt-get update
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add
sudo apt-add-repository https://packages.microsoft.com/ubuntu/18.04/multiarch/prod
sudo apt-get update

sleep 4s

sudo apt-get -y install aziot-identity-service

sudo apt-get -y install osconfig

sudo systemctl stop osconfig

#sudo apt-get -y --no-install-recommends install python3-pip
#sudo apt-get -y --no-install-recommends install python3-wheel
#sudo apt-get -y --no-install-recommends install python3-setuptools
#sudo pip3 install wheel
#sudo pip3 install azure-iot-device
