function Copy-ItemSafely {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$inputPath,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$destinationPath,

        [Parameter(Position = 2)]
        [Switch]$return
    )

    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object FreeSpace

    if (($inputPath.Length / 1GB) -lt ($disk.FreeSpace / 1GB)) {
        try {
            Copy-Item $inputPath $destinationPath -Recurse
        } catch {
            Write-Syslog -catagory 'ERROR' -message "Failed to copy file. Error: $_" -displayMessage
        }
    } else {
        Write-Syslog -catagory 'ERROR' -message "Could not safely copy file due to lack of disk space." -displayMessage
        $destinationPath = $NULL
        return $NULL
    }

    if ($return) {
        Return $destinationPath
    }
}