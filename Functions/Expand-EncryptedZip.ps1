<#
.SYNOPSIS
This function decrypt an encrypted zip file using 7zip.

.PARAMETER inputfile
Full path of the encrypted zip file to decrypt.

.PARAMETER key
Key to decrypt the zip file.

.PARAMETER outputdirectory
Directory where the decrypted zip file will be saved. Defaults to: "$env:temp".

.PARAMETER deleteinputfile
Switch. Will delete the input file once it's been decrypted.

.EXAMPLE
Expand-EncryptedZip -inputfile 'C:\example\encryptedfile.zip -key '123456' -outputdirectory C:\example\
Will decrypt the zip file input and place it in the output directory.

.EXAMPLE
Expand-EncryptedZip 'C:\example\encryptedfile.zip '123456' -deleteinputfile
Will decrypt the zip file input and place it in the default output directory ("$env:temp") and will delete the input file.
#>
function Expand-EncryptedZip {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$inputFile,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$key,

        [Parameter(Position = 2)]
        [String]$outputDirectory = "$env:temp",

        [Parameter(Position = 3)]
        [Switch]$deleteInputFile
    )

    if ((Get-ApplicationInformation 7zip) -eq 'Not Installed') {
        Write-Syslog -category 'ERROR' -message '7-Zip not installed. Install 7-Zip and re-try.'
        return
    }

    try {
        
        $process = 'C:\Program Files\7-Zip\7z.exe'

        Start-Process $process -ArgumentList "x $inputFile -p$key -o$outputDirectory" -Wait
        Start-Sleep 5

        Write-Syslog -category 'INFO' -message "Decrypted $inputFile and saved to $outputDirectory"

        if ($deleteInputFile) {
            Remove-Item $inputFile -Force
            Write-Syslog -category 'WARN' -message "Removed $inputFile"
        }
    } catch {
        Write-Syslog -catagory 'ERROR' -message "Failed to decrypted zip file $inputFile"
    }

    #Can't really offer any return as the function will be blind to what's in the zip it's decrypting 
}
Set-Alias -Name 'Expand-EncryptedArchive' -Value 'Expand-EncryptedZip'