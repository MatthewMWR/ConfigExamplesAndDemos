#!/bin/bash

wave=$3
shutdownAfterSetup=$4
package_channels=("prod") # Use ("prod") for stable release, use ("prod" "insiders-fast") for preview builds
start_device_labels_at_number=$1 # Typically 1
create_this_many_devices=$2
vm_size="Standard_B1s"
use_this_azure_location="westus2"
demoUniqueLabel="OSCDemo-277"
resourceGroupForVMs="OSCDemo-277_VMs"
lastDeviceNumber=$(( $start_device_labels_at_number+$create_this_many_devices-1 ))

az group create --name "$resourceGroupForVMs" --location "$use_this_azure_location" --query id

## Create IoT Hub device IDs and corresponding connected virtual devices (VMs)
vmInitScriptTemplate='#!/bin/bash
sleep 10s
sudo apt-get update
sleep 5s
## add prod and sometimes insider channels from packages.microsoft.com
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/pkgs-msft_key.asc > /dev/null
## channel add commands added dynamically below this line
sudo apt-get update
sleep 15s

## Install and configure AIS, then osconfig
sudo apt-get install -y aziot-identity-service
sleep 5s
sudo aziotctl config mp --connection-string DEMO_CONNECTION_STRING_PLACEHOLDER --force
sudo aziotctl config apply
sleep 10s
sudo apt-get -y install osconfig
sleep 5s
sudo systemctl restart osconfig
sleep 5s
'

for i in $(seq $start_device_labels_at_number $lastDeviceNumber)
do
  deviceName=$(printf "device%02d" "$i")
  echo "Creating device ID and connected virtual device $deviceName"
  if [[ $((i%2)) == 0 || $i -eq 1 ]]
  then
    siteName="Munich"
    siteType="gen1"
  else
    siteName="Berlin"
    siteType="gen2"
  fi
  tags="{\"siteType\": \"$siteType\",\"siteName\": \"$siteName\",\"wave\":\"$wave\"}"
  pathToDeviceInitScript="/var/tmp/$deviceName.sh"
  az iot hub device-identity create --hub-name "$demoUniqueLabel" --device-id "$deviceName" --query status
  sleep 2s
  az iot hub device-twin update --tags "$tags" --hub-name "$demoUniqueLabel" --device-id "$deviceName" --query tags

  connectionString=$(az iot hub device-identity connection-string show --device-id "$deviceName" --hub-name "$demoUniqueLabel" --query connectionString)
  echo "$vmInitScriptTemplate" > "$pathToDeviceInitScript"
  sed -i "s|DEMO_CONNECTION_STRING_PLACEHOLDER|$connectionString|" "$pathToDeviceInitScript"
  for channelName in "${package_channels[@]}"
  do
    additionalChannelString="curl -sSL https://packages.microsoft.com/config/ubuntu/20.04/$channelName.list | sudo tee /etc/apt/sources.list.d/pkgs-msft_$channelName.list"
    sed -i "5 s[^[$additionalChannelString\n[" "$pathToDeviceInitScript"
  done
  az vm create --tags "$tags" --resource-group "$resourceGroupForVMs" --name "$deviceName" --size "$vm_size" --image "canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest" --generate-ssh-keys --user-data "$pathToDeviceInitScript" --public-ip-sku Standard --admin-username "azureuser" --no-wait
  sleep 2
  rm "$pathToDeviceInitScript"
done

sleep 90s

for i in $(seq $start_device_labels_at_number $lastDeviceNumber)
do
  deviceName=$(printf "device%02d" "$i")
  echo "Trying to set tags on $deviceName"
  if [[ $((i%2)) == 0 || $i -eq 1 ]]
  then
    siteName="Munich"
    siteType="gen1"
  else
    siteName="Berlin"
    siteType="gen2"
  fi
  tags="{\"siteType\": \"$siteType\",\"siteName\": \"$siteName\",\"wave\":\"$wave\"}"
  while [[ -z $(az iot hub module-twin show -m osconfig -d "$deviceName" -n "$demoUniqueLabel" -g "$demoUniqueLabel") ]]
  do
    printf "."
    sleep 10s
  done
  siteName="default"
  
  az iot hub module-twin update --tags "$tags" -g "$demoUniqueLabel" -n "$demoUniqueLabel" -d "$deviceName" -m 'osconfig' --query tags
  az vm list-ip-addresses -n "$deviceName" -g "$resourceGroupForVMs" --query [].virtualMachine.network.publicIpAddresses[].ipAddress --output tsv
  if [ "$shutdownAfterSetup" -gt 0 ]
  then
    az vm stop -n "$deviceName" -g "$resourceGroupForVMs"
  fi  
done