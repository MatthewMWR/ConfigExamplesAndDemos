#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

util/DevicesDeleteAll.sh $DEMO_NAME 
