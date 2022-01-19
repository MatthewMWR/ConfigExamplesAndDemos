#!/bin/sh

## IMPORTANT: For this quick temporary demo in a controlled VM 
## lab environment we are using simple connection strings embedded in scripts.
## For real devices and scenarios you should choose stronger authentication
## mechanisms, such as hardware protected device secrets.

resourceGroupName="QuickStart-OSConfig-Fleet"
location="westus2"
iotHubName="$resourceGroupName"
startAtDeviceNumber=1
endAfterDeviceNumber=2

az group create --name "$resourceGroupName" --location "$location"
az iot hub create --resource-group "$resourceGroupName" --name "$iotHubName"

vmInitScriptTemplate='#!/bin/sh
demo_connection_string=DEMO_CONNECTION_STRING_PLACEHOLDER

## add prod and insiders channels from packages.microsoft.com to package manager
os=$(cat /etc/os-release | grep ^ID= | tr -d "ID=")
version=$(cat /etc/os-release | grep VERSION_ID | tr -d "VERSION_ID=" | tr -d \")
curl -sSL https://packages.microsoft.com/config/$os/$version/prod.list | sudo tee /etc/apt/sources.list.d/packages.microsoft.com_prod.list
curl -sSL https://packages.microsoft.com/config/$os/$version/insiders-fast.list | sudo tee /etc/apt/sources.list.d/packages.microsoft.com_insiders-fast.list
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
sudo apt-get update

## Install AIS. Downloading from GitHub as workaround to 
## package not yet on packages.microsoft.com
curl -L -O https://github.com/Azure/azure-iotedge/releases/download/1.2.5/aziot-identity-service_1.2.4-1_$os$version\_amd64.deb
sudo apt install ./aziot-identity-service_1.2.4-1_$os$version\_amd64.deb

## configure AIS
sudo aziotctl config mp --connection-string "$demo_connection_string" --force
sudo aziotctl config apply

sudo apt-get -y install osconfig
sleep 5
sudo systemctl restart osconfig
'

mkdir ./temp

for i in `seq $startAtDeviceNumber $endAfterDeviceNumber`
do
    deviceName=$(printf "device%02d" $i)
    az iot hub device-identity create --hub-name "$iotHubName" --device-id "$deviceName"
    connectionString=$(az iot hub device-identity connection-string show --device-id "$deviceName" --hub-name "$iotHubName" --query connectionString)
    echo "$vmInitScriptTemplate" > ./temp/$deviceName.sh
    sed -i "s|DEMO_CONNECTION_STRING_PLACEHOLDER|$connectionString|" ./temp/$deviceName.sh
    az vm create --resource-group "$resourceGroupName" --name "$deviceName" --size Standard_B1s --image "canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest" --generate-ssh-keys --user-data "./temp/$deviceName.sh" --public-ip-sku Standard --admin-username "azureuser" --no-wait
    rm ./temp/$deviceName.sh
done