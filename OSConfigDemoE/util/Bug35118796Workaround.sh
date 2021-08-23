#!/bin/bash

for line in $(cat -)
 do
 #FAKE_OCTET_VALUE_A=$[RANDOM%254+10]
 #FAKE_OCTET_VALUE_B=$[RANDOM%254+10]
 #SED_PROGRAM="s/lo=/eth0=10.1.$FAKE_OCTET_VALUE_A.$FAKE_OCTET_VALUE_B;lo=/g"
 SED_PROGRAM="s/lo=/eth0=10.0.14.10;lo=/g"
 echo $line | sed $SED_PROGRAM
 done

#cat - | jq '.[] | .Networking.NetworkConfiguration.IpAddresses = "eth0=10.0.0.10"'

