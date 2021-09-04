#!/bin/bash

while true ; do
  OUT=$(/bin/bash -c "$*")
  clear
  echo "$OUT"
  sleep 4
done