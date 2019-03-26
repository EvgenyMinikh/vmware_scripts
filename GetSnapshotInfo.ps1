$Cred = Get-Credential
Connect-VIServer -Server fi1vcsa01 -Credential $Cred
Get-VM -Location ru1 | Get-Snapshot | Select-Object VM, Name, Created, @{l='SizeGB'; e={[math]::Round(($_.SizeGB),2)}} | Sort-Object -Descending -Property SizeGB | Format-Table -AutoSize | Out-File c:\temp\snapshots.txt
Disconnect-VIServer