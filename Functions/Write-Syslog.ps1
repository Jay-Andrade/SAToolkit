<#
.SYNOPSIS
This function will write data out to syslog.

.PARAMETER Message
The message you would like to display in the log entry

.PARAMETER category
Catagory of your log entry. Common are: INFO, WARN, and ERROR

.PARAMETER OutputFile
The log file to output the log entry to. Defaults to: "$env:systemdrive\nable\syslog.log"

.PARAMETER Source
Displays the source of the log entry in the entry. Important for log entries to Rebootflag.log

.EXAMPLE
Write-Syslog "Test message" "INFO" "C:\nable\example.log" "- AMP - AMP NAME" -displayMessage
This will write a message to syslog with catagory 'INFO'. It will display the source of the log entry and will write the log entry to console.

.EXAMPLE
Write-Syslog "Test message" "WARN"
This will write a message to syslog with catagory 'WARN'. It will use the default output directory "$env:systemdrive\nable\syslog.log"
It will not show the source of the log entry, and will not write the log entry to console.
#>
function Write-Syslog {
    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        $message,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        $category,

        [Parameter(Position = 2)]
        $outputFile = "$env:systemdrive\nable\syslog.log",

        [Switch]$displayMessage,
        
        [Switch]$displaySource
    )
    switch ($category) {
        'ERROR' { $etype = 1; break}
        'WARN' { $etype = 2; break}
        default { $etype = 4; break}
    }
    
    if ($displaySource){
        $string = "["+(Get-Date -Format g)+"] " + "[$category] [SOURCE] $source [MESSAGE] $message"
    } else {
        $string = "["+(Get-Date -Format g)+"] " + "[$category] [MESSAGE] $message"
    }

    if ($displayMessage) {
        Write-Host $string
    }

    Out-File -FilePath $outputFile -InputObject $string -Append
    Return
}
Set-Alias -Name 'syslog' -Value 'Write-Syslog'