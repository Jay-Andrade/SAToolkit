<#
.SYNOPSIS
This function will set the value of a registry key.

.PARAMETER regkey
Registry key path (Ex: 'HKLM:\SOFTWARE\Policies\Microsoft\Onedrive').

.PARAMETER keyname
Name of the key to adjust.

.PARAMETER deletekey
Switch parameter, will delete the key supplied

.PARAMETER keyvalue
Value to set for the key.

.PARAMETER keytype
Type to use for the key (Ex: String, DWord, etc.).

.PARAMETER returnvalue
Switch, returns the new value of the registry key.

.EXAMPLE
Set-RegKey -regkey $regKey -keyname "Example Name" -keyvalue "Example Value" keytype "String" -returnvalue
Creates/Sets the registry key "Example Name" with string value "Example Value" and returns the created key.

.EXAMPLE
Set-RegKey "Example Name" "Example Value"
Creates/Sets the registry key "Example Name" with type String by default and value "Example Value" in the default location: "HKLM:\SOFTWARE\SAToolkit\".

.EXAMPLE
Set-RegKey -regkey $regKey -keyname "Example Name" -deletekey
Deletes the key provided. Mote: will fail silently.
#>
function Set-RegKey {
    Param (
        [Parameter(Position = 0)]
        $regKey = "HKLM:\SOFTWARE\SAToolkit\",

        [Parameter(Mandatory = $TRUE, Position = 1)]
        $keyName,

        [Parameter(ParameterSetName= 'Remove', Mandatory = $TRUE)]
        [Switch]$deletekey,

        [Parameter(ParameterSetName= 'Add/Adjust', Mandatory = $TRUE)]
        [Parameter(Position = 2)]$keyValue,

        [Parameter(ParameterSetName= 'Add/Adjust')]
        [Parameter(Position = 3)]$keyType = "String",

        [Parameter(ParameterSetName= 'Add/Adjust')]
        [Switch]$returnValue

    )

    if ($regKey -match "^HKLM:") {
        $sanitizedKeyPath = $regKey -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'
    } elseif ($regKey -match '^HKCU:') {
        $sanitizedKeyPath = $regKey -replace '^HKCU:', 'HKEY_CURRENT_USER'
    }
    elseif ($regKey -match '^HKCR:') {
        $sanitizedKeyPath = $regKey -replace '^HKCR:', 'HKEY_CLASSES_ROOT'
    }
    elseif ($regKey -match '^HKU:') {
        $sanitizedKeyPath = $regKey -replace '^HKU:', 'HKEY_USERS'
    }

    if (!(Test-Path "Registry::$sanitizedKeyPath")) {
        #Replace shorthand for creation of key if nonexistant.
        New-Item -Path "Registry::$sanitizedKeyPath" -Force | Out-Null
        Write-Syslog -category 'WARN' -message "Registry key path $regkey did not exist. Creating it now." -displayMessage
    }

    #Prevents .ToLower() happening to an int and causing issues but doesn't override supplied input value
    if (($keyvalue.GetType()).name -eq 'String') {
        $keyCheck = $keyValue.ToLower()
    } else {
        $keyCheck = $keyValue
    }

    try {
        if ((Get-Item -Path $regKey).GetValue($keyName).ToLower() -ne $keyCheck) {
            Set-ItemProperty -Path $regKey -Name $keyName -Value $keyValue -Force | Out-Null
        } 
    } catch {
        New-ItemProperty -Path $regKey -Name $keyName -PropertyType $keyType -Value $keyValue -Force | Out-Null
        Write-SysLog -category 'WARN' -message "$keyName does not exist. Creating now." -displayMessage
    }
    
    Write-SysLog -category "INFO" -message "$keyName set to $keyvalue" -displayMessage


    #Used for conformation of change
    if ($returnValue) {
        return ((Get-Item -Path $regKey).GetValue($keyName))
    }
}