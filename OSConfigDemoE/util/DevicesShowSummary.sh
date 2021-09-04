#!/bin/bash

DEMO_NAME=$1
IOTHUB_QUERY=$2
AZ_CLI_JMSE_QUERY=$3
TABLE_COLUMNNAMES=$4
TABLE_COLUMNVALUEMAXLENGTH=$5
STYLE_STRONG="\033[1;92m"
STYLE_RESET="\033[0m"
STYLE_WEAK="\033[90m"

TITLE="
----------------------------------------------------------------------
|$STYLE_STRONG Device Management$STYLE_RESET$STYLE_WEAK:  $DEMO_NAME:  $(date) $STYLE_RESET"

echo -e "$TITLE"

echo ""

az iot hub query -n $DEMO_NAME -q "$IOTHUB_QUERY" --query "$AZ_CLI_JMSE_QUERY" \
| util/Bug35118796Workaround.sh \
| util/Json2Table.sh "$TABLE_COLUMNNAMES" $TABLE_COLUMNVALUEMAXLENGTH \
| awk '{ print "  " $0 }'
