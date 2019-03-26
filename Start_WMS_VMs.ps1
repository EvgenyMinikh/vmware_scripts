cls
# Список машин для проверки состояния. При необходимости добавить или удалить машину руками.
$VMs = @("ru1ra69", "ru1ra70", "ru1ra71", "ru1rx11", "ru1rx12", "ru1rx13")

function Get-VMPowerStatus {
# Функция выводит состояние питания каждой машины из списка
    foreach($VM in $VMs) {
        $vmState = if ((Get-VM -Name $VM).PowerState -eq "PoweredOn") {"ON"} else {"OFF"}
        $msg = "$VM `t.........`t $vmState"
    
        Switch ($vmState) {
            "ON" { Write-Host $msg -ForegroundColor green }
            "OFF" {  Write-Host $msg -ForegroundColor red }
        }
    }
    Write-Host ("="*30)
}

$cred = Get-Credential
Connect-VIServer -Server fi1vcsa01 -Credential $cred

Get-VMPowerStatus

Start-VM -VM ru1ra69 -Confirm:$false | Out-Null
Start-Sleep -Seconds 10

Start-VM -VM ru1ra70 , ru1ra71 -Confirm:$false | Out-Null
Start-Sleep -Seconds 10

Start-VM -VM ru1rx11 , ru1rx12 , ru1rx13 -Confirm:$false | Out-Null

Get-VMPowerStatus
Disconnect-VIServer -Confirm:$false