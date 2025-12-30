<#
.SYNOPSIS
This function will query the system and return basic information about the system.
It's designed as an improved, more accurate, and more concise version of Get-ComputerInfo

.EXAMPLE
$systemInfo = Get-SystemInfo
#>
function Get-SystemInfo
{
    try {
        #Get information on the system
        if (((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType) -eq 2){
            $dcStatus = $TRUE
        } else {
            $dcStatus = $FALSE
        }
        
        $computerInfo = Get-ComputerInfo
        
        $biosVersion = "$($computerInfo.BiosSystemBiosMajorVersion).$($computerInfo.BiosSystemBiosMinorVersion)"
        
        $diskInfo =Get-PSDrive C
        $diskFree = $diskInfo.Free /1GB
        $diskSize = $diskFree + ($diskInfo.used / 1GB)
        $diskSize = [int32]$diskSize
        $diskFree = [int32]$diskFree
        
        $uptime = ((Get-Date) - ($computerInfo.OsLastBootUpTime))
        $uptimeHours = [int32]$uptime.totalhours
        $uptimeDays = [math]::round($uptime.totaldays,2)
        
        $ramsticks = (Get-CimInstance win32_physicalmemory).Capacity
        $ramCapacity = 0
        foreach ($dimm in $ramsticks) {
            #In case more than 1 DIMM is present this is necessary
            $ramCapacity += $dimm / 1GB
        }

        #More reliable than using output from Get-ComputerInfo
        $ReleaseID = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId
        if ($ReleaseID -like "2009") {
            $ReleaseID = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion
        }

        #Lenovo stores model in format '21AK002LUS' in .CSModel, and format 'ThinkPad P14s Gen 3' in .CsSystemFamily
        #Dell and HP do not follow this and store the friendly-named model name in .CSModel
        if ($computerInfo.CsManufacturer.tolower() -notlike "lenovo") {
            $manufacturer = $computerInfo.CsModel
        } else {
            $manufacturer = $computerInfo.CsSystemFamily
        }
        
        $rebootPending = Test-PendingReboot

        $eidJoinData = Get-EntraIDJoinStatus
        if ($eidJoinData -ne "Device is not Entra ID Joined") {
            $eidStatus = "Device is Entra ID Joined to $($eidJoinData.TenantDisplayName)"
        } else {
            $eidStatus = $eidJoinData
        }

        $publicIP = Get-PublicIP

        #Add everything into an ordered hashtable
        $systemInfo = [ordered]@{
            Name = $computerInfo.CsCaption
            OS = $computerInfo.OSName
            OSVersion = $ReleaseID
            Domain = $computerInfo.CsDomain
            EntraIDJoinStatus = $eidStatus
            isDomainController = $dcStatus
            Manufacturer = $computerInfo.CsManufacturer
            Model = $manufacturer
            Processor = $computerInfo.CsProcessors
            SerialNumber = $computerInfo.BiosSeralNumber
            RebootPending = $rebootPending
            PublicIP = $publicIP
            BIOSVersion = $biosVersion
            RAM = $ramCapacity
            Disk = $diskSize
            DiskFree = $diskFree
            UptimeHours = $uptimeHours
            UptimeDays = $uptimeDays
        }

    } catch {
        Write-Syslog -Category 'ERROR' -Message "Failed to get system information. Error: $_"
        $systemInfo = $NULL
    }

    return $systemInfo
}