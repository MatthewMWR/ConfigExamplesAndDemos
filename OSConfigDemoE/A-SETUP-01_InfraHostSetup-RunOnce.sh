#!/bin/bash
#sudo apt remove azure-cli -y && sudo apt autoremove -y
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

INTERIM_INSTANCE_NAME="UbuntuBasePlus05"
OUTPUT_IMAGE_NAME="OSConfigBase05"

az --version
az extension add --name azure-iot

sudo apt install -y jq
sudo apt install -y csvkit

sudo snap install lxd
lxc --version

lxc launch ubuntu:18.04 "$INTERIM_INSTANCE_NAME"
sleep 10s
lxc file push assets/DeviceSetupInside-A.sh "$INTERIM_INSTANCE_NAME/var/tmp/"
lxc exec "$INTERIM_INSTANCE_NAME" -- /var/tmp/DeviceSetupInside-A.sh
sleep 5s
lxc stop "$INTERIM_INSTANCE_NAME"
lxc publish "$INTERIM_INSTANCE_NAME" --alias "$OUTPUT_IMAGE_NAME"
