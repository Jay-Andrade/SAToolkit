<#
.SYNOPSIS
This function returns the information for a given application.

.PARAMETER InputFile
Full name of the application.

.EXAMPLE
Get-ApplicationInformation -AppName 'Huntress Agent'
#>
function Get-ApplicationInformation {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$AppName
    )

    try {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        foreach ($path in $paths) {
            $applicationData = Get-ItemProperty $path | Where-Object { $_.DisplayName -like "*$AppName*" }
            if ($applicationData) {
                break
            }
        }
    } catch {
        return "Not Installed"
    }

    if ($applicationData) {
        return $applicationData
    } else {
        return "Not Installed"
    }
}
Set-Alias -Name 'Get-AppInfo' -Value 'Get-ApplicationInformation'
Set-Alias -Name 'Get-ApplicationInfo' -Value 'Get-ApplicationInformation'
Set-Alias -Name 'Get-AppInformation' -Value 'Get-ApplicationInformation'