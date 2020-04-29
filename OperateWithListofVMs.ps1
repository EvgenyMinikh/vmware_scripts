function Get-ListofAllVMsonHost {
    param (
        $VMHostName,
        $VMLogPath,
        $PowerState = 'PoweredOn'
    )

    $VMs = Get-VMHost -Name $VMHostName | Get-VM | where {$_.PowerState -eq $PowerState} | Select -ExpandProperty Name
    $VMs | Out-File -FilePath $VMLogPath
}

function PowerOff-VMs {
    param (
        $VMListPath
    )

    $VMList = Get-Content $VMListPath

    foreach ($VM in $VMList) {
        
        if ($VM.length -le 1) {
            continue
        }
        
        $PowerState = (Get-VM $VM).PowerState
        
        if ($PowerState -eq 'PoweredOff') {
            continue
        }

        Shutdown-VMGuest -VM $VM -Confirm:$false
    }
}

function PowerOn-VMs {
    param (
        $VMListPath
    )

    $VMList = Get-Content $VMListPath

    foreach ($VM in $VMList) {
        
        if ($VM.length -le 1) {
            continue
        }

        $PowerState = (Get-VM $VM).PowerState
        
        if ($PowerState -eq 'PoweredOn') {
            continue
        }

        Start-VM $VM -RunAsync -Confirm:$false
    }
}

function Check-VMPowerstate {
    param (
        $VMListPath,
        $PreviousAction = 'Power Off',
        $ForceShutdown = 'No'
    )
    
    $ColorforPoweredOn = 'Green'
    $ColorforPoweredOff = 'Red'

    if ($PreviousAction -eq 'Power Off') {
        $ColorforPoweredOn = 'Red'
        $ColorforPoweredOff = 'Green'
    }

    if ($PreviousAction -eq 'Power On') {
        $ColorforPoweredOn = 'Green'
        $ColorforPoweredOff = 'Red'
    }

    $VMList = Get-Content $VMListPath
    
    foreach ($VM in $VMList) {
        $PowerState = (Get-VM $VM).PowerState
        
        if ($PowerState -eq 'PoweredOff') {
            Write-Host "$VM Powered Off" -ForegroundColor $ColorforPoweredOff
        }

        if ($PowerState -eq 'PoweredOn') {
            Write-Host "$VM Powered On" -ForegroundColor $ColorforPoweredOn

            if (($PreviousAction -eq 'Power Off') -and ($ForceShutdown -eq 'Yes')) {
                Stop-VM -VM $VM -RunAsync -Confirm:$false
            }
        }
    }
}


$Cred = Get-Credential
Connect-VIServer -Server fi1vcsa01 -Credential $Cred
<#
$Hosts = @('vmware114.group.ad','vmware115.group.ad','vmware117.group.ad','vmware118.group.ad')

foreach ($VMHost in $Hosts) {
    Get-ListofAllVMsonHost -VMHostName $VMHost -VMLogPath "C:\vmware\$($VMHost.Split('.')[0]).txt" -PowerState 'PoweredOn'
}
#>
$vmlist = "C:\vmware\xmit.txt"

#PowerOff-VMs -VMListPath $vmlist
#Check-VMPowerstate -VMListPath $vmlist -PreviousAction 'Power Off'
#Check-VMPowerstate -VMListPath $vmlist -PreviousAction 'Power Off' -ForceShutdown 'Yes'
PowerOn-VMs -VMListPath $vmlist
Check-VMPowerstate -VMListPath $vmlist -PreviousAction 'Power On'

#Disconnect-VIServer -Confirm:$false