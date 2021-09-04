#!/bin/bash

DEMO_NAME=$(util/DemoNameGet.sh)

IOT_HUB_SELECT="deviceId, properties.reported.tempLatest, properties.reported.tempTarget AS tempTarget_Reported, properties.desired.tempTarget AS tempTarget_Desired"

IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices"

AZ_CLI_JMSE_QUERY="[].{deviceId:deviceId,tempLatest:tempLatest,tempTarget_Reported:tempTarget_Reported,tempTarget_Desired:tempTarget_Desired}"

TABLE_COLUMNNAMES="deviceId,tempLatest,tempTarget_Reported,tempTarget_Desired"

TABLE_COLUMNVALUEMAXLENGTH=24

while true ; do
  OUT=$(util/DevicesShowSummary.sh $DEMO_NAME "$IOT_HUB_QUERY" "$AZ_CLI_JMSE_QUERY" "$TABLE_COLUMNNAMES" $TABLE_COLUMNVALUEMAXLENGTH)
  clear
  echo "$OUT"
  sleep 4
done
