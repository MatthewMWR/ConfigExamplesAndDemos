#!/bin/bash

DEMO_NAME=$(util/DemoNameGet.sh)

IOT_HUB_QUERY_SELECT="deviceId, connectionState, tags.country, properties.reported.Networking.NetworkConfiguration.IpAddresses, properties.reported.Networking.NetworkConfiguration.DnsServers"

IOT_HUB_QUERY="select ${IOT_HUB_QUERY_SELECT} from devices.modules where moduleId='osconfig'"

AZ_CLI_JMSE_QUERY="[]"

TABLE_COLUMNNAMES="deviceId,connectionState,country,IpAddresses,DnsServers"

TABLE_COLUMNVALUEMAXLENGTH=24

while true ; do
  OUT=$(util/DevicesShowSummary.sh $DEMO_NAME "$IOT_HUB_QUERY" "$AZ_CLI_JMSE_QUERY" "$TABLE_COLUMNNAMES" $TABLE_COLUMNVALUEMAXLENGTH)
  clear
  echo "$OUT"
  sleep 4
done
