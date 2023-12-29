<#
.SYNOPSIS
This function will set the value of a registry key.

.PARAMETER RegistryKey
Registry key path (Ex: 'HKLM:\SOFTWARE\Policies\Microsoft\Onedrive').

.PARAMETER ValueName
Name of the key to adjust.

.PARAMETER Delete
Switch parameter, will delete the key supplied

.PARAMETER ValueData
Value to set for the key.

.PARAMETER ValueType
Type to use for the key (Ex: String, DWord, etc.).

.PARAMETER Return
Switch, returns the new value of the registry key.

.EXAMPLE
Set-RegistryKey -RegistryKey $RegistryKey -ValueName "Example Name" -ValueData "Example Value" -ValueType "String" -Return
Creates/Sets the registry key "Example Name" with string value "Example Value" and returns the created key.

.EXAMPLE
Set-RegistryKey "Example Name" "Example Value"
Creates/Sets the registry key "Example Name" with type String by default and value "Example Value" in the default location: "HKLM:\SOFTWARE\SAToolkit\".

.EXAMPLE
Set-RegistryKey -RegistryKey $RegistryKey -ValueName"Example Name" -Delete
Deletes the key provided. Will fail silently.
#>
function Set-RegistryKey {
    Param (
        [Parameter(Position = 0)]
        $RegistryKey = "HKLM:\SOFTWARE\SAToolkit\",

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$ValueName,

        [Parameter(ParameterSetName= 'Remove', Mandatory = $TRUE)]
        [Switch]$Delete,

        [Parameter(ParameterSetName= 'Add/Adjust', Mandatory = $TRUE)]
        [Parameter(Position = 2)]$ValueData,

        [Parameter(ParameterSetName= 'Add/Adjust')]
        [Parameter(Position = 3)]$ValueType = "String",

        [Parameter(ParameterSetName= 'Add/Adjust')]
        [Switch]$Return

    )

    $usr = [Environment]::UserName
    if (($usr -like "SYSTEM") -and (($RegistryKey -match '^HKEY_CURRENT_USER') -or ($RegistryKey -match '^HKCU:'))) {
        #Determine if we're running as NTAUTHORITY\System, and if we are, attempt to get the SID of the current logged-in user.
        try {
            $User = New-Object System.Security.Principal.NTAccount((Get-WmiObject -Class win32_computersystem).UserName.split('\')[1])
            $currentUserSID = $User.Translate([System.Security.Principal.SecurityIdentifier]).value
            $notice = "Detected HKCU entry, caller is NTAUTHORITY\System. Addressing HKU via current logged on user's SID: $currentuserSID"
            Write-Syslog -Category 'INFO' -Message $notice
        } catch {
            $err = "Detected HKCU entry, caller is NTAUTHORITY\System. Failed to get current user SID. Error: $_"
            Write-Syslog -Category 'ERROR' -Message $err
            return
        }
    }
    
    #Replace shorthand for creation of key if nonexistant.
    #Special treatment needed for HKEY_CURRENT_USER
    if ($RegistryKey -match "^HKLM:") {
        $sanitizedKeyPath = $RegistryKey -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'

    } elseif (($RegistryKey -match '^HKCU:') -and ($currentUserSID)) {
        #HKCU and caller is NTAUTHORITY\System
        $sanitizedKeyPath = $RegistryKey -replace '^HKCU:', "HKEY_USERS\$currentUserSID"
        $RegistryKey = $RegistryKey -replace '^HKCU:', "Registry::HKEY_USERS\$currentUserSID"

    } elseif (($RegistryKey -match '^HKEY_CURRENT_USER') -and ($currentUserSID)) {
        #HKCU and caller is NTAUTHORITY\System
        $sanitizedKeyPath = $RegistryKey -replace '^HKEY_CURRENT_USER', "HKEY_USERS\$currentUserSID"
        $RegistryKey = $RegistryKey -replace '^HKEY_CURRENT_USER', "Registry::HKEY_USERS\$currentUserSID"

    } elseif ($RegistryKey -match '^HKCU:') {
        #HKCU and caller is NOT NTAUTHORITY\System (don't inject $currentUserSID)
        $sanitizedKeyPath = $RegistryKey -replace '^HKCU:', "HKEY_CURRENT_USER"

    } elseif ($RegistryKey -match '^HKCR:') {

        $sanitizedKeyPath = $RegistryKey -replace '^HKCR:', 'HKEY_CLASSES_ROOT'

    } elseif ($RegistryKey -match '^HKU:') {
        $sanitizedKeyPath = $RegistryKey -replace '^HKU:', "HKEY_USERS"
    }

    if (($Delete) -and ($ValueName -notlike "Reboot Needed")) {
        Try {
            Remove-ItemProperty -Path $RegistryKey -Name $ValueName -Force -ErrorAction Stop
            Write-Syslog -Category "INFO" -Message "Deleted reg key with item property name $ValueName."
        } Catch{
            Write-Syslog -Category 'INFO' -Message "Reg key $ValueName is already deleted or could not be deleted."
        }
        return
    } elseif (($Delete) -and ($ValueName -like "Reboot Needed")) {
        Throw "Cannot delete this key"
        Return
    }

    if (!(Test-Path "Registry::$sanitizedKeyPath")) { 
        #need to encapsulate into a try
        New-Item -Path "Registry::$sanitizedKeyPath" -Force | Out-Null
        Write-Syslog -category 'WARN' -message "Registry key path $RegistryKey did not exist. Creating now."
    }

    #Prevents .ToLower() happening to an int and causing issues but doesn't override supplied input value
    if (($ValueData.GetType()).name -eq 'String') {
        $keyCheck = $ValueData.ToLower()
    } else {
        $keyCheck = $ValueData
    }

    try {
        if ((Get-Item -Path $RegistryKey).GetValue($ValueName).ToLower() -ne $keyCheck) {
            Set-ItemProperty -Path $RegistryKey -Name $ValueName -Value $ValueData -Force | Out-Null
        } 
    } catch {
        New-ItemProperty -Path $RegistryKey -Name $ValueName -PropertyType $ValueType -Value $ValueData -Force | Out-Null
        if ($ValueName -like "Reboot Needed") {
            Write-SysLog -category 'WARN' -message "Created 'Reboot Needed' registry value name. Set to $ValueData." -outputFile "$env:systemdrive\nable\rebootflag.log"
        } else {
            Write-SysLog -category 'WARN' -message "$ValueName does not exist. Creating now."
        }
    }
    
    #Not a duplicate, above if is in a catch
    if ($ValueName -like "Reboot Needed") {
        Write-SysLog -category "INFO" -message "Reboot Needed set to $ValueData" -outputFile "$env:systemdrive\nable\rebootflag.log"
    } else {
        Write-SysLog -category "INFO" -message "$ValueName set to $ValueData"
    }

    #Used for conformation of change
    if ($Return) {
        return ((Get-Item -Path $RegistryKey).GetValue($ValueName))
    }
}
Set-Alias -Name 'Set-RegistryKey' -Value 'Set-RegistryKey'