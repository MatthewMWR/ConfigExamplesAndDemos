function Get-DemoFleetStatusData {
    param($IoTHubName)
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
    $azOutput = az iot hub query -n $IotHubName -q "select * from devices.modules WHERE devices.modules.moduleId='osconfig'" --hub-name $IoTHubName
    $azOutputAsPSO = $azOutput | Convertfrom-json -AsHashtable
    $azOutputAsPSO |
    Select-Object -property @( 
        @{n="DeviceId  ";e={$_.deviceId + "  "}}
        @{n="ConnectionState  ";e={$_.connectionState + "  "}}
        @{n="Country  ";e={" " + $_.tags.country }}
        @{n="Config  "; e={$($_.configurations.getenumerator() | ?{$_.Value.Values -contains "Applied"} | % {$_.Name + " " })}}
        @{n="TelLevel_Desired  ";e={" " + $_.properties.desired.Settings.DeviceHealthTelemetryConfiguration.ToString()}}
        @{n="TelLevel_Reported  ";e={" " + $_.properties.reported.Settings.DeviceHealthTelemetryConfiguration.value.ToString()}}
        @{n="CmdRunner_Command  ";e={$_.properties.desired.CommandRunner.CommandArguments.Arguments.ToString().Substring(0,30)}}
        @{n="CmdRunner_Output  ";e={$_.properties.reported.CommandRunner.CommandStatus.TextResult.ToString()}}
        )
}

function Update-DemoDashboardDataCache {
    param(
    $IoTHubName,
    $OutPath
    )
    Write-Information $PSBoundParameters

    $workingFilePath = $OutPath + "WORKING"

@'

####################################      
                                      
        OPERATIONS DASHBOARD              
          |_ DEVICES                      
                                     
####################################  

'@ > $workingFilePath

    '      ' + (Get-Date) >> $workingFilePath
    '' >> $workingFilePath
    Get-DemoFleetStatusData -IoTHubName $IotHubName | Sort-Object -Property Country | format-table -autosize | out-file -Path $workingFilePath -Width 160 -Append

@'

#################################### 
'@ >> $workingFilePath

    copy-item $workingFilePath $OutPath -Force
}