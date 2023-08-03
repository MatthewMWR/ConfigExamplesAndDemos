#!/bin/bash

azureLocationForHub="westus3"
demoUniqueLabel="$(cat demo-env-name.txt)"
resourceGroupForVMs=$(printf "%s_VM" "$demoUniqueLabel")

echo "Creating resource group and IoT Hub"
az group create --name "$demoUniqueLabel" --location "$azureLocationForHub" --query id
az group create --name "$resourceGroupForVMs" --location "$azureLocationForHub" --query id
if [[ -z $(az iot hub show -n $demoUniqueLabel -g $demoUniqueLabel) ]]
then
  az iot hub create --resource-group "$demoUniqueLabel" --name "$demoUniqueLabel" --query id --output tsv
fi

# The below commands sometimes fail mysteriously. Suspicion is that the Hub isn't ready.
# Sleep added to (hopefully) increase success rate
# FUTURE: Determine where "Hub isn't ready" is really the cause and if so find a way
# to properly wait. If that turns out not to be the cause then remove this sleep
sleep 30s

az iot hub configuration create -c "net_config" --content assets/net-config_modulecontent.json \
 --target-condition "from devices.modules where moduleId='osconfig' AND tags.siteType='gen1'" --priority 50 \
 --metrics assets/net-config_metrics.json --hub-name "$demoUniqueLabel"

 az iot hub configuration create -c "net_config_gen2_sites" --content assets/net-config-for-gen2-sites_modulecontent.json \
 --target-condition "FROM devices.modules WHERE moduleId='osconfig' AND tags.siteType='gen2'" --priority 51 \
 --metrics assets/net-config-for-gen2-sites_metrics.json --hub-name "$demoUniqueLabel"

 az iot hub configuration create -c "pkg_source_config" --content assets/pkg-config_modulecontent.json \
 --target-condition "from devices.modules where moduleId='osconfig'" --priority 50 \
 --metrics assets/pkg-config_metrics.json --hub-name "$demoUniqueLabel"
 