#!/bin/bash

DEMO_NAME=$(util/DemoNameGet.sh)

#util/WatchAlt.sh util/ADMConfigShowSummary.sh $DEMO_NAME

#function jsonArrayToTable(){
#    jq -r '(.[0] | ([keys[] | .] |(., map(length*"-")))), (.[] | ([keys[] as $k | .[$k] | tostring | .[0:24] ])) | @tsv' | column -t -s $'\t' -n -c 100
#}

SELECT="deviceId, connectionState, tags.country, properties.reported.Networking.NetworkConfiguration.IpAddresses, properties.reported.Networking.NetworkConfiguration.DnsServers"

QUERY="select ${SELECT} from devices.modules where moduleId='osconfig'"

TABLE_COLUMNNAMES="deviceId,connectionState,country,IpAddresses,DnsServers"

TABLE_COLUMNVALUEMAXLENGTH=24

while true ; do
  OUT=$(util/DevicesShowSummary.sh $DEMO_NAME "$QUERY" "$TABLE_COLUMNNAMES" $TABLE_COLUMNVALUEMAXLENGTH)
  clear
  echo "$OUT"
  sleep 4
done
