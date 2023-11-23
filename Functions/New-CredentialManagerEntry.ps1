<#
.SYNOPSIS
This function create a new entry in Windows credential manager with type 'Domain Credential'.

.PARAMETER targetAddress
Target URL or Path for credential manager entry to correspond to.

.PARAMETER username
Username for the credential manager entry.

.PARAMETER password
[SecureString] Password for the credential manager entry.

.PARAMETER returnEntryFound
Conformation that an entry matching targetAddress and username input was found or created.

.EXAMPLE
New-CredentialManagerEntry -targetAddress '192.168.1.0' -username 'admin' -password $securePassword -returnEntryFound
Will create a new entry in credential manager pointing to '192.168.1.0' with username 'admin' and a secure password. Will return if creation was successful
or if an entry matching 'admin' already existed.
#>
function New-CredentialManagerEntry {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$targetAddress,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$username,

        [Parameter(Mandatory = $TRUE, Position = 2)]
        [SecureString]$password,

        [Parameter(Position = 3)]
        [Switch]$returnEntryFound
    )

    $credentialManagerEntryFound = $FALSE
    
    $cmURL = 'https://gtiotech.blob.core.windows.net/gtio-public/CredentialManager.dll'
    $cmdll = "$env:temp\CredentialManager.dll"

    if (!(Test-Path $cmdll)) {
        Invoke-PSDownload -url $cmURL -fullPath $cmdll -disableLogging
    }
    
    if ((Get-FileHash $cmdll).hash -ne '00413E280C97E167BB7246CE39FCEA52F5C1BB47E53D7C451A298EC0B5783A2D') {
        Write-Syslog -catagory 'ERROR' -message "Hash does not match for CredentialManager.dll. Are you sure this is the right file?" -displayMessage
        exit
    }

    #Doing this to allow unloading and removal of DLL at completion of function
    Start-Job -Name CM -ScriptBlock {
        $cmdll = $using:cmdll
        $targetAddress = $using:targetAddress
        $username = $using:username
        $password = $using:password

        [System.Reflection.Assembly]::LoadFrom("$cmdll") | Out-Null

        $credentials = [CredentialManager]::EnumerateCrendentials()
        $filteredCredentials = $credentials | 
        Where-Object {($_.CredentialType -eq "DomainPassword") -and ($_.UserName -like $username) -and ($_.ApplicationName -like $targetAddress)}

        if (!($filteredCredentials)) {
            [CredentialManager]::WriteCredential($targetAddress, $username, $password)
        }

        $credentials = [CredentialManager]::EnumerateCrendentials()
        $filteredCredentials = $credentials | 
        Where-Object {($_.CredentialType -eq "DomainPassword") -and ($_.UserName -like $username) -and ($_.ApplicationName -like $targetAddress)}

        if ($filteredCredentials) {
            return $TRUE
        } else {
            return $FALSE
        }
    } | Out-Null

    Wait-Job -Name CM | Out-Null
    $credentialManagerEntryFound = Receive-Job -Name CM

    if ($credentialManagerEntryFound) {
        Write-Syslog -category 'INFO' -message "Created Windows Credential Manager entry or confirmed entry already present for target: $targetAddress" -displayMessage
    } else {
        Write-Syslog -category 'ERROR' -message "Could not confirm creation or existance of Windows Credential Manager entry for target: $targetAddress" -displayMessage
    }

    Remove-Item $cmdll

    if ($returnEntryFound) {
        return $credentialManagerEntryFound
    }
}
Set-Alias -Name 'Create-CredentialManagerEntry' -Value 'New-CredentialManagerEntry'
