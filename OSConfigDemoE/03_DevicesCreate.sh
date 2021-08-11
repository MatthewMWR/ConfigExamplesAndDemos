#!/bin/bash

if [ "$4" != "-y" ]
then
  util/ContextCheck.sh
fi

DEMO_NAME=$(util/DemoNameGet.sh)

START_AT=$1
END_AFTER=$2
DELAY_SECONDS=$3

LOCATIONS=("DE" "ES" "BR")

for i in `seq $1 $2`
do
  echo "$i"
  LOCATION=$(echo ${LOCATIONS[RANDOM%${#LOCATIONS[@]}]})
  DEVICE_NAME=$(printf "Device%02d" $i)
  az iot hub device-identity create -n $DEMO_NAME -d $DEVICE_NAME
  ## FUTURE: Make this parallel friendly (for quickly creating many devices)
  ## by making this connection string file name device instance specific
  ## or using some other mechanism to pass the connection string to the device
  az iot hub device-identity connection-string show -n $DEMO_NAME -d $DEVICE_NAME --query connectionString | tr -d \" > /var/tmp/DeviceConnectionString.txt
  lxc launch OSConfigBase01 $DEVICE_NAME
  sleep 1s
  lxc file push /var/tmp/DeviceConnectionString.txt $DEVICE_NAME/var/tmp/
  lxc file push assets/DeviceSetupInside-B.sh $DEVICE_NAME/var/tmp/
  lxc exec $DEVICE_NAME -n -T -- /var/tmp/DeviceSetupInside-B.sh
  az iot hub module-twin update --device-id $DEVICE_NAME --hub-name $DEMO_NAME --module-id "osconfig" --tags "{\"country\": \"$LOCATION\"}"
  sleep $DELAY_SECONDS
done
