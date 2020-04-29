$DatacenterName = 'ru1'
$VMHosts = @('vmware114.group.ad',
'vmware115.group.ad',
'vmware117.group.ad',
'vmware118.group.ad',
'vmware127.group.ad',
'vmware126.group.ad',
'vmware128.group.ad',
'vmware122.group.ad',
'vmware125.group.ad',
'vmware120.group.ad',
'vmware121.group.ad',
'vmware123.group.ad',
'vmware124.group.ad')

$Cred = Get-Credential -Message 'Creds to connect to vCenter'
$CommonCred = Get-Credential -Message 'Creds without domain'

#Connect-VIServer -Server fi1vcsa01 -Credential $Cred

foreach ($VMHost in $VMHosts) {
    
    $ScriptBlock = {
        Param($VMHost, $Cred, $CommonCred)

        Connect-VIServer -Server fi1vcsa01 -Credential $Cred

        $outputfile = "c:\temp\$VMHost.txt"
        Remove-Item -Path $outputfile -Force -ErrorAction Ignore

        $vms = Get-VMHost -Name $VMHost | get-vm | where {($_.PowerState -eq 'PoweredOn') -and ($_.Guest -like '*windows*')}
        #$ScriptForVM = 'Get-Service | Where-Object {$_.Name -like "*SQL*"} | Select-Object -Property Status, Name | ft -AutoSize'
        $ScriptForVM = 'net start | find /i "SQL"'

        foreach($vm in $vms) {
            $vmdetails = Get-VM -Name $vm

            $vmpowerstate = $vmdetails.PowerState
            if ($vmpowerstate -eq 'PoweredOff') {continue}

            $OSVersion = $vmdetails.Guest.OSFullName
            if ($OSVersion -notlike '*Windows*') {continue}

            $vmname = $vmdetails.Name
            $vmhost = $vmdetails.VMHost.Name
            $cluster = $vmdetails.VMHost.Parent.Name

            #$output = (Invoke-VMScript -VM $vm -ScriptText $ScriptForVM -ScriptType Powershell -GuestCredential $CommonCred -ErrorAction Ignore).ScriptOutput
            $output = (Invoke-VMScript -VM $vm -ScriptText $ScriptForVM -ScriptType Bat -GuestCredential $CommonCred -ErrorAction Ignore).ScriptOutput
            if ($output.Length -eq 0) {continue}

            $result = "=====`r`n{0}`r`n{1}`r`n{2}`r`n{3}`r`n{4}`r`n*****" -f $vmname, $OSVersion, $cluster, $vmhost, $output
    
            Out-File -InputObject $result -FilePath $outputfile -Append
        }
        
        Disconnect-VIServer -Confirm:$false
    }

    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $VMHost, $Cred, $CommonCred
}

Disconnect-VIServer -Confirm:$false

Get-Job | Remove-Job -Force