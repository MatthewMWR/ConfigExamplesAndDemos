#!/bin/bash

DEMO_NAME=$(util/DemoNameGet.sh)

VIEW=1

while true ; do
  OUT=$(util/DashboardRender.sh $DEMO_NAME $VIEW)
  clear
  echo "$OUT"
  read -s -t 2 NEW_VIEW
  if [ -z $NEW_VIEW ]
  then continue
  else VIEW="$NEW_VIEW"
  fi
done
