param(
    [switch]$Loop,
    [int]$LoopDelaySeconds = 5,
    $TenantIdForDestinationAuth = "d52246e2-06ff-483a-8b1f-8ee9d81f76cb",
    $AppIdForDestinationAuth = "1082e8d3-b4f5-40fb-8f1a-a49a1fa7b2b8",
    $AppSecretForDestinationAuth = "HDB8Q~Z.V~vKCD4Teo8frsAsgQd~~Zi.lYocAbSa",
    $DataCollectionEndpointForDestination = "https://tempdatacollectionendpoint-nnb7.westus2-1.ingest.monitor.azure.com", 
    $IoTHubName = "OSCDemo-277",
    $IoTHubResourceGroupName = "OSCDemo-277",
    $IoTHubSasToken='SharedAccessSignature sr=OSCDemo-277.azure-devices.net&sig=l5JBYH4TDSN1Ekin5OhZuH7WDmbRFUOj7h2ygooydiU%3D&skn=iothubowner&se=1670864970',
    $IoTHubFqdn = "OSCDemo-277.azure-devices.net",
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
)

$ErrorActionPreference = "Stop"


#region function definitions
############################
function Get-RjDeviceTwin {
    param(
        [Parameter(Mandatory)]
        [string]$IoTHubSasToken, 
        $DeviceId
    )
    
    $fqdn = Get-IoTHubFqdnFromSasToken -IoTHubSasToken $IoTHubSasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $IoTHubSasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}
    
function Get-IoTHubFqdnFromSasToken {
    param(
        [Parameter(Mandatory)]
        [string]$IoTHubSasToken
    )
    if( $IoTHubSasToken -match 'sr=([^\.]*\.azure-devices\.net)'){
        $Matches[1]
    }
    else{
        throw "Could not extract fqdn from sas token"
    }
}
    
function Get-RjModuleTwinsAll {
    param(
        [Parameter(Mandatory)]
        [string]$IoTHubSasTokens, 
        $DeviceIds = @(), 
        $ModuleName = "osconfig"
    )
    
    if( $DeviceIds.Count -eq 0){
        $DeviceIds = @(
            Get-RjDevices -IoTHubSasToken $IoTHubSasToken | 
            ConvertFrom-Json | 
            Foreach-Object { $_.deviceId }
        )
    }
    
    $twins= @(
        $deviceIds | 
        Foreach-Object { Get-RjModuleTwin -IoTHubSasToken $IoTHubSasToken -DeviceId $_ -ModuleName $ModuleName}
    )
    '[' + ( $twins -join ',' ) + ']'
}
    
function Get-RjDevices {
    param(
        [Parameter(Mandatory)]
        [string]$IoTHubSasToken
    )
    
    $fqdn = Get-IoTHubFqdnFromSasToken -IoTHubSasToken $IoTHubSasToken
    $restUri = "https://$fqdn/devices?api-version=2020-05-31-preview"
    $headers = @{ Authorization = $IoTHubSasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}
    
function Get-RjModuleTwin {
    param(
        [Parameter(Mandatory)]
        [string]$IoTHubSasToken, 
        $DeviceId, 
        $ModuleName = "osconfig"
    )
    
    $fqdn = Get-IoTHubFqdnFromSasToken -IoTHubSasToken $IoTHubSasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID/modules/$($ModuleName)?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $IoTHubSasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

#endregion function definitions
###############################

#$__perfTest__initialTimestamp = Get-Date

#region execution
##############################

$headersForSasRestCall =@{
    Authorization = $IoTHubSasToken
    'Content-Type' = 'application/json'
}
$uriForConfigurations = "https://$IoTHubFqdn/configurations?api-version=2020-05-31-preview"

#[pscustomobject]@{location = "AA" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

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
        $body = "client_id=$AppIdForDestinationAuth&scope=$scope&client_secret=$AppSecretForDestinationAuth&grant_type=client_credentials";
        $headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
        $uri = "https://login.microsoftonline.com/$TenantIdForDestinationAuth/oauth2/v2.0/token"
        $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
    }

    if(((Get-Date) - $deviceListLastUpdate).TotalSeconds -gt $deviceListRefreshAfterSeconds){
        $deviceList = Get-AzIoTHubDevice -IoTHubName $IoTHubName -ResourceGroupName $IoTHubResourceGroupName
    }
    $headersForDataIngestion = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" };
    $timestampForThisRun = Get-Date -Format o
    $bodyForDataIngestion = ''

    #[pscustomobject]@{location = "CC" ; secondsElapsed = ((Get-Date) - $__perfTest__initialTimestamp).TotalSeconds}

    foreach($set in $IngestionSets){
        if ( $set.SetName -eq "DeviceTwins" -and $set.Enabled ){
            $items = @()
            $deviceList | Foreach-Object {
                $items += (Get-RjDeviceTwin -IoTHubSasToken $IoTHubSasToken -DeviceId $_.Id)
            }
            $bodyForDataIngestion = ('[' + ($items -join ',') + ']') | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        elseif( $set.SetName -eq "OSConfigTwins" -and $set.Enabled ){
            $bodyForDataIngestion = Get-RjModuleTwinsAll -IoTHubSasToken $IoTHubSasToken | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        elseif( $set.SetName -eq "HubConfigs" -and $set.Enabled ){
            $bodyForDataIngestion = $(Invoke-WebRequest -Headers $headersForSasRestCall -Method Get -Uri $uriForConfigurations).Content | jq --compact-output "map(. += {`"TimeGenerated`": `"$timestampForThisRun`"})"
        }
        if( $set.SendToAzMon ){
            $uriForDataIngestion = "$DataCollectionEndpointForDestination/dataCollectionRules/$($set.DcrImmutableId)/streams/$($set.StreamName)"+"?api-version=2021-11-01-preview"
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
#endregion execution
#######################
