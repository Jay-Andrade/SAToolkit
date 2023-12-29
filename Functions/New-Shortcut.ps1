<#
.SYNOPSIS
This function will create a new shortcut to the defined target

.PARAMETER shortcutName
Name of the shortcut (do not include extension)

.PARAMETER shortcutPath
Location on disk shortcut should be placed. Optional, defaults to 'C:\Users\Public\Desktop\'

.PARAMETER shortcutTarget
Target the shortcut should point to

.PARAMETER allowClobber
Switch. Allows for recreation of shortcut that already exists with defined name and path

.EXAMPLE
New-Shortcut -shortcutName 'Company NAS' -shortcutTarget '192.168.1.2'
Will create a new shortcut with defined parameters in the default directory 'C:\Users\Public\Desktop\'. Will not overwrite any existing shortcut

.EXAMPLE
New-Shortcut -shortcutName 'Common files' -shortcutPath "C:\example" -shortcutTarget '10.0.0.3' -allowClobber
Will create a new shortcut with defined parameters. Will overwrite any existing shortcut in the defined location
#>
function New-Shortcut {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$shortcutName,

        [Parameter(Position = 1)]
        [String]$shortcutPath = 'C:\Users\Public\Desktop\',

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$shortcutTarget,

        [Parameter(Position = 3)]
        [Switch]$allowClobber
    )

    $shortcut = "$shortcutPath\$shortcutName.lnk"

    if (!(Test-Path -Path $shortcut)) {
        $createShortcut = $TRUE
    } elseif ((Test-Path -Path $shortcut) -and ($allowClobber)) {
        Write-Syslog -category 'WARN' -message "Shortcut already exists, clobber is enabled. Deleting and recreating."
        Remove-Item $shortcut -Force
        $createShortcut = $TRUE
    }

    if ($createShortcut) {
        try {
            $sh = new-object -com "WScript.Shell"
            $lnk = $sh.CreateShortcut( (join-path $shortcutPath $shortcutName) + ".lnk" )
            $lnk.TargetPath = $shortcutTarget
            $lnk.IconLocation = "explorer.exe,0"
            $lnk.Save()
            Write-Syslog -category 'INFO' -message "Created new shortcut: $shortcut"
        } catch {
            Write-Syslog -category 'ERROR' -message "Failed to create shortcut. Error: $_"
            break
        }
    } else {
        Write-Syslog -category 'INFO' -message "Shortcut already exists and clobber is disabled. Doing nothing."
    }

}