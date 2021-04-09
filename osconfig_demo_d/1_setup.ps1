param(
    [hashtable]$DemoParameters = @{}
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
Set-StrictMode -Version Latest

Import-Module (Join-Path $psscriptroot "demoSetupFunctions.psm1") -Force

if($DemoParameters.Count -eq 0){
    $DemoParameters = New-DemoParameters
}

Export-DemoParameters -DemoParameters $DemoParameters

Write-Information "The demo environment ID for this run is $($DemoParameters.DemoEnvironmentName)"

New-DemoIoTHub @DemoParameters

Add-DemoADMConfigurations @DemoParameters

Add-DemoDevice @DemoParameters -DeviceCount 4