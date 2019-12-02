$vCenterName = 'fi1vcsa01'
$FolderToObserveVMs = 'UI'

$creds = Get-Credential -Message "Enter your credentials"
Connect-VIServer -Server $vCenterName -Credential $creds

function Get-UIVMs {
    param (
        $Folder
    )
    
    $vms = Get-Folder -Name $Folder | Get-VM
    $vmList = @()

    foreach($vm in $vms) {
        $ipArray = @()
        $IPs = $vm.Guest.IPAddress
        
        foreach ($ip in $IPs) {
            if ($ip -match ':') {
                continue
            } else {
                $ipArray += $ip
            }
        }
        
        $properties = @{
            vmName = $vm.Name
            PowerState = $vm.PowerState
            IPAddresses = $ipArray
        }
        $o = New-Object -TypeName psobject -Property $properties
        $vmList += $o
    }
    return $vmList
}


function Create-VMList {
    $ListView.Items.Clear()
    $ListView.Columns.Clear()
    
    $ListView.Columns.Add('vmName') | Out-Null
    $ListView.Columns.Add('PowerState') | Out-Null
    $ListView.Columns.Add('IPAddresses') | Out-Null

    $vms = Get-UIVMs -Folder $FolderToObserveVMs

    foreach($vm in $vms) {
        $listViewItem = New-Object System.Windows.Forms.ListViewItem($vm.vmName)
        $listViewItem.SubItems.Add("$($vm.PowerState)") | Out-Null
        $listViewItem.SubItems.Add("$($vm.IPAddresses)") | Out-Null

        $ListView.Items.Add($listViewItem) | Out-Null
    }
    
    $ListView.AutoResizeColumns("HeaderSize")
}


function Sort-ListViewColumn 
{
    <#
    .SYNOPSIS
        Sort the ListView's item using the specified column.

    .DESCRIPTION
        Sort the ListView's item using the specified column.
        This function uses Add-Type to define a class that sort the items.
        The ListView's Tag property is used to keep track of the sorting.

    .PARAMETER ListView
        The ListView control to sort.

    .PARAMETER ColumnIndex
        The index of the column to use for sorting.
        
    .PARAMETER  SortOrder
        The direction to sort the items. If not specified or set to None, it will toggle.
    
    .EXAMPLE
        Sort-ListViewColumn -ListView $listview1 -ColumnIndex 0
#>
    param(    
            [ValidateNotNull()]
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.ListView]$ListView,
            [Parameter(Mandatory=$true)]
            [int]$ColumnIndex,
            [System.Windows.Forms.SortOrder]$SortOrder = 'None')
    
    if(($ListView.Items.Count -eq 0) -or ($ColumnIndex -lt 0) -or ($ColumnIndex -ge $ListView.Columns.Count))
    {
        return;
    }
    
    #region Define ListViewItemComparer
        try{
        $local:type = [ListViewItemComparer]
    }
    catch{
    Add-Type -ReferencedAssemblies ('System.Windows.Forms') -TypeDefinition  @" 
    using System;
    using System.Windows.Forms;
    using System.Collections;
    public class ListViewItemComparer : IComparer
    {
        public int column;
        public SortOrder sortOrder;
        public ListViewItemComparer()
        {
            column = 0;
            sortOrder = SortOrder.Ascending;
        }
        public ListViewItemComparer(int column, SortOrder sort)
        {
            this.column = column;
            sortOrder = sort;
        }
        public int Compare(object x, object y)
        {
            if(column >= ((ListViewItem)x).ListView.Columns.Count ||
                column >= ((ListViewItem)x).SubItems.Count ||
                column >= ((ListViewItem)y).SubItems.Count)
                column = 0;
        
            if(sortOrder == SortOrder.Ascending)
                return String.Compare(((ListViewItem)x).SubItems[column].Text,`
 ((ListViewItem)y).SubItems[column].Text);
            else
                return String.Compare(((ListViewItem)y).SubItems[column].Text,`
 ((ListViewItem)x).SubItems[column].Text);
        }
    }
"@  | Out-Null
    }
    #endregion
    
    if($ListView.Tag -is [ListViewItemComparer])
    {
        #Toggle the Sort Order
        if($SortOrder -eq [System.Windows.Forms.SortOrder]::None)
        {
            if($ListView.Tag.column -eq $ColumnIndex -and $ListView.Tag.sortOrder -eq 'Ascending')
            {
                $ListView.Tag.sortOrder = 'Descending'
            }
            else
            {
                $ListView.Tag.sortOrder = 'Ascending'
            }
        }
        else
        {
            $ListView.Tag.sortOrder = $SortOrder
        }
        
        $ListView.Tag.column = $ColumnIndex
        $ListView.Sort() #Sort the items
    }
    else
    {
        if($Sort -eq [System.Windows.Forms.SortOrder]::None)
        {
            $Sort = [System.Windows.Forms.SortOrder]::Ascending    
        }
        
        #Set to Tag because for some reason in PowerShell ListViewItemSorter prop returns null
        $ListView.Tag = New-Object ListViewItemComparer ($ColumnIndex, $SortOrder) 
        $ListView.ListViewItemSorter = $ListView.Tag #Automatically sorts
    }
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainForm                        = New-Object system.Windows.Forms.Form
$MainForm.ClientSize             = '430,500'
$MainForm.text                   = 'Factory UI VMs'
$MainForm.TopMost                = $true
$MainForm.FormBorderStyle        = 'Fixed3D'
$MainForm.MaximizeBox            = $false
$MainForm.MinimizeBox            = $false
$MainForm.StartPosition          = 'CenterScreen'
$MainForm.TopMost                = $true

$ListView                        = New-Object system.Windows.Forms.ListView
$ListView.text                   = 'listView'
$ListView.width                  = 410
$ListView.height                 = 300
$ListView.location               = New-Object System.Drawing.Point(9,13)
$ListView.View                   = 'Details'
$ListView.GridLines              = $true
$ListView.MultiSelect            = $false
$ListView.FullRowSelect          = $true

$TextVMName                      = New-Object system.Windows.Forms.TextBox
$TextVMName.multiline            = $false
$TextVMName.width                = 155
$TextVMName.height               = 20
$TextVMName.location             = New-Object System.Drawing.Point(10,351)
$TextVMName.Font                 = 'Microsoft Sans Serif,10'
$TextVMName.Enabled              = $false

$textLAbel1                      = New-Object system.Windows.Forms.Label
$textLAbel1.text                 = 'VM Name:'
$textLAbel1.AutoSize             = $true
$textLAbel1.width                = 25
$textLAbel1.height               = 10
$textLAbel1.location             = New-Object System.Drawing.Point(10,333)
$textLAbel1.Font                 = 'Microsoft Sans Serif,10'

$Groupbox1                       = New-Object system.Windows.Forms.Groupbox
$Groupbox1.height                = 55
$Groupbox1.width                 = 235
$Groupbox1.text                  = 'VM Actions'
$Groupbox1.location              = New-Object System.Drawing.Point(173,333)

$Groupbox2                       = New-Object system.Windows.Forms.Groupbox
$Groupbox2.height                = 55
$Groupbox2.width                 = 235
$Groupbox2.text                  = 'Power Actions'
$Groupbox2.location              = New-Object System.Drawing.Point(173,406)

$RefreshButton                   = New-Object system.Windows.Forms.Button
$RefreshButton.text              = 'Refresh List'
$RefreshButton.width             = 85
$RefreshButton.height            = 30
$RefreshButton.location          = New-Object System.Drawing.Point(10,417)
$RefreshButton.Font              = 'Microsoft Sans Serif,9'

$RestartVMButton                 = New-Object system.Windows.Forms.Button
$RestartVMButton.text            = 'Restart'
$RestartVMButton.width           = 60
$RestartVMButton.height          = 30
$RestartVMButton.location        = New-Object System.Drawing.Point(10,15)
$RestartVMButton.Font            = 'Microsoft Sans Serif,9'
$RestartVMButton.Enabled         = $false

$ShutdownVMButton                = New-Object system.Windows.Forms.Button
$ShutdownVMButton.text           = 'Shutdown'
$ShutdownVMButton.width          = 72
$ShutdownVMButton.height         = 30
$ShutdownVMButton.location       = New-Object System.Drawing.Point(82,15)
$ShutdownVMButton.Font           = 'Microsoft Sans Serif,9'
$ShutdownVMButton.Enabled        = $false

$StartVMButton                   = New-Object system.Windows.Forms.Button
$StartVMButton.text              = 'Start'
$StartVMButton.width             = 56
$StartVMButton.height            = 30
$StartVMButton.location          = New-Object System.Drawing.Point(166,15)
$StartVMButton.Font              = 'Microsoft Sans Serif,9'
$StartVMButton.Enabled           = $false

$PowerOffVMButton                = New-Object system.Windows.Forms.Button
$PowerOffVMButton.text           = 'Power Off'
$PowerOffVMButton.width          = 72
$PowerOffVMButton.height         = 30
$PowerOffVMButton.location       = New-Object System.Drawing.Point(83,15)
$PowerOffVMButton.BackColor      = '#c99da2'
$PowerOffVMButton.Font           = 'Microsoft Sans Serif,9'
$PowerOffVMButton.Enabled        = $false

$ResetVMButton                   = New-Object system.Windows.Forms.Button
$ResetVMButton.text              = 'Reset'
$ResetVMButton.width             = 60
$ResetVMButton.height            = 30
$ResetVMButton.location          = New-Object System.Drawing.Point(10,15)
$ResetVMButton.BackColor         = '#c99da2'
$ResetVMButton.Font              = 'Microsoft Sans Serif,9'
$ResetVMButton.Enabled           = $false

$MainForm.controls.AddRange(@($ListView,$TextVMName,$textLAbel1,$Groupbox1,$Groupbox2,$RefreshButton))
$Groupbox1.controls.AddRange(@($RestartVMButton,$ShutdownVMButton,$StartVMButton))
$Groupbox2.controls.AddRange(@($PowerOffVMButton,$ResetVMButton))

Create-VMList

$VMName = ''

$RestartVMButton.Add_Click(
    {
        $VMName = $TextVMName.Text
        Restart-VMGuest -VM $VMName -Confirm:$false
    }
)

$ShutdownVMButton.Add_Click(
    {
        $VMName = $TextVMName.Text
        Shutdown-VMGuest -VM $VMName -Confirm:$false
    }
)

$StartVMButton.Add_Click(
    {
        $VMName = $TextVMName.Text
        Start-VM -VM $VMName -Confirm:$false
    }
)

$ResetVMButton.Add_Click(
    {
        $VMName = $TextVMName.Text
        Restart-VM -VM $VMName -Confirm:$false
    }
)

$PowerOffVMButton.Add_Click(
    {
        $VMName = $TextVMName.Text
        Stop-VM -VM $VMName -Confirm:$false
    }
)

$RefreshButton.Add_Click(
    {
        Create-VMList
    }
)

$ListView.Add_Click(
    {
        $VMName = $ListView.SelectedItems[0].Text
        $PowerState = $ListView.SelectedItems[0].SubItems[1].Text
        $TextVMName.Text = $VMName
        
        if ($PowerState -eq 'PoweredOn') {
            $PowerOffVMButton.Enabled = $true
            $ResetVMButton.Enabled = $true
            $StartVMButton.Enabled = $false
            $ShutdownVMButton.Enabled = $true
            $RestartVMButton.Enabled = $true
        } else {
            $PowerOffVMButton.Enabled = $false
            $ResetVMButton.Enabled = $false
            $StartVMButton.Enabled = $true
            $ShutdownVMButton.Enabled = $false
            $RestartVMButton.Enabled = $false
        }
    }
)

$ListView.Add_ColumnClick(
    {
        Sort-ListViewColumn $this $_.Column
    }
)

[void]$MainForm.ShowDialog()
Disconnect-VIServer -Confirm:$false
# SIG # Begin signature block
# MIIIggYJKoZIhvcNAQcCoIIIczCCCG8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5/kOl50+Xjnzvp+d5lRHTVKt
# ZGagggXwMIIF7DCCBNSgAwIBAgIKQ0d83gAAAAAAMjANBgkqhkiG9w0BAQUFADBN
# MRIwEAYKCZImiZPyLGQBGRYCQUQxGDAWBgoJkiaJk/IsZAEZFghXMks4VEVTVDEd
# MBsGA1UEAxMUVzJLOFRFU1QtREMyVEVTVDMtQ0EwHhcNMTUwNzIwMDkwODQ4WhcN
# MjQwMzE3MTA1NDM2WjB0MQswCQYDVQQGEwJGSTESMBAGA1UECBMJUGlya2FubWFh
# MRkwFwYDVQQKExBOb2tpYW4gVHlyZXMgUGxjMQswCQYDVQQLEwJJVDEpMCcGCSqG
# SIb3DQEJARYaaG9zdG1hc3RlckBub2tpYW50eXJlcy5jb20wggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQC4C0T846wZP47bj/ulLf8A6BOn40zB9zQkYVJA
# xLx4dw712mCQMuh3mSNTr0UICWp2S0K8b+nHYM70L2VWWWLKfx0Fb8e3cLyErWZA
# RpzwZ2K8i4tQqB3KU0OV+kB2EY/lJojw/QcnOQb+eZirgYEYLAWQqXMbwk4jb7v7
# a98Pd7kCL5rAc8QiKWacgN6jjQIw5uEYmALaBmJ6bOiET8o7Hyt+0laMu77z7bYr
# pLB/dxJAmMFtsVZFcyDMlxhvEpGosbXSxwfRwr0jYs5Vodo99wQ43qB/kCKvnaGa
# eXXStyeQa58N/hDGuC6qLEGKH6KUqutk3IGYHVKa6F/8aqLpAgMBAAGjggKlMIIC
# oTA8BgkrBgEEAYI3FQcELzAtBiUrBgEEAYI3FQiFm1mB9s8LhKWFK4L0xhmE4elO
# HoWEh1+CgYpAAgFlAgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQE
# AwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSU9DFJ
# iu3MroLqePvcnrWd8BXEdzAfBgNVHSMEGDAWgBQ9KOhfvPJ50hILmw6OCovXs+OB
# hjCCAQYGA1UdHwSB/jCB+zCB+KCB9aCB8oaBvGxkYXA6Ly8vQ049VzJLOFRFU1Qt
# REMyVEVTVDMtQ0EsQ049REMyVEVTVDMsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUy
# MFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9VzJLOFRF
# U1QsREM9QUQ/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hjFodHRwOi8vY3JsLmdyb3VwLmFkL2Ny
# bGQvVzJLOFRFU1QtREMyVEVTVDMtQ0EuY3JsMIHGBggrBgEFBQcBAQSBuTCBtjCB
# swYIKwYBBQUHMAKGgaZsZGFwOi8vL0NOPVcySzhURVNULURDMlRFU1QzLUNBLENO
# PUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1D
# b25maWd1cmF0aW9uLERDPVcySzhURVNULERDPUFEP2NBQ2VydGlmaWNhdGU/YmFz
# ZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MAwGA1UdEwEB/wQC
# MAAwDQYJKoZIhvcNAQEFBQADggEBACy8tir4CtLg1ivnj/Cgn16XuZd007+jipyW
# M96TfyrERxiQM0c4ZkieSHYqU3ixBKQbPw189hEWyiEZFkdWFnCz07nyMEbSs7FJ
# Z0Q1VVOwEm9vsvbHY9IuyIUUw9645ShpmCw4JRa0gzd0cvRzTLV87PhzDOOnLB1U
# blXU+8hXpB14gqXI4MXaOIItUI7gE4d8KUUvPerHmqPoQtyRdz+GXW27xpWbZLUI
# EOEgjQxlCftahpnNEEa9lP4ZMMrPZf60IJJsE0ZNGx7nGZEVWHCx6bLl3dZJmcXz
# f/osuHCVsaN7GCfgM0Ir98aRpp2FFPv8Ne51XmCPIx85a1bsfb4xggH8MIIB+AIB
# ATBbME0xEjAQBgoJkiaJk/IsZAEZFgJBRDEYMBYGCgmSJomT8ixkARkWCFcySzhU
# RVNUMR0wGwYDVQQDExRXMks4VEVTVC1EQzJURVNUMy1DQQIKQ0d83gAAAAAAMjAJ
# BgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAj
# BgkqhkiG9w0BCQQxFgQUYRV/M+7fIZfhj9JQDJtjXBTu7cUwDQYJKoZIhvcNAQEB
# BQAEggEAZxVc1/yyZXjOQAetsfeqJyTXXLKACfROwLni88XHbrvoHKtqu8zvsCyr
# p879AS3icDFQtXBwkdi1xW3gyjXyzJa/COvYmFaHAcwsAdRIIZALELZ3Q8e5VPGl
# 4lcP6V48G9xisoB4amrKHypUrS4vEZfz+aouTy8U2ZH5ezV6Re5pmjASwuvWb4S+
# 5BRX9xgDAsHeU0AyEtBFf51QvEmiz7lZs/lSRqa12c68/D7Qa0R8xoHhg9WEn0s7
# juw5uuMz8ZZx/6i/UQUHBRrTMWNXxOjwu2zPNnJ8OqNJ7TdzRqim7NbZxs0CQD1a
# 629awXvlUKFe1iBDLp6Ls1UXSqvwEA==
# SIG # End signature block
