param(
    [switch]$Loop,
    [int]$LoopDelaySeconds = 5
)

#$__perfTest__initialTimestamp = Get-Date

## information needed to authenticate to AAD and obtain a bearer token
$tenantId = "d52246e2-06ff-483a-8b1f-8ee9d81f76cb"; #the tenant ID in which the Data Collection Endpoint resides
$appId = "1082e8d3-b4f5-40fb-8f1a-a49a1fa7b2b8"; #the app ID created and granted permissions
$appSecret = "T1d8Q~bjIywbfxMFNNHCnMRPGriHg2q.alyE3bhD"; #the secret created for the above app - never store your secrets in the source code
#$DcrImmutableId = "dcr-2f851f422e364f308a60ead984a95c41" 
$DceURI = "https://tempdatacollectionendpoint-nnb7.westus2-1.ingest.monitor.azure.com" 
#$Table = "OSConfigTwins2_CL"
$IoTHubName = "OSCDemo-277"
$ResourceGroupName = "OSCDemo-277"
$sasToken='SharedAccessSignature sr=OSCDemo-277.azure-devices.net&sig=NMLLvttJ7oB9R2G7n2w2b9i889wHt7ujhUkgAL%2BtaSI%3D&se=1691097989&skn=iothubowner'
$headersForSasRestCall =@{
    Authorization = $sasToken
    'Content-Type' = 'application/json'
}
$uriForConfigurations = 'https://OSCDemo-277.azure-devices.net/configurations?api-version=2020-05-31-preview'
#$uriForModuleTwin = 'https://OSCDemo-277.azure-devices.net/twins/DEVICE_ID/modules/osconfig?api-version=2020-05-31-preview'

function Get-RjDeviceTwin {
    param($SasToken, $DeviceId)

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-IoTHubFqdnFromSasToken {
    param($SasToken)
    if( $sasToken -match 'sr=([^\.]*\.azure-devices\.net)'){
        $Matches[1]
    }
    else{
        throw "Could not extract fqdn from sas token"
    }
}

function Get-RjModuleTwinsAll {
    param($SasTokens, $DeviceIds = @(), $ModuleName = "osconfig")

    if( $DeviceIds.Count -eq 0){
        $DeviceIds = @(Get-RjDevices -SasToken $sasToken | 
        ConvertFrom-Json | 
        Foreach-Object { $_.deviceId })
    }

    $twins= @(
        $deviceIds | 
        Foreach-Object { Get-RjModuleTwin -SasToken $sasToken -DeviceId $_ -ModuleName $ModuleName}
    )
    '[' + ( $twins -join ',' ) + ']'
}

function Get-RjDevices {
    param($SasToken)

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/devices?api-version=2020-05-31-preview"
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-RjModuleTwin {
    param($SasToken, $DeviceId, $ModuleName = "osconfig")

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID/modules/$($ModuleName)?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

#[pscustomobject]@{location = "AA" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

$IngestionSets = (
    @{
        SetName = "DeviceTwins"
        DcrImmutableId = "dcr-8c50d73781d246228faff383222ab2f3"
        TableName = "DeviceTwins_CL"
        StreamName = "Custom-DeviceTwins_CL"
        SendToAzMon = $true
        SendToFile = $true
        Enabled = $true
    },
    @{
        SetName = "OSConfigTwins"
        DcrImmutableId = "dcr-2f851f422e364f308a60ead984a95c41" 
        TableName = "OSConfigTwins2_CL"
        StreamName = "Custom-OSConfigTwins2_CL"
        SendToAzMon = $true
        SendToFile = $true
        Enabled = $true
    },
    @{
        SetName = "HubConfigs"
        DcrImmutableId = "dcr-8c50d73781d246228faff383222ab2f3"
        TableName = "HubConfigs_CL"
        StreamName = "Custom-HubConfigs_CL"
        SendToAzMon = $true
        SendToFile = $true
        Enabled = $true
    }
)

$tokenLastUpdate = Get-Date 0
$tokenRefreshAfterSeconds = 300
$deviceListLastUpdate = Get-Date 0
$deviceListRefreshAfterSeconds = 60

#[pscustomobject]@{location = "BB" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

[bool]$keepGoing=$true
while($keepGoing){
    if(((Get-Date) - $tokenLastUpdate).TotalSeconds -gt $tokenRefreshAfterSeconds){
        ## Obtain a bearer token used to authenticate against the data collection endpoint
        $scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
        $body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
        $headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
        $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
        $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
    }

    if(((Get-Date) - $deviceListLastUpdate).TotalSeconds -gt $deviceListRefreshAfterSeconds){
        $deviceList = Get-AzIoTHubDevice -IoTHubName $IoTHubName -ResourceGroupName $ResourceGroupName
    }
    $headersForDataIngestion = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" };
    $timestampForThisRun = Get-Date -Format o
    $bodyForDataIngestion = ''

    #[pscustomobject]@{location = "CC" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

    foreach($set in $IngestionSets){
        if ( $set.SetName -eq "DeviceTwins" -and $set.Enabled ){
            $items = @()
            $deviceList | Foreach-Object {
                $items += (Get-RjDeviceTwin -SasToken $sasToken -DeviceId $_.Id)
            }
            $bodyForDataIngestion = ('[' + ($items -join ',') + ']') | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        elseif( $set.SetName -eq "OSConfigTwins" -and $set.Enabled ){
            $bodyForDataIngestion = Get-RjModuleTwinsAll -SasToken $sasToken | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        elseif( $set.SetName -eq "HubConfigs" -and $set.Enabled ){
            $bodyForDataIngestion = $(Invoke-WebRequest -Headers $headersForSasRestCall -Method Get -Uri $uriForConfigurations).Content | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        if( $set.SendToAzMon ){
            $uriForDataIngestion = "$DceURI/dataCollectionRules/$($set.DcrImmutableId)/streams/$($set.StreamName)"+"?api-version=2021-11-01-preview"
            $null = Invoke-WebRequest -Uri $uriForDataIngestion -Method "Post" -Body $bodyForDataIngestion -Headers $headersForDataIngestion
        }
        if( $set.SendToFile ){
            $filePath = Join-Path "/var/tmp" "$($set.SetName).json"
            $bodyForDataIngestion > $filePath
        }
        #[pscustomobject]@{location = "DD" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}
    }
    #[pscustomobject]@{location = "EE" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

    Start-Sleep -Seconds $LoopDelaySeconds
    $keepGoing=$Loop.IsPresent
}














#    $uriForDataIngestion = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table"+"?api-version=2021-11-01-preview";
# 
#    $timestampForThisRun = Get-Date -Format o
#    $deviceTwins = @()
#    $deviceTwins = $deviceList | Start-RSJob -ScriptBlock {
#        az iot hub device-twin show -g $Using:ResourceGroupName -n $Using:IoTHubName -d $_.Id | jq --compact-output ". += {`"TimeGenerated`": `"$Using:timestampForThisRun`"}"
#    } | Wait-RSJob | Receive-RSJob
#    $bodyForDataIngestion = '[' + ($deviceTwins -join ',') + ']'
#    $bodyForDataIngestion > /var/tmp/devicetwins.json
#    $null = Invoke-RestMethod -Uri $uriForDataIngestion -Method "Post" -Body $bodyForDataIngestion -Headers $headersForDataIngestion
#    $deviceTwins = $null
#
#    $moduleTwins = @()
#    $moduleTwins = $deviceList | Start-RSJob -ScriptBlock {
#        az iot hub module-twin show -g $Using:ResourceGroupName -n $Using:IoTHubName -d $_.Id -m "osconfig" | jq 'del(.properties.reported."$metadata") | del(.properties.desired."$metadata")' | jq --compact-output ". += {`"TimeGenerated`": `"$Using:timestampForThisRun`"}"
#    } | Wait-RSJob | Receive-RSJob
#    $bodyForDataIngestion = '[' + ($moduleTwins -join ',') + ']'
#    $null = Invoke-RestMethod -Uri $uriForDataIngestion -Method "Post" -Body $bodyForDataIngestion -Headers $headersForDataIngestion
#    $i++
#    Start-Sleep -Seconds 10
#    #$keepGoing=$false
#}
