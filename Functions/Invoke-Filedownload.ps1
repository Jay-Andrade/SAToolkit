<#
.SYNOPSIS
This function download a file when provided with a URL.

.PARAMETER url
URL of file to download.

.PARAMETER outputdirectory
Directory where the file will be saved once downloaded. Defaults to: "$env:temp".

.PARAMETER filename
Manually specify the name the file will be saved with once downloaded.

.PARAMETER generatefilename
Will generate the filename based on the given URL.

.PARAMETER useAZCopy
Switch. Will try to use AzCopy to transfer if file is in Azure Blob. Useful for large files.

.PARAMETER returnPath
Switch. Will return the path of the downloaded file.

.EXAMPLE
Start-FileDownload -url $URL -outputdirectory 'C:\testdir\' -filename 'example.txt'
Downloads a file using the provided URL and will output as C:\testdir\example.txt.

.EXAMPLE
Start-FileDownload $URL -filename 'exmple.txt'
Downloads a file using the provided URL. Will save the file to the default directory: "$env:temp",
and will name the file 'example.txt'.

.EXAMPLE
Start-FileDownload $URL -generatefilename
Downloads a file using the provided URL. Will save the file to the default directory: "$env:temp",
and will generate the name of the file based on the URL.
#>
function Invoke-Filedownload {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$URL,

        [Parameter(Position = 1)]
        [String]$outputDirectory = "$env:temp",

        [Parameter(ParameterSetName= 'Input Filename', Mandatory = $TRUE, Position = 2)]
        [String]$fileName,

        [Parameter(ParameterSetName= 'Generate Filename', Mandatory = $TRUE, Position = 2)]
        [Switch]$generateFileName, #kind of a dummy parameter but seems to be best practice to include it for legibility purposes

        [Parameter]
        [Switch]$useAZCopy,

        [Parameter]
        [Switch]$returnPath
    )

    if (!($fileName)) {
        $FileName = [System.IO.Path]::GetFileName($URL)
    }

    $fullPath = "$outputDirectory\$fileName"

    if (($useAZCopy) -and ($URL -match "blob")) {
        #use AZCopy
        $azcopy = "$env:temp\azcopy.exe"
        Invoke-PSDownload -url 'https://aka.ms/downloadazcopy-v10-windows' -fullPath $azcopy

        if (((Get-FileHash $azcopy).hash) -ne "3808CD286E24AFDA0D20C72E25A466C1CAA43F8D8B1A0FEAC8DFDDA6F7492BCD") {
            throw "AZCopy hash does not match."
        }

        #Move this to Remove-Spaces
        if ($URL -match " ") {
            $URL = $URL.replace(" ","%20")
            $fullPath = $fullPath.Replace(" ","")
        }

        Start-Process -Wait -NoNewWindow -FilePath $azcopy -ArgumentList "copy $URL $fullPath"
        Write-Syslog -category "INFO" -message "Downloaded: $fullPath via AZCopy" -displayMessage
        Remove-Item $azcopy
    } elseif (($useAZCopy) -and (!($URL -match "blob"))) {
        #azcopy switch, URL notmatch blob, fallback on PSDownload
        Write-Syslog -category "WARN" -message "Supplied URL doesn't look like Azure Blob. Falling back to standard download" -displayMessage
        Invoke-PSDownload -url $url -fullPath $fullPath
    } else {
        #psdownload
        Invoke-PSDownload -url $url -fullPath $fullPath
    }

    if ($returnPath) {
        return $fullPath
    }
}
Set-Alias -Name 'Download-File' -Value 'Invoke-Filedownload'
Set-Alias -Name 'Start-FileDownload' -Value 'Invoke-Filedownload'