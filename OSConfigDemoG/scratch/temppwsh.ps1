#$tenantId = "d52246e2-06ff-483a-8b1f-8ee9d81f76cb"; #the tenant ID in which the Data Collection Endpoint resides
#$appId = "37b2dcb5-1f65-433a-8e11-033926dbb817"; #the app ID created and granted permissions
#$appSecret = "cvb8Q~1VGV3JRtmwMMI4HhWsZo3xC.er16SWicd1"
#$subscriptionId = "54ea281d-e6f7-4e09-a315-8eba4de04b2d"
#$resourceGroupName = "OSCDemo-277"
#$sasToken='SharedAccessSignature sr=OSCDemo-277.azure-devices.net&sig=RhyX9s8BKak1%2FVLOKGWzF4JkzKgItm8GktYt3ZTr%2BNQ%3D&skn=iothubowner&se=1670651441'
#$scope = [System.Web.HttpUtility]::UrlEncode("https://iothubs.azure.net/.default")
##$scope = [System.Web.HttpUtility]::UrlEncode("https://management.azure.com/.default")
#$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
#$headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
#$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
#$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
##$headersForRestCall = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" }
#$headersForRestCall = @{"Authorization" = $sasToken; "Content-Type" = "application/json" }
#
##$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Devices/IotHubs/$($resourceGroupName)?api-version=2018-04-01"
#$uri = 'https://OSCDemo-277.azure-devices.net/configurations/net_config?api-version=2020-05-31-preview'
##$bearerToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyIsImtpZCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuY29yZS53aW5kb3dzLm5ldC8iLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9kNTIyNDZlMi0wNmZmLTQ4M2EtOGIxZi04ZWU5ZDgxZjc2Y2IvIiwiaWF0IjoxNjcwNDcwNzAyLCJuYmYiOjE2NzA0NzA3MDIsImV4cCI6MTY3MDQ3NTQzNiwiYWNyIjoiMSIsImFpbyI6IkFYUUFpLzhUQUFBQUFwRGh4QmlWbnAvSk9DazQ3TUpEUHh5UTc1bVhmWDQyWUFvS2pEeDloYzA0amE0M2JlNEVIMzdhQVVRbW9aQ3pwTHVObUJZRGd1S3BNQmprVStZRzBWZG1jM25odFFDTHUxcXFkUmZUdkNBbWZkbkswM1dJRWhTclZIckw3L2xDaTEyOEZycExBMmlDWGdPY1p6cFk2QT09IiwiYWx0c2VjaWQiOiIxOmxpdmUuY29tOjAwMDM3RkZFM0UzNTQyMDEiLCJhbXIiOlsicHdkIiwibWZhIl0sImFwcGlkIjoiNWUxYmE1NGQtNDUwNC00Nzk5LTk2MDAtNmQwNWU1OGYwNjgyIiwiYXBwaWRhY3IiOiIyIiwiZW1haWwiOiJtcmV5bjJAb3V0bG9vay5jb20iLCJmYW1pbHlfbmFtZSI6IlJleW5vbGRzIiwiZ2l2ZW5fbmFtZSI6Ik1hdHRoZXciLCJncm91cHMiOlsiNTE2YTZmMzktNDY5YS00MmYzLThhMGEtMjliMjMzMDk0YzZkIl0sImlkcCI6ImxpdmUuY29tIiwiaXBhZGRyIjoiNzMuMTkzLjE4LjI0NSIsIm5hbWUiOiJNYXR0aGV3IFJleW5vbGRzIiwib2lkIjoiNmQxY2IzYjctYjRkOC00NzFmLTgyZGEtMzQ1ZTA0ZDlhZjY0IiwicHVpZCI6IjEwMDMyMDAxNENGODU2RTUiLCJyaCI6IjAuQVgwQTRrWWkxZjhHT2tpTEg0N3AyQjkyeTBaSWYza0F1dGRQdWtQYXdmajJNQk45QUdzLiIsInNjcCI6InVzZXJfaW1wZXJzb25hdGlvbiIsInN1YiI6ImxPem54bmNVTEtfNnNRSVZ6WUR4eEZFYWJFYzZTN2stOUpIdVoyaFVnOVUiLCJ0aWQiOiJkNTIyNDZlMi0wNmZmLTQ4M2EtOGIxZi04ZWU5ZDgxZjc2Y2IiLCJ1bmlxdWVfbmFtZSI6ImxpdmUuY29tI21yZXluMkBvdXRsb29rLmNvbSIsInV0aSI6IldlSGluakZIbms2UlM2YUhzVEd1QXciLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfdGNkdCI6MTYyMjkyOTQ3N30.CAhdVBCRCeGXA4Tl3cyMe3oAH7im0KbMb5ODu9jHYQOU3SuzvSaPLYU9AK3XYAgrzisRnSR181a7kpRiptwV7wOEoLjG6BDJGrNH3vVtOZIOJf5Z2l7au8m2_pDSqKm7LGfOLbB0Ag2OvhZAtT54cjSdW1jyKw-iyjSYyau0o_7w9VwIVLvXC2DbcODQYit8e8_801zUbUrBQAMUsFIZZyekBhCA4v0IQfGZBF-TK7r6W2OKV5lrYgZAv79ErsyUqzJBKG2Zv7V2Wj3KtETgFK5Cpl7goZWlDh1D5hqxsfXdXaHFiKH9zPgIh3t_zEA86lzFDFX-YQoAObx37qzD-A'
#
##$response = Invoke-RestMethod -Method Get -Headers $headersForRestCall -Uri $uri
#$response = Invoke-WebRequest -Headers $headersForRestCall -Method Get -Uri $uri
#$response.Content > tempnetconfig.txt

function Get-RjHubConfigs {
    param(
        $SasToken
    )
    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/configurations?api-version=2020-05-31-preview"
    $headers =@{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-RjModuleTwin {
    param($SasToken, $DeviceId, $ModuleName = "osconfig")

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID/modules/$($ModuleName)?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-RjDeviceTwin {
    param($SasToken, $DeviceId)

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/twins/DEVICE_ID?api-version=2020-05-31-preview" -replace "DEVICE_ID",$DeviceId
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-RjDevices {
    param($SasToken)

    $fqdn = Get-IoTHubFqdnFromSasToken -SasToken $SasToken
    $restUri = "https://$fqdn/devices?api-version=2020-05-31-preview"
    $headers = @{ Authorization = $sasToken ; 'Content-Type' = 'application/json'}
    (Invoke-WebRequest -Uri $restUri -Headers $headers -Method Get).Content
}

function Get-RjModuleTwinsAll {
    param($SasTokens, $ModuleName = "osconfig")

    $twins= @(
        Get-RjDevices -SasToken $sasToken | 
        ConvertFrom-Json | 
        Foreach-Object { Get-RjModuleTwin -SasToken $sasToken -DeviceId $_.deviceId -ModuleName $ModuleName}
    )
    '[' + ( $twins -join ',' ) + ']'
}

function Get-RjDeviceTwinsAll {
    param($SasToken)

    $twins = @(
        Get-RjDevices -SasToken $sasToken | ConvertFrom-Json | 
        Foreach-Object { Get-RjDeviceTwin -SasToken $sasToken -DeviceId $_.deviceId }
    )
    '[' + ( $twins -join ',' ) + ']'
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

$sasToken='SharedAccessSignature sr=OSCDemo-277.azure-devices.net&sig=RhyX9s8BKak1%2FVLOKGWzF4JkzKgItm8GktYt3ZTr%2BNQ%3D&skn=iothubowner&se=1670651441'

#Get-HubConfigs -SasToken $sasToken


Get-RjModuleTwinsAll -SasToken $sasToken -ModuleName osconfig



