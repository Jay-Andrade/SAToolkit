<#
.SYNOPSIS
This function will search any syslog file to isolate items from a specific source. Useful for debugging issues using logs pulled from endpoints.
Assumes use of a standard format for source identification of each log entry. 

.PARAMETER Source
Name of the source to search for in the log file.

.PARAMETER LogFilePath
The path of the Logfile to search. Optional parameter. Defaults to "$env:temp\syslog.log"

.EXAMPLE
Search-SyslogFile -Source '- MONITOR - Secure Boot Status' -LogFilePath "C:\users\example\downloads\syslog(4).log"
Will search the specified logfile for log lines from the specified source.

.EXAMPLE
Search-SyslogFile -Source '- MISC - Force Intune Compliance Sync'
Will search the default logfile for log lines from the specified source.
#>

#Mostly written by ChatGPT 4o with moderate refinement by Jay, then moved into function format. 
#Regex sucks and AI is a hell of a lot better at it than I am.
function Search-SyslogFile {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$Source,

        [Parameter(Position = 1)]
        [String]$LogFilePath = "$env:temp\syslog.log",

        [Parameter(Position = 2)]
        [Switch]$ShowFullLogLines = $false
    )

    $validTypes = @("CLEAR", "CONFIGURE", "INSTALL", "MANAGE", "MISC", "MONITOR", "REMEDIATE", "REPORT", "SYNC", "TEST") #Adjust these if using a different set of source identification keywords

    #Ensure the source filter follows the expected format
    if ($Source -notmatch "^- ($($validTypes -join '|')) - .+$") {
        Write-Syslog -Category 'WARN' -Message "Non-standard source filter format. Expected format: '- TYPE - Name'"
    }

    #Check if the log file exists
    if (-Not (Test-Path -Path $LogFilePath)) {
        Write-Syslog -Category 'ERROR' -Message "Log file not found: $LogFilePath"
        return
    }

    #Read log file and filter based on the source name
    $filteredLogs = Get-Content -Path $LogFilePath | Where-Object { $_ -like "*$Source*" }

    #If loglines exist, output them. Either the full logline or the abridged version (default) for easier legibility.
    if ($filteredLogs.Count -eq 0) {
        Write-Syslog -Category 'WARN' -Message "No logs found for source: $Source"
    } elseif ($ShowFullLogLines -eq $false) {
        $filteredLogs | ForEach-Object {
            if ($_ -match "^\[(.*?)\] \[.*?\] \[.*?\] - .*? \[MESSAGE\] (.*)$") {
                Write-Output "[$($matches[1])] [MESSAGE] $($matches[2])"
            }
        }
    } elseif ($ShowFullLogLines -eq $true) {
        $filteredLogs | ForEach-Object { Write-Output $_ }
    }
}
Set-Alias -Name 'Search-LogFile' -Value 'Search-SyslogFile'