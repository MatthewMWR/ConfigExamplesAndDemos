#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

echo "Creating resource group"
az group create --resource-group $DEMO_NAME --location westus2

echo "Creating IoT Hub"
az iot hub create --name $DEMO_NAME --resource-group $DEMO_NAME

echo "Creating baseline/noop configs for reporting"
for CONFIG_PATH in `ls -d assets/*_noop.adm.json`
do 
  util/ADMConfigImport.sh $DEMO_NAME $CONFIG_PATH 
done