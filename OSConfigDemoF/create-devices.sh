#!/bin/sh

## IMPORTANT: For this quick temporary demo in a controlled VM 
## lab environment we are using simple connection strings embedded in scripts.
## For real devices and scenarios you should choose stronger authentication
## mechanisms, such as hardware protected device secrets.

if [ -z "$1" ]
then
    uniquifier=$(od --address-radix=n -N2 -i /dev/random | tr -d [:space:])
    demoUniqueLabel="QuickStart-$uniquifier"
else
    demoUniqueLabel=$1
fi

echo "##"
echo "## Starting lab setup"
echo "## Your resource group and IoT Hub will be named:"
echo "## $demoUniqueLabel"
echo "##"

resourceGroupName="$demoUniqueLabel"
location="westus2"
iotHubName="$demoUniqueLabel"
startAtDeviceNumber=1
endAfterDeviceNumber=2

echo ""
echo "## Creating resource group"
echo ""
az group create --name "$resourceGroupName" --location "$location" --query id

echo ""
echo "## Creating IoT Hub (this can take a few minutes)"
echo ""
az iot hub create --resource-group "$resourceGroupName" --name "$iotHubName" --query id

vmInitScriptTemplate='#!/bin/sh
demo_connection_string=DEMO_CONNECTION_STRING_PLACEHOLDER

## simulate ADHS being installed by placing ADHS config file
mkdir /etc/azure-device-health-services/
echo "Permission = \"Optional\"" > /etc/azure-device-health-services/config.toml

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
    pathToDeviceInitScript="./temp/$deviceName.sh"
    echo ""
    echo "## Creating IoT Hub devide identity: $deviceName"
    echo ""
    az iot hub device-identity create --hub-name "$iotHubName" --device-id "$deviceName" --query status
    connectionString=$(az iot hub device-identity connection-string show --device-id "$deviceName" --hub-name "$iotHubName" --query connectionString)
    echo "$vmInitScriptTemplate" > $pathToDeviceInitScript
    sed -i "s|DEMO_CONNECTION_STRING_PLACEHOLDER|$connectionString|" $pathToDeviceInitScript
    echo ""
    echo "## creating VM to act as virtual device: $deviceName"
    echo ""
    az vm create --resource-group "$resourceGroupName" --name "$deviceName" --size Standard_B1s --image "canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest" --generate-ssh-keys --user-data $pathToDeviceInitScript --public-ip-sku Standard --admin-username "azureuser" --no-wait
    sleep 2
    rm $pathToDeviceInitScript
done

echo "## Lab setup script concluded"
echo "## Your resource group and IoT Hub are named:"
echo "## $demoUniqueLabel"
echo ""
