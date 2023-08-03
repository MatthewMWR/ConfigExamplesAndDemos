param(
    $DemoEnvName = "QuickStart-" + (Get-Random -min 1000 -max 9999),
    $Count = 1,
    $AzureLocationPool = @("westus3","westus3","westus3","westus2","eastus","eastus2","southcentralus","centralus"),
    $Size = "Standard_B1s"
)

$ErrorActionPreference = "Stop"

$resourceGroupForVM = $DemoEnvName + "_VM"

if( $null -eq $(Get-AzResourceGroup -Name $resourceGroupForVM -ErrorAction SilentlyContinue)){
    New-AzResourceGroup -Name $resourceGroupForVM -Location "westus3"
}

$existingDeviceCount = 0
foreach( $tempDeviceObj in $(Get-AzIotHubDevice -ResourceGroupName $DemoEnvName -IotHubName $DemoEnvName -ErrorAction SilentlyContinue ))
{
    if( $tempDeviceObj.Id -match 'device\d{2}') {
        $existingDeviceCount++
    }
}
$StartAt = $existingDeviceCount + 1

#$StartAt..($StartAt + $Count - 1) | ForEach-Object {
$StartAt..($StartAt + $Count - 1) | Start-RSJob -VariablesToImport DemoEnvName,resourceGroupForVM,Size,AzureLocationPool -ScriptBlock {
    $deviceNumber = $_
    $vmInfo = [pscustomobject]@{
        deviceId = "device" + $deviceNumber.tostring('D2')
        vmPublicIpIfPresent = ""
        vmCommandStatus = ""
        location = ""
        tagsHt = ""
        tagsString = ""
    }

    $vmInfo.tagsHt = $(
        if( $deviceNumber -lt 3 -or $deviceNumber % 2 -eq 0){
            @{siteName = "Munich"; siteType= "gen1"}
        }
        else{
            @{siteName = "Berlin"; siteType = "gen2"}
        }
    )

    $vmInfo.tagsString = ($vmInfo.tagsHt.GetEnumerator() | Foreach-Object { $_.Name + '=' + $_.Value }) -join ' '

    $vmInfo.location = Get-Random -InputObject $AzureLocationPool

    $iotHubDeviceParams =@{
        ResourceGroupName = $DemoEnvName
        IoTHubName = $DemoEnvName
        DeviceId = $vmInfo.deviceId
    }
    if( -not $(Get-AzIoTHubDevice @iotHubDeviceParams)){
        $null = Add-AzIotHubDevice @iotHubDeviceParams
    }
    $null = Update-AzIotHubDeviceTwin @iotHubDeviceParams -Tag $vmInfo.tagsHt
    $connectionString = Get-AzIotHubDeviceConnectionString @iotHubDeviceParams
    $vmObject = Get-AzVM -ResourceGroupName $resourceGroupForVM -Name $vmInfo.deviceId -ErrorAction SilentlyContinue
    
    if( $null -eq $vMObject ){
        # Public IPs are useful for examples and troubleshooting, but are subject to
        # quota limits. Giving every 3rd VM a public IP
        if( $deviceNumber % 3 -eq 0){
            $vmInfo.vmPublicIpIfPresent = az vm create -g $resourceGroupForVM -n $vmInfo.deviceId --size $Size --storage-sku Standard_LRS --location $vmInfo.location --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest" --generate-ssh-key --public-ip-sku Basic --public-ip-address-allocation dynamic --query publicIpAddress
        }
        else{
            $vmInfo.vmPublicIpIfPresent = az vm create -g $resourceGroupForVM -n $vmInfo.deviceId --size $Size --storage-sku Standard_LRS --location $vmInfo.location --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest" --generate-ssh-key --public-ip-sku Basic --public-ip-address "" --query name
        }
    }
    $connectionStringString = "'" + $connectionString.ConnectionString + "'"
    $vmCommandStatusRaw = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupForVM -VMName $vmInfo.deviceId -CommandId 'RunShellScript' -Parameter @{"1"=$connectionStringString} -ScriptString @'
#!/bin/bash
touch /var/log/my-lab-setup.log
echo "A" >> /var/log/my-lab-setup.log
echo "B" 2>&1 | tee -a /var/log/my-lab-setup.log
apt-get update 2>&1 | tee -a /var/log/my-lab-setup.log
curl -sSL https://packages.microsoft.com/keys/microsoft.asc -o /etc/apt/trusted.gpg.d/pkgs-msft-key.asc
curl -sSL https://packages.microsoft.com/config/ubuntu/20.04/prod.list -o /etc/apt/sources.list.d/pkgs-msft-prod.list
apt-get update 2>&1 | tee -a /var/log/my-lab-setup.log
apt-get install -y aziot-identity-service 2>&1 | tee -a /var/log/my-lab-setup.log
aziotctl config mp --connection-string "$1" --force 2>&1 | tee -a /var/log/my-lab-setup.log
aziotctl config apply 2>&1 | tee -a /var/log/my-lab-setup.log
aziotctl check 2>&1 | tee -a /var/log/my-lab-setup.log
apt-get install -y osconfig 2>&1 | tee -a /var/log/my-lab-setup.log
sleep 5s
systemctl status osconfig 2>&1 | tee -a /var/log/my-lab-setup.log
sleep 5s
systemctl status osconfig 2>&1 | tee -a /var/log/my-lab-setup.log
echo "C" 2>&1 | tee -a /var/log/my-lab-setup.log
'@ 
    $vmInfo.vmCommandStatus = $vmCommandStatusRaw | Foreach-Object { $_.Status }
    Start-Sleep -Seconds 5
    $null = Update-AzIotHubModuleTwin -ResourceGroupName $DemoEnvName -IoTHubName $DemoEnvName -DeviceId $vmInfo.deviceId -ModuleId "osconfig" -Tag $vmInfo.tagsHt
    $vmInfo
} | Wait-RSJob | Receive-RSJob

#foreach($device in (Get-AzIoTHubDevice -IotHubName $DemoEnvName -ResourceGroupName $DemoEnvName)){
#    $deviceTwin = Get-AzIotHubDeviceTwin -ResourceGroupName $DemoEnvName -IoTHubName $DemoEnvName -DeviceId $device.Id
#    $tagsBackToHt = @{}
#    $deviceTwin.Tags | Foreach-Object { $tagsBackToHt[$_.Key] = $_.Value } -ErrorAction Continue
#    $null = Update-AzIotHubModuleTwin -ResourceGroupName $DemoEnvName -IoTHubName $DemoEnvName -DeviceId $device.Id -ModuleId "osconfig" -Tag $tagsBackToHt
#}