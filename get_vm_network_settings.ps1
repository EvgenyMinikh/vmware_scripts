$Cred = Get-Credential
Connect-VIServer -Server fi1vcsa01 -Credential $Cred

#$vm_list_path = "C:\Users\eminih\Desktop\vm_list.txt"

$vms = Get-Datacenter ru1 | Get-VMHost | Get-VM | where {$_.PowerState -eq 'PoweredOn'}
#$vms = Get-Content -Path $vm_list_path

$result_file = "C:\Users\eminih\Desktop\vms_with_net_settings.csv"

if (Test-Path -Path $result_file) {
    Remove-Item -Path $result_file
}

foreach ($vm in $vms) {
    $result = ''
    #$vm = Get-VM -Name $vm
    $subnetmask = @()
    $row = "" | Select OS, Name,IP,Gateway,Subnetmask,DNS
    $row.Name = $vm.Name
    $row.IP = [string]::Join(',',$vm.Guest.IPAddress)
    $row.Gateway = $vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute.Gateway.IpAddress | where {$_ -ne $null}
    $row.OS = $vm.Guest.OSFullName

    foreach ($iproute in $vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute) {
        if (($vm.Guest.IPAddress -replace "[0-9]$|[1-9][0-9]$|1[0-9][0-9]$|2[0-4][0-9]$|25[0-5]$", "0" | select -uniq) -contains $iproute.Network) {
            $subnetmask += $iproute.Network + "/" + $iproute.PrefixLength
        }

    }

    $row.Subnetmask = [string]::Join(',',($subnetmask))
    $row.DNS = [string]::Join(',',($vm.ExtensionData.Guest.IpStack.DnsConfig.IpAddress))

    $result = "{0};{1};{2};{3};{4};{5}" -f $row.OS, $row.Name, $row.IP, $row.Subnetmask, $row.Gateway, $row.DNS
    $result | Out-File -FilePath $result_file -Append
}

Disconnect-VIServer -Confirm:$false