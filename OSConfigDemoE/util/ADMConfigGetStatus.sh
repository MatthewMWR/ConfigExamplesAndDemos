#!/bin/bash

DEMO_NAME=$1
CONFIG_NAME=$2
CONFIG_METRIC=$3

az iot hub configuration show-metric \
--config-id $CONFIG_NAME -n $DEMO_NAME -m $CONFIG_METRIC \
--query result

