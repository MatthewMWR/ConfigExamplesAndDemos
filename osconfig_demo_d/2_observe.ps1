$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
Set-StrictMode -Version Latest
Import-Module (Join-Path $psscriptroot "demoSetupFunctions.psm1") -Force
Import-Module (Join-Path $psscriptroot "demoOperateFunctions.psm1") -Force
Import-Module PoshRSJob

$thisDemo = Import-DemoParameters

$dashboardCacheFilePath = Join-Path $thisDemo.TempPath "dashboardCache.txt"
$iotHubName = $thisDemo.IoTHubName

$dataRefreshJob = Start-RSJob -FunctionsToImport "Get-DemoFleetStatusData","Update-DemoDashboardDataCache" -Scriptblock {
    cd $Using:pwd
    $continue=$true
    while($true){
        if([console]::KeyAvailable){ $continue = $false ; continue }
        Update-DemoDashboardDataCache -IoTHubName $Using:iotHubName -OutPath $Using:dashboardCacheFilePath
        Start-Sleep -Seconds 1
    }
}

try{
    watch -t -d -n 1 cat $dashboardCacheFilePath
}
finally{
    Start-Sleep -seconds 2
    Stop-RSJob $dataRefreshJob
    Remove-RSJob $dataRefreshJob -Force
}







