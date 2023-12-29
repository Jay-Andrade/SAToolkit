<#
.SYNOPSIS
This function will upload a file to Azure Blob storage

.PARAMETER file
Full path of file to upload


.PARAMETER sasurl
SAS token URL to upload to blob container.

.PARAMETER returnurl
Switch. Will return the generated blob URL to the file.

.PARAMETER deleteInputFile
Switch. Will delete the input file if successfully uploaded to blob.

.EXAMPLE
Push-FiletoAzBlob -file "C:\example\example.txt" -SASURL $SASURL
Will upload the input file to specified blob container using the given SAS URL
#>
function Push-FiletoAzBlob {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$file,

        [Parameter(Mandatory = $TRUE, Position = 2)]
        [String]$SASURL,

        [Parameter(Position = 3)]
        [Switch]$returnURL,

        [Parameter(Position = 4)]
        [Switch]$deleteInputFile
    )

    $container = $SASURL.split('?')[0]

    $azcopy = "$env:temp\azcopy.exe"
    Invoke-PSDownload -url 'https://aka.ms/downloadazcopy-v10-windows' -fullPath $azcopy

    #Sanitize file of spaces if necessary
    if (($file -match " ") -and (Test-Path $file)){
        $spacelessPath = Remove-Spaces -inputString $file
        $sanitizedName = [System.IO.Path]::GetFileName($spacelessPath)
        $sanitizedFile = "$env:temp\$sanitizedName"
        Copy-ItemSafely -inputPath $file -destinationPath $sanitizedFile
        $payload = $sanitizedFile #allows deletion of sanitizedfile while preserving original if delete flag not set
    } else {
        $payload = $file
    }
    
    if (Test-Path $payload) {
        try {
            Start-Process -Wait -NoNewWindow -FilePath $azcopy -ArgumentList "copy $payload $SASURL"
        } catch {
            Write-Syslog -category 'ERROR' -message "Failed to upload $payload to Blob: $_"
            break #don't continue with stuff in if but don't fully return/exit
        }
        
        $fullOutputURL = $container + [System.IO.Path]::GetFileName($file)
        Write-Syslog -category 'INFO' -message "Uploaded $file to Azure Blob: $fullOutputURL"
        if ($deleteInputFile) {
            Remove-Item $file -Force
        }
    } else {
        Write-Syslog -category 'ERROR' -message "$payload not found, cannot upload nonexistant file. Ignoring delete flag if present."
    }

    if ($sanitizedFile) {
        Remove-Item $sanitizedFile
    }
    
    Remove-Item $azcopy

    if ($returnURL) {
        $fullOutputURL
    }
}
Set-Alias -Name 'Invoke-UploadtoBlob' -Value 'Push-FiletoAzBlob'
Set-Alias -Name 'Start-UploadtoBlob' -Value 'Push-FiletoAzBlob'