#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

for CONFIG_PATH in `ls -d assets/*adm.json`
do 
  util/ADMConfigImport.sh $DEMO_NAME $CONFIG_PATH 
done