#!/bin/bash

echo "w"
echo "$*"

while true ; do
  OUT=$(/bin/bash -c "$*")
  #clear
  echo "$OUT"
  sleep 4
done