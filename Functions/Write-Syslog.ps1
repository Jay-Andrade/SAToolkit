<#
.SYNOPSIS
This function will write data out to syslog.

.PARAMETER Message
The message you would like to display in the log entry

.PARAMETER category
Catagory of your log entry. Common are: INFO, WARN, and ERROR

.PARAMETER OutputFile
The log file to output the log entry to. Defaults to: "$env:temp\syslog.log"

.PARAMETER Source
Displays the source of the log entry in the entry. Important for log entries to Rebootflag.log

.EXAMPLE
Write-Syslog "INFO" "Test message" "C:\SAToolkit\example.log" 
This will write a message to syslog with catagory 'INFO'. It will display the source of the log entry and will write the log entry to console.

.EXAMPLE
Write-Syslog "WARN" "Test message"
This will write a message to syslog with catagory 'WARN'. It will use the default output directory "$env:temp\syslog.log"
#>

function Write-Syslog {
    Param (

        [Parameter(Mandatory = $TRUE, Position = 0)]
        $Category,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        $Message,

        [Parameter(Position = 2)]
        $OutputFile = "$env:temp\syslog.log"
    )
    
    switch ($Category) {
        'ERROR' { $etype = 1; break}
        'WARN' { $etype = 2; break}
        default { $etype = 4; break}
    }

    try {
        $logSize = (Get-ItemProperty $OutputFile -ErrorAction SilentlyContinue).Length/1MB
    } catch {}
    if ($logSize -gt 1.0) {
        #Cannot call Write-Syslog normally for logging as function will infinetly recurse
        $dateThreshold = (Get-Date).AddDays(-30)

        $filteredEntries = Get-Content $OutputFile | Where-Object {
            try {
                # Extract the timestamp and trim any additional whitespace or hidden characters
                $dateString = $_.Split(']')[0].Trim('[', ']', ' ', "`t", "`n", "`r")
                # Specify the format of the date string accommodating single and double-digit days and months
                $entryDate = [DateTime]::ParseExact($dateString, "M/d/yyyy h:mm tt", [Globalization.CultureInfo]::InvariantCulture)
        
                # Keep the entry if it's newer than the threshold
                $entryDate -ge $dateThreshold
            }
            catch {
                # Handle entries with invalid date formats. Setting var to avoid numerous duplicate writes.
                $invalidEntries = $TRUE
            }
        }

        #Write filtered log entries (those newer than 30 days) to output file
        #Has to come before the $parsingMessage and $invalidEntries to prevent overwriting those items
        $filteredEntries | Out-File $OutputFile
        
        $parsingMessage = "["+(Get-Date -Format g)+"] " + "[INFO] [SOURCE] $source [MESSAGE] Trimmed syslog file: $OutputFile - Keeping last 30 days of logs."
        Write-Host $parsingMessage
        Out-File -FilePath $OutputFile -InputObject $parsingMessage -Append

        if ($invalidEntries) {
            $errorMessage = "["+(Get-Date -Format g)+"] " + "[ERROR] [SOURCE] $source [MESSAGE] Skipped log entries with invalid date format during trim."
            Write-Host $errorMessage
            Out-File -FilePath $OutputFile -InputObject $errorMessage -Append
        }
        
    }
    
    $string = "["+(Get-Date -Format g)+"] " + "[$Category] [SOURCE] $source [MESSAGE] $Message"

    Write-Host $string

    Out-File -FilePath $OutputFile -InputObject $string -Append
    Return
}
Set-Alias -Name 'syslog' -Value 'Write-Syslog'