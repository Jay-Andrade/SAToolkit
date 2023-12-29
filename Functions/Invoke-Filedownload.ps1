<#
.SYNOPSIS
This function download a file when provided with a URL.

.PARAMETER url
URL of file to download.

.PARAMETER OutputDirectory
Directory where the file will be saved once downloaded. Defaults to: "$env:temp", file name will be generated.
Override with another directory (with trailing \), or specify directory and filename. See examples for clarification

.PARAMETER useAZCopy
Switch. Will try to use AzCopy to transfer if file is in Azure Blob. Useful for large files.

.PARAMETER TryCount
Determines how many times the download will try to run. Defaults to 1

.PARAMETER returnPath
Switch. Will return the path of the downloaded file.

.EXAMPLE
Start-FileDownload -url $URL -OutputDirectory 'C:\testdir\'
Downloads a file using the provided URL. generated the filename based on URL input and will output to C:\testdir\.

.EXAMPLE
Start-FileDownload $URL -OutputDirectory 'C:\temp\example.txt'
Downloads a file using the provided URL. Will save the file to the default directory: "$env:temp",
and will name the file 'example.txt'.

.EXAMPLE
Start-FileDownload $URL -UseAZCopy -TryCount 3
Downloads a file using the provided URL. Will generate the filename and save the file to the default directory: "$env:temp".
Will use AZCopy and will try the download 3 times if there are any errors.

.EXAMPLE
Start-FileDownload $URL -OutputDirectory 'C:\temp\files
Downloads a file using the provided URL and will save it with filename 'files'. Prevent this behavior by adding trailing \ to 
OutputDirectory input
#>
function Invoke-Filedownload {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$URL,

        [Parameter(Position = 1)]
        [String]$OutputDirectory = "$env:temp",

        [Parameter()]
        [Switch]$UseAZCopy,

        [Parameter(Position = 2)]
        [Int32]$TryCount = 1,

        [Parameter()]
        [Switch]$ReturnPath
    )

    if (($OutputDirectory[-1] -eq '\') -and (!($outputdirectory.Split('\')[-1] | Select-String "."))) {
        $fileName = [System.IO.Path]::GetFileName($URL)
        $OutputDirectory = $OutputDirectory + $fileName
    }


    for ($i = 0; $i -lt $TryCount; $i++) {
        try {
            if (($UseAZCopy) -and ($URL -match "blob")) {
                #use AZCopy
                $azcopy = "$env:temp\azcopy.exe"
                Invoke-PSDownload -url 'https://aka.ms/downloadazcopy-v10-windows' -fullPath $azcopy -DisableLogging
        
                if ($URL -match " ") {
                    $URL = Remove-Spaces -InputString $URL
                    $OutputDirectory = Remove-Spaces -InputString $OutputDirectory
                }
        
                Start-Process -Wait -NoNewWindow -FilePath $azcopy -ArgumentList "copy $URL $OutputDirectory"
                Write-Syslog -category "INFO" -message "Downloaded: $OutputDirectory via AZCopy"
                Remove-Item $azcopy
                break
            } elseif (($UseAZCopy) -and (!($URL -match "blob"))) {
                #azcopy switch, URL notmatch blob, fallback on PSDownload
                Write-Syslog -category "WARN" -message "Supplied URL doesn't look like Azure Blob. Falling back to standard download"
                Invoke-PSDownload -url $URL -fullPath $OutputDirectory
                break
            } else {
                #psdownload
                Invoke-PSDownload -url $URL -fullPath $OutputDirectory
                break
            }
        } catch {
            $tryCount = $i + 1 #for legibility since loop starts at 0
            $triesLeft = $retryCount - $i
            Write-Syslog -Category "ERROR" -Message "Download try $tryCount failed. Retrying $triesLeft more times."
            Start-Sleep 15
        }
    }
    
    if ($ReturnPath) {
        return $OutputDirectory
    }
}
Set-Alias -Name 'Download-File' -Value 'Invoke-Filedownload'
Set-Alias -Name 'Start-FileDownload' -Value 'Invoke-Filedownload'