#!/bin/bash

demoUniqueLabel="$(cat demo-env-name.txt)"
resourceGroupForVMs=$(printf "%s_VM" "$demoUniqueLabel")

az group delete --resource-group "$demoUniqueLabel" --yes --force-deletion-types Microsoft.Compute/virtualMachines --no-wait

az group delete --resource-group "$resourceGroupForVMs" --yes --force-deletion-types Microsoft.Compute/virtualMachines --no-wait
