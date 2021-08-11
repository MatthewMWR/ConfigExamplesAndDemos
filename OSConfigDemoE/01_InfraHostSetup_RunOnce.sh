#!/bin/bash
#sudo apt remove azure-cli -y && sudo apt autoremove -y
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version
az extension add --name azure-iot

sudo snap install lxd
lxc --version

lxc launch ubuntu:18.04 UbuntuBasePlus
sleep 10s
lxc file push assets/DeviceSetupInside-A.sh UbuntuBasePlus/var/tmp/
lxc exec UbuntuBasePlus -- /var/tmp/DeviceSetupInside-A.sh
sleep 5s
lxc stop UbuntuBasePlus
lxc publish UbuntuBasePlus --alias OSConfigBase01
