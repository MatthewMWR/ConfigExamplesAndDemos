#!/bin/bash
DEMO_NAME=$1
for DEVICE_NAME in $(lxc list -c n -f csv)
do 
    echo $DEVICE_NAME
    lxc delete $DEVICE_NAME --force
    az iot hub device-identity delete -n $DEMO_NAME -d $DEVICE_NAME
done