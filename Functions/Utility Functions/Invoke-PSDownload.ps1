function Invoke-PSDownload {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$URL,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$fullPath,

        [Parameter(Position = 2)]
        [Switch]$disableLogging #Should only be used when a public function silently downloads a required file
    )

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $web_client = New-Object System.Net.WebClient
        $web_client.DownloadFile($url,$fullPath)
        if (!($disableLogging)) {
            Write-Syslog -category "INFO" -message "Downloaded: $fullPath" -displayMessage
        }
        
    }
    catch {
        #Leaving this on by deafult to prevent issues bug hunting
        Write-SysLog -category "ERROR" -message "Failed to download $url with error: $($_.Exception)" -displayMessage
    }
}