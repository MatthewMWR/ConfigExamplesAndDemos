#!/bin/bash

util/ContextCheck.sh
DEMO_NAME=$(util/DemoNameGet.sh)

util/CloudDeleteAll.sh $DEMO_NAME 