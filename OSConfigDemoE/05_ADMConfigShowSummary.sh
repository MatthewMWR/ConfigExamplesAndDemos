#!/bin/bash

DEMO_NAME=$(cat util/DemoNameGet.sh )
CONFIG_METRIC="detailedStatus"
STYLE_STRONG="\033[1;92m"
STYLE_RESET="\033[0m"
STYLE_WEAK="\033[90m"
TITLE="
----------------------------------------------------------------------------------------------------
|$STYLE_STRONG Automatic Device Management$STYLE_RESET$STYLE_WEAK: $DEMO_NAME | $(date) $STYLE_RESET
"

function jsonArrayToTable(){
    jq -r '(.[0] | ([keys[] | .] |(., map(length*"-")))), (.[] | ([keys[] as $k | .[$k] | tostring | .[0:24] ])) | @tsv' | column -t -s $'\t' -n -c 100
}

echo -e "$TITLE"

for CONFIG_NAME in `az iot hub configuration list -n $DEMO_NAME --query [].id --output tsv | sort`
do
  CONFIG_STATUS_DATA=$(util/ADMJobGetStatus.sh $DEMO_NAME $CONFIG_NAME $CONFIG_METRIC)
  ITEM_COUNT=$(echo $CONFIG_STATUS_DATA | jq '. | length')
  CONFIG_BANNER="
--------------------------------------
| $STYLE_STRONG $CONFIG_NAME$STYLE_RESET$STYLE_WEAK: $ITEM_COUNT devices $STYLE_RESET
"
  echo -e "$CONFIG_BANNER" | awk '{ print " " $0 }'
  if [ $ITEM_COUNT -gt 0 ]
    then
        echo $CONFIG_STATUS_DATA | jsonArrayToTable | awk '{ print "    " $0 }'
  fi 
done