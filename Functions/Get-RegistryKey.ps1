<#
.SYNOPSIS
Get and return a specified registry key. Will return the value the key is set to or $NULL if the key does not exist. Does not make any changes.

.PARAMETER RegistryKey
Registry key path (Ex: 'HKLM:\SOFTWARE\Policies\Microsoft\Onedrive').

.PARAMETER ValueName
Name of the key to check.

.EXAMPLE
$registryValue = Get-RegistryKey -RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Onedrive" -ValueName "ExampleValueName"
#>
function Get-RegistryKey {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$RegistryKey,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$ValueName,

        [Switch]$Silent
    )

    $usr = [Environment]::UserName
    if (($usr -like "SYSTEM") -and (($RegistryKey -match '^HKEY_CURRENT_USER') -or ($RegistryKey -match '^HKCU:'))) {
        #Determine if we're running as NTAUTHORITY\System, and if we are, attempt to get the SID of the current logged-in user.
        $currentUserSID = Get-LoggedInUserSID
        if ($NULL -ne $currentUserSID) {
            $notice = "Detected HKCU entry, caller is NTAUTHORITY\System. Addressing HKU via current logged on user's SID: $currentuserSID"
            if (!($Silent)) {
                Write-Syslog -Category 'INFO' -Message $notice
            }
        } else {
            $err = "Detected HKCU entry, caller is NTAUTHORITY\System. Failed to get current user SID. Error: $_"
            Write-Syslog -Category 'ERROR' -Message $err
            return
        }
    }

    #Replace shorthand for creation of key if nonexistant.
    #Special treatment needed for HKEY_CURRENT_USER
    if ($RegistryKey -match "^HKLM:") {
        $sanitizedKeyPath = $RegistryKey -replace '^HKLM:', 'Registry::HKEY_LOCAL_MACHINE'

    } elseif (($RegistryKey -match '^HKCU:') -and ($currentUserSID)) {
        #HKCU and caller is NTAUTHORITY\System
        $sanitizedKeyPath = $RegistryKey -replace '^HKCU:', "Registry::HKEY_USERS\$currentUserSID"
        $RegistryKey = $RegistryKey -replace '^HKCU:', "HKEY_USERS\$currentUserSID"

    } elseif (($RegistryKey -match '^HKEY_CURRENT_USER') -and ($currentUserSID)) {
        #HKCU and caller is NTAUTHORITY\System
        $sanitizedKeyPath = $RegistryKey -replace '^HKEY_CURRENT_USER', "Registry::HKEY_USERS\$currentUserSID"
        $RegistryKey = $RegistryKey -replace '^HKEY_CURRENT_USER', "HKEY_USERS\$currentUserSID"

    } elseif ($RegistryKey -match '^HKCU:') {
        #HKCU and caller is NOT NTAUTHORITY\System (don't inject $currentUserSID)
        $sanitizedKeyPath = $RegistryKey -replace '^HKCU:', "Registry::HKEY_CURRENT_USER"

    } elseif ($RegistryKey -match '^HKCR:') {

        $sanitizedKeyPath = $RegistryKey -replace '^HKCR:', 'Registry::HKEY_CLASSES_ROOT'

    } elseif ($RegistryKey -match '^HKU:') {
        $sanitizedKeyPath = $RegistryKey -replace '^HKU:', "Registry::HKEY_USERS"
    }

    if (Test-Path "$sanitizedKeyPath") {
        $returnValue = ((Get-Item -Path "$sanitizedKeyPath").GetValue($ValueName))
        if ($NULL -eq $returnValue) {
            #Key exists, value does not
            Write-Syslog -Category 'WARN' -Message "Registry path ($RegistryKey) exists, but the specified value name ($valueName) does not"
        } else {
            if (!($Silent)) {
                Write-Syslog -Category 'INFO' -Message "($RegistryKey\$valueName) exists and is set to $returnValue"
            }
        }
    } else {
        Write-Syslog -category 'WARN' -message "Registry key path $RegistryKey does not exist. Returning NULL"
        $returnValue = $NULL
    }

    return $returnValue
}
Set-Alias -Name 'Get-RegKey' -Value 'Get-RegistryKey'