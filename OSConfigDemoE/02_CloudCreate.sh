#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

echo "Creating resource group"
az group create --resource-group $DEMO_NAME --location westus2
echo "Creating IoT Hub"
az iot hub create --name $DEMO_NAME --resource-group $DEMO_NAME