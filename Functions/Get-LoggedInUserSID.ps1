<#
.SYNOPSIS
Get the SID of the currently logged in user..

.EXAMPLE
$SID = Get-LoggedInUserSID
#>
function Get-LoggedInUserSID {

    try {
        $User = New-Object System.Security.Principal.NTAccount((Get-WmiObject -Class win32_computersystem).UserName.split('\')[1])
        $path= "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*"
        $currentUserSID = (Get-ItemProperty -Path $path | Where-Object { $_.ProfileImagePath -like "*$user" }).PSChildName
    } catch {
        Write-Syslog -Category 'ERROR' -Message "Failed to get the logged-in user's SID. Returning NULL. Error: $_"
        $currentUserSID = $NULL
    }
    
    return $currentUserSID
}