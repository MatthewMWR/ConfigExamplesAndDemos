#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

util/ADMConfigImport.sh $DEMO_NAME "assets/osconfig_sensitive.adm.json"
util/ADMConfigImport.sh $DEMO_NAME "assets/osconfig_everyone.adm.json"

## WORKAROUND: Sometimes IoT Hub takes many minutes to evaluate that
## a configuration profile should apply to some devices. This might
## be fine in normal life, but doesn't work in a demo where
## results must feel immediate.
## Tweaking the priority and/or target condition seems to trigger 
## re-evaluation in the rules engine and get things going.
sleep 10
az iot hub configuration update -c "osconfig_everyone" -n $DEMO_NAME --set priority=6 targetCondition="from devices.modules where moduleId='osconfig' and tags.country !='DE'"

