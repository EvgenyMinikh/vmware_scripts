$Cred = Get-Credential
Connect-VIServer -Server fi1vcsa01 -Credential $Cred

$VMS = Get-VM -Location ru1 |
        where {$_.powerstate -ne "PoweredOff" } |
        where {$_.Guest.ToolsVersionStatus -ne "guestToolsCurrent"} |
        % { get-view $_.id } |
        select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}}, @{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}

$Results = $VMS | where {($_.ToolStatus -ne "guestToolsCurrent") -and `
                    ($_.ToolStatus -ne "guestToolsUnmanaged") -and `
                    ($_.Name -notlike '*ru1rl*') -and `
                    ($_.Name -notlike 'rufdc*') -and `
                    ($_.Name -notlike 'ru1dc*') -and `
                    ($_.Name -notlike 'rupbx*') -and `
                    ($_.Name -notlike 'ru1rs03')}

foreach ($vm in $Results) {
    Write-Host $vm
    Update-Tools -VM $vm.Name -RunAsync -NoReboot
}

<#foreach ($vm in $Results) {
    Restart-VM -VM $vm.Name -RunAsync -Confirm:$false
}#>

Disconnect-VIServer -Confirm:$false

<#
Update-Tools -VM pesmel11 -RunAsync -NoReboot
Update-Tools -VM pesmel9 -RunAsync -NoReboot
Update-Tools -VM vmpesmel5 -RunAsync -NoReboot
Update-Tools -VM vmpesmel3 -RunAsync -NoReboot
Update-Tools -VM vmpesmel1 -RunAsync -NoReboot
Update-Tools -VM vmpesmel7 -RunAsync -NoReboot
Update-Tools -VM pesmel13 -RunAsync -NoReboot
#>