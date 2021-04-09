$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
Set-StrictMode -Version Latest

function New-DemoParameters {
    param(
        $DemoEnvironmentNamePrefix = "Demo-",
        $ResourceGroupName = "Ens-NonProd-Comm-ItEM-Cus-00",
        $VMImageLabel = "UbuntuLTS",
        $VMSize = "Standard_A1_v2",
        $VMAdminUserName = "demo_user",
        $TempPath = (Join-Path $psscriptroot "temp"),
        $AssetsPath = (Join-Path $psscriptroot "assets")
    )

    $demoEnvironmentName = $DemoEnvironmentNamePrefix + (Get-Random -min 1000 -max 9999)

    @{
        DemoEnvironmentName = $demoEnvironmentName
        IoTHubName = $demoEnvironmentName
        ResourceGroupName = $ResourceGroupName
        VMImageLabel = $VMImageLabel
        VMSize = $VMSize
        VMAdminUserName = $VMAdminUserName
        TempPath = $TempPath
        AssetsPath = $AssetsPath
    }
}

function Export-DemoParameters{
    param(
        [hashtable]$DemoParameters,
        $SaveName = "saved-demo-parameters_default"
    )
    Export-Clixml -Path (Join-Path $PSScriptRoot $SaveName) -InputObject $DemoParameters 
}

function Import-DemoParameters{
    param($SaveName = "saved-demo-parameters_default")
    Import-Clixml -Path (Join-Path $PSScriptRoot $SaveName)
}

function New-DemoIoTHub {
    param(
        $IotHubName,
        $ResourceGroupName
        )
    Write-Information "START: Creating IoT Hub, this often takes a few minutes"
    az iot hub create --name $IoTHubName --resource-group $ResourceGroupName
    Write-Information "END: Creating IoT Hub"
}

function Add-DemoADMConfigurations{
    param(
        $IoTHubName,
        $AssetsPath, 
        $TempPath
    )
    Write-Information "START: Creating ADM jobs"
    foreach($fileItem in Get-ChildItem -Path assets -filter ADM*Parameters.json)
    {
        Add-DemoADMConfiguration -IoTHubName $IoTHubName -ADMConfigParametersJsonString (Get-Content $fileItem.FullName)
    }
    Write-Information "END: Creating ADM Jobs"
}

function Add-DemoADMConfiguration {
    param(
        $IoTHubName,
        $ADMConfigParametersJsonString,
        $TempPath = $PWD
    )
    $jobParameters = $ADMConfigParametersJsonString | ConvertFrom-Json
    $jobContentTempPath = Join-Path $TempPath "tempContent.json"
    $jobMetricsTempPath = Join-Path $TempPath "tempMetrics.json"
    $jobParameters.content | ConvertTo-JSON -Depth 5 > $jobContentTempPath
    $jobParameters.metrics | ConvertTo-JSON -Depth 5 > $jobMetricsTempPath
    $ErrorActionPreference = 'SilentlyContinue'
    $null = az iot hub configuration delete -c $jobParameters.id -n $IotHubName 2>&1 
    $ErrorActionPreference = 'Stop'
    az iot hub configuration create -c $jobParameters.id -n $IotHubName --content $jobContentTempPath --metrics $jobMetricsTempPath --target-condition $jobParameters.targetCondition --priority $jobParameters.priority
}

function New-DemoVMPassword {
    $chars = @(
        ,[System.Object[]][char[]]([char]'a'..[char]'z')
        ,[System.Object[]][char[]]([char]'A'..[char]'Z')
        ,@('-','!','#','@','_','+','|',',')
    )

    @(foreach($n in 1..6){
        foreach($nn in 0..2){
            Get-Random $chars[$nn]
        }
    }) -join ''
}

function Add-DemoDevice{
    param(
        $DemoEnvironmentName,
        $IoTHubName,
        $ResourceGroupName,
        $VMImageLabel,
        $VMSize,
        $VMAdminUserName,
        $DeviceCount = 1,
        $StartAt = 1,
        $TempPath,
        $AssetsPath
    )

    ## create logical devices and vms
    $endAfter = $StartAt + $DeviceCount - 1
    Write-Information "Creating $($DeviceCount) devices from $($StartAt) to $($endAfter)"
    foreach( $n in $StartAt..$endAfter )
    {
        $reportOut = [pscustomobject]@{
            DeviceId = ""
            DeviceSSHUserName = $VMAdminUserName
            DeviceSSHPwd = ""
            DeviceConnectionString = ""
            DeviceIpAddress = ""
        }
        $tagsPayloadForThisDevice = Convert-HashTableToAzCliTagsPayload @{country = (Get-Random "DE","ES") }
        ## create logical device
        $deviceId = "Device-" + $n
        $reportOut.DeviceId = $deviceId
        #$ErrorActionPreference = "Continue"
        $null = az iot hub device-identity create --device-id $deviceId --hub-name $IoTHubName --query "deviceId" 2>&1 
        $null = az iot hub device-twin update --device-id $deviceId --hub-name $IoTHubName --tags $tagsPayloadForThisDevice 2>&1 
        [string]$connectionString = az iot hub device-identity connection-string show --device-id $deviceId --hub-name $IoTHubName | convertfrom-json | Foreach-Object { $_.connectionString }
        if([string]::IsNullOrEmpty($connectionString)){
            throw "No connection string!!!"
        }
        $reportOut.DeviceConnectionString = $connectionString

        ## create quasi-physical device (VM)
        $tempPassword = New-DemoVMPassword
        $reportOut.DeviceSSHPwd = $tempPassword
        $deviceSpecificScriptPath = Join-Path $TempPath "os-setup_device-specific.sh"
        Set-DemoOSInitScriptContentForSpecificDevice -DeviceConnectionString $reportOut.DeviceConnectionString -OutputScriptPath $deviceSpecificScriptPath -AssetsPath $AssetsPath
        $null = az vm create --name $($DemoEnvironmentName + "-Device-" + $n) -g $ResourceGroupName --image $VMImageLabel --size $VMSize --admin-username $VMAdminUserName --admin-password $tempPassword --authentication-type all --generate-ssh-keys --custom-data $deviceSpecificScriptPath
        $vmDetails = az vm show --name $($DemoEnvironmentName + "-Device-" + $n) -g $ResourceGroupName --show-details --query publicIps        
        $reportOut.DeviceIpAddress = $vmDetails
        $reportOut

        while($false -eq (Test-DemoDeviceHasActiveOSConfigModule -DeviceId $deviceId -IoTHubName $IoTHubName)){
            Start-Sleep -Seconds 5
        }
        Write-Information "Creating module tags"
        $debugMsg = az iot hub module-twin update --device-id $deviceId --module-id "osconfig" --hub-name $IoTHubName --tags $tagsPayloadForThisDevice 2>&1 
        Write-Information $debugMsg
        Write-Information $LASTEXITCODE
    }
}

function Set-DemoOSInitScriptContentForSpecificDevice{
    param(
        $DeviceConnectionString,
        $AssetsPath,
        $OutputScriptPath
    )
    <#
    '#!/bin/sh' > $OutputScriptPath
    ## TODO Make this dynamic with run time SAS key generation, etc.
    ## Part 1 
    Get-Content -Path (Join-Path $AssetsPath "os-setup_part-1_get-assets.sh") >> $OutputScriptPath
    ## Part 2
    Get-Content -Path (Join-Path $AssetsPath "os-setup_part-2_setup.sh") >> $OutputScriptPath
    ## Part 3
    'aziotctl config mp --connection-string ' + "'"+ $DeviceConnectionString + "'" >> $OutputScriptPath
    'aziotctl config apply' >> $OutputScriptPath
    'systemctl enable osconfig' >> $OutputScriptPath
    'systemctl start osconfig' >> $OutputScriptPath
    #>
    (Get-Content (Join-Path $AssetsPath "install-osconfig.sh")) -replace '{{DEVICE_CONNECTION_STRING_HERE}}',$DeviceConnectionString > $OutputScriptPath
}

function Remove-DemoResources{
    param(
        $DemoEnvironmentName,
        $IoTHubName,
        $ResourceGroupName,
        $TempPath,
        $AssetsPath
    )
    $resourceFilter = $DemoEnvironmentName + '*'
    az iot hub delete --name $IoTHubName -g $ResourceGroupName
    az vm delete --yes --ids $((az vm list -g $ResourceGroupName --query "[].id" -o tsv) -like $('*' + $DemoEnvironmentName + '*'))
    az resource list | convertfrom-json | ? name -like $resourceFilter | % {az resource delete --ids $_.id}
    Get-ChildItem -Path $TempPath | Remove-Item
}

function Convert-HashTableToAzCliTagsPayload {
    param(
        [hashtable]$InputObject
    )
    $escapedDoubleQuote = '\"'
    $outputStringElements = @('{')
    foreach($kvp in $InputObject.GetEnumerator()){
        $outputStringElements += $escapedDoubleQuote
        $outputStringElements += $kvp.key
        $outputStringElements += $escapedDoubleQuote
        $outputStringElements += ':'
        $outputStringElements += $escapedDoubleQuote
        $outputStringElements += $kvp.Value
        $outputStringElements += $escapedDoubleQuote
    }
    $outputStringElements += @('}')
    $outputStringElements -join ''
}

function Test-DemoDeviceHasActiveOSConfigModule {
    param(
        $IoTHubName,
        $DeviceId
    )
    [object[]]$modules = az iot hub module-identity list --device-id $DeviceId --hub-name $IoTHubName | ConvertFrom-Json
    if ($null -eq $modules -or $modules.Count -eq 0){
        return $false
    }
    $osconfigModule = $modules | Where-Object { $_.moduleId -eq 'osconfig'}
    if($null -eq $osconfigModule -or $osconfigModule.connectionState -ne 'Connected'){
        return $false
    }
    return true
}