#!/bin/bash

demoUniqueLabel="$(cat demo-env-name.txt)"

pwsh assets/add-devices_v2.ps1 -DemoEnvName "$demoUniqueLabel" -Count 40
