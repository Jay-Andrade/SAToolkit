<#
.SYNOPSIS
Get the public IPv4 address of a device.

.EXAMPLE
$publicIP = Get-PublicIP
#>
function Get-PublicIP {
    $publicIP = (Invoke-RestMethod -uri "http://icanhazip.com").Replace("`n","")
    return $publicIP
}
Set-Alias -Name 'Get-WANIP' -Value 'Get-PublicIP'