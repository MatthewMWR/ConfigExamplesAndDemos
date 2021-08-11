#!/bin/bash

echo "| Azure account context"
echo "| (from az login and az account)"
echo "| ------------------------------"
az account show --query [name,id] | awk '{ print "  " $0 }'
echo ""

DEMO_NAME=$(util/DemoNameGet.sh)
echo "| Demo name context" 
echo "| (from 00_DemoParameters.json)"
echo "| ------------------------------"
echo ""
echo $DEMO_NAME | awk '{ print "  " $0 }'
echo ""
read -p "| Press ENTER to continue or CTRL+C to exit"