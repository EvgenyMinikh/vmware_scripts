function Add-NewVLANtoDatacenter {
    param (
        [Parameter(Mandatory=$true)] $VLAN_Name,
        [Parameter(Mandatory=$true)] $VLAN_ID,
        [Parameter(Mandatory=$true)] $vSwitchName,
        [Parameter(Mandatory=$true)] $DataCenter
    )
    Get-Datacenter -Name $DataCenter | Get-VMHost | Get-VirtualSwitch -name $vSwitchName | New-VirtualPortGroup -Name $VLAN_Name -VLanId $VLAN_ID
}

$cred = Get-Credential
$vCenter = '#vCenter Name to connect to'
$vSwitchName = '#VSwitch name where to add a new VLAN'
$datacenter = '#Datacenter Name'

$newVLANID = #VLAN Number
$newVLANName = '#New VLAN Name'

Connect-VIServer -Server $vCenter -Credential $cred

Add-NewVLANtoDatacenter -VLAN_Name $newVLANName -VLAN_ID $newVLANID -vSwitchName $vSwitchName -DataCenter $datacenter

Disconnect-VIServer -Confirm:$false