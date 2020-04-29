function Edit-VSwitch {
    param (
        $sourceHostString,
        $destinationHostString,
        $sourceSwitchString,
        $destinationSwitchString,
        $destinationSwithToEditString
    )
    
    $destinationHost = get-vmhost $destinationHostString
    $sourceHost = get-vmhost $sourceHostString
        
    $srcSwitch = get-vmhost $sourceHost | get-virtualswitch -name $sourceSwitchString -errorAction silentlycontinue
    $destinationSwitch = get-vmhost $destinationHostString | get-virtualswitch -name $destinationSwitchString -errorAction silentlycontinue
    $destinationSwithToEdit = get-vmhost $destinationHostString | get-virtualswitch -name $destinationSwithToEditString -errorAction silentlycontinue

    $srcSwitchPortgroups = $srcSwitch | get-virtualportgroup
    $PortgroupsToRemoveStrings = $srcSwitch | get-virtualportgroup | Select -ExpandProperty Name
    $editedSwitchPortgroups = $destinationSwithToEdit | Get-VirtualPortGroup
    $destinationSwithToEditPortgroups = $destinationSwithToEdit | Get-VirtualPortGroup

    foreach ($pg in $destinationSwithToEditPortgroups) {
        $pgName = $pg.Name

        if ($PortgroupsToRemoveStrings.Contains($pgName)) {
            Remove-VirtualPortGroup $pg -Confirm:$false
        }
    }

    foreach ($pg in $srcSwitchPortgroups) {
        $pgName = $pg.Name
        $pgVLANID = $pg.VLanId
        New-VirtualPortGroup -Name $pgName -VirtualSwitch $destinationSwitch -VLanId $pgVLANID
    }
}


$sourceHostString = "vmware124.group.ad"
$destinationHostString = "vmware122.group.ad"
$sourceSwitchString = "vSwitch2"
$destinationSwitchString = "vSwitch2"
$destinationSwithToEditString = "vSwitch0"

$cred = Get-Credential
$vCenter = "fi1vcsa01"
Connect-VIServer -Server $vCenter -Credential $cred

Edit-VSwitch    -sourceHostString $sourceHostString `
                -destinationHostString $destinationHostString `
                -sourceSwitchString $sourceSwitchString `
                -destinationSwitchString $destinationSwitchString `
                -destinationSwithToEditString $destinationSwithToEditString

Disconnect-VIServer -Confirm:$false