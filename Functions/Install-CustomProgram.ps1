<#
.SYNOPSIS
This function will install an application given the installer file and correct arguments

.PARAMETER fileURL
URL of the installer file

.PARAMETER arguments
Manually defined arguments for installation

.PARAMETER xmlurl
Download a configuation file for defining insatllation arguments

.PARAMETER appName
Optional, will use name of file in download URL if not specified. Mostly for logging

.EXAMPLE
Install-CustomProgram -fileURL $fileURL -arguments '/qn'
Will insatll the program using the provided arguments

.EXAMPLE
Install-CustomProgram -fileURL $fileURL -xmlurl $xmlurl
Will install the program using arguments provided by the xml
#>
function Install-CustomProgram {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$fileURL,

        [Parameter(ParameterSetName = 'Standard Install', Mandatory = $TRUE, Position = 1)]
        [String]$arguments,

        [Parameter(ParameterSetName = 'Extended Install', Mandatory = $TRUE, Position = 1)]
        [String]$xmlURL,

        [Parameter(ParameterSetName = 'Extended Install', Position = 2)]
        [String]$xmlargs,

        [Parameter(Position = 2)]
        [String]$appName
    )

    $file_name = [System.IO.Path]::GetFileName($fileURL)
    $download_exe = "$env:temp\$file_name"
    Invoke-PSDownload -url $fileURL -fullPath $download_exe

    if ($XMLURL) {
        $xml_name = [System.IO.Path]::GetFileName($XMLURL)
        $download_xml = "$env:temp\$xml_name"
        Invoke-PSDownload -url $XMLURL -fullPath $download_xml 
        if ($xmlargs) {
            $arguments = $xmlargs
        } else {
            #defing here not at param level since part of default args includes $download_xml
            $arguments = "/configure `"$download_xml`"" # Use `/qb` instead of `/qn` for a basic UI
        }
    }

    if (!($appName)) {
        #defing here not at param level since fallback is generated during function run
        $appName = $file_name
    }

    Write-Syslog -category 'INFO' -message "Installing $($appName)" -displayMessage

    try {
        Start-Process -FilePath $download_exe -ArgumentList $arguments -Wait -NoNewWindow
        Write-Syslog -category 'INFO' -message "Installed $($appName)" -displayMessage
        Write-Syslog -category 'INFO' -message "Cleaning up...." -displayMessage
        Remove-Item $download_exe -Force
        Remove-Item $download_xml -Force
    }
    catch {
        Write-Host "Error occurred during installation: $($_.Exception.Message)"
    }
}