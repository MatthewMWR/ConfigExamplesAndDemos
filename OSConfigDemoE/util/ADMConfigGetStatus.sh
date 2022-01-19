#!/bin/bash

DEMO_NAME=$1
CONFIG_NAME=$2
CONFIG_METRIC=$3

## For some reason getting the results via az iot hub configuration show-metric
## is running extremely slowly.
## As an alternative I am trying to extract the query from the Config, and
## run it directly using query
##az iot hub configuration show-metric \
##--config-id $CONFIG_NAME -n $DEMO_NAME -m $CONFIG_METRIC \
##--query result

CONFIG_JSON=$(az iot hub configuration show --config-id $CONFIG_NAME -n $DEMO_NAME)
QUERY=$(echo $CONFIG_JSON | jq -r .metrics.queries.detailedStatus)
az iot hub query -n $DEMO_NAME -q "$QUERY"