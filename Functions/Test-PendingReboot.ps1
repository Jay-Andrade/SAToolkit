<#
.SYNOPSIS
This function will query the system and determine if a reboot is pending.

.EXAMPLE
$rebootNeeded = Test-PendingReboot
Tests if a reboot is needed and outputs to the variable $rebootNeeded
#>
function Test-PendingReboot
{
    $key1 = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    $key2 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    $pendingReboot = $FALSE
    if ((Get-ChildItem $key1 -EA Ignore) -or (Get-Item $key2 -EA Ignore)) {
        $pendingReboot = $TRUE
    }
    # if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
    #     $pendingReboot = $TRUE
    # }
    try { 
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($NULL -ne $status) -and ($status.RebootPending)) {
            $pendingReboot = $TRUE
        }
    } catch{}

    return $pendingReboot
}