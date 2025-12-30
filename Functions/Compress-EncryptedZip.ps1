<#
.SYNOPSIS
This function compress and encrypt a file or directory using 7zip.

.PARAMETER inputDirectory
Directory to encrypt.

.PARAMETER inputfile
Full path of the file to encrypt.

.PARAMETER key
Key to use when encrypting the zip file.

.PARAMETER outputFullPath
Directory and name of the location to place the newly created encryped zip file. Must contain path, name, and end in '.zip'.

.PARAMETER deleteInputDirectory
Switch. Will delete the input directory once it's been encrypted.

.PARAMETER deleteinputfile
Switch. Will delete the input file once it's been encrypted.

.PARAMETER returnPath
Switch. Will return the path of the newly created encrypted zip file.

.EXAMPLE
Compress-EncryptedZip -inputDirectory "C:\example\" -key '123' -outputFullPath "C:\example2\encrypted-dir.zip" -deleteInputDirectory -returnPath
Will compress and encrypt the given input directory with provided key and output to provided path. Will delete the input directory and return the path of the new zip

.EXAMPLE
Compress-EncryptedZip -inputFile "C:\example\test.txt" -key '123' -outputFullPath "C:\example2\encrypted-dir.zip"
Will compress and encrypt the given input file with provided key and output to provided path.
#>
function Compress-EncryptedZip {
    #7zip sucks. This was a total PITA.
    Param (
        [Parameter(ParameterSetName = 'Directory', Mandatory = $TRUE, Position = 0)]
        [String]$inputDirectory,

        [Parameter(ParameterSetName = 'File', Mandatory = $TRUE, Position = 0)]
        [String]$inputFile,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$key,

        [Parameter(Mandatory = $TRUE, Position = 2)]
        [String]$outputFullPath,

        [Parameter(ParameterSetName = 'Directory', Position = 3)]
        [Switch]$deleteInputDirectory,

        [Parameter(ParameterSetName = 'File', Position = 3)]
        [Switch]$deleteInputFile,

        [Parameter(Position = 4)]
        [Switch]$returnPath
    )

    if ((Get-ApplicationInformation 7zip) -eq 'Not Installed') {
        Write-Syslog -category 'ERROR' -message '7-Zip not installed. Install 7-Zip and re-try.'
        return
    }

    <#
        Remeber how I said 7zip sucks?
        Well, it doesn't like spaces in the name of the file if it's a single file
        and it doesn't like spaces in the name of the lowest level folder if it's a directory.
        Also, if it's a folder, it will zip any child folders, but totally ignores and files in the specified parent directory.
        So, the easiest thing to do is to just create a copy of the folder/file where we can sanitize it then remove it
        at the end of execution. /rant
    #>
    if ($inputFile) { 

        #Copy file to working dir and remove any spaces present.
        $sanitizedfileName = Remove-Spaces -inputString ($inputFile.split('\')[-1])
        $sanitizedFile = "$env:temp\$sanitizedfileName"
        Copy-ItemSafely -inputPath $inputFile -destinationpath $sanitizedFile

        $inputItem = $inputFile
        
    } else {
        #Get rid of tailing \ for ease of use
        if (($inputDirectory -match '\\$')) {
            $inputDirectory = $inputDirectory.Remove($inputDirectory.Length - 1)
        }

        #Copy folder to working dir any spaces in child-most folder in input
        $sanitizedendofpath = Remove-Spaces -inputString ($inputDirectory.split('\')[-1])
        $sanitizedFile = "$env:temp\$sanitizedendofpath"
        Copy-ItemSafely -inputPath $inputDirectory -destinationpath $sanitizedfile

        #Check if there are files in the defined folder. If there are create a saftey folder and move them to it so they're not skipped
        $rawFiles = Get-ChildItem $sanitizedFile -Depth 0 | Where-Object { -not $_.PSIsContainer }
        if ($rawFiles) {
            $safteyFolder = New-Item "$sanitizedFile\7zFiles" -ItemType Directory -Force
            ForEach ($file in $rawFiles) {
                Move-Item "$sanitizedFile\$file" $safteyFolder
            }
        }

        $inputItem = $inputDirectory
    }

    #Protect against missing filename in output path
    if (($outputFullPath.split('\')[-1]).Length -eq 0) {
        Write-Syslog -catagory 'ERROR' -message 'OutputFullPath does not look like it has a destination file name. Exiting'
        exit
    }

    #Protect against missing .zip extension in output path
    if (!($outputFullPath.ToLower() -match '\.zip$')) {
        Write-Syslog -catagory 'WARN' -message ".zip not present at end of outputFullPath. Appending to outputFullPath."
        $outputFullPath = $outputFullPath += '.zip'
    }

    try {
        $process = 'C:\Program Files\7-Zip\7z.exe'

        Start-Process $process -ArgumentList "a $outputFullPath -p$key $sanitizedFile" -Wait
        Start-Sleep 5

        Write-Syslog -category 'INFO' -message "Compressed and encrypted $inputItem and saved to $outputFullPath"

        if (($deleteInputFile) -or ($deleteInputDirectory)) {
            Remove-Item $inputItem -Force
            Write-Syslog -category 'WARN' -message "Removed $inputItem"
        }
    } catch {
        Write-Syslog -catagory 'ERROR' -message "Failed to compress encrypted zip file $inputItem"
    }

    Remove-Item $sanitizedFile -Force -Recurse

    if ($returnPath) {
        return $outputFullPath
    }
}
Set-Alias -Name 'Compress-EncryptedArchive' -Value 'Compress-EncryptedZip'