#!/bin/bash

DEMO_NAME=$1
JOBJSON="$(cat $2)"

az iot hub configuration delete \
-n "$DEMO_NAME" \
--config-id "$(echo $JOBJSON | jq -r .id)"

az iot hub configuration create \
-n "$DEMO_NAME" \
--config-id "$(echo $JOBJSON | jq -r .id)" \
--content "$(echo $JOBJSON | jq .content)" \
--target-condition "$(echo $JOBJSON | jq -r .targetCondition)" \
--priority "$(echo $JOBJSON | jq -r .priority)" \
--metrics "$(echo $JOBJSON | jq -r .metrics)"