<#
.SYNOPSIS
This function returns information on if the device is joined to Entra ID (Formerly known as Azure AD).

.EXAMPLE
$joinData = Get-EntraIDJoinStatus
#>
function Get-EntraIDJoinStatus {

    #Credit to https://github.com/DeployWindowsCom/DeployWindows-Scripts/blob/master/Azure%20AD/Get-AadJoinInformation.ps1 for the bones of this function and all of the .NET functionality (.NET functionality stored in Utility Function)
    #A large amount of the original code by DeployWindowsCom has been commented out but left in place. More testing is needed to determine if the data it provides access to is needed for the use case of this function

    Add-Type -Path "$PSScriptRoot\Utility Functions\DSREG.cs"
    
    $pcszTenantId = $null
    $ptrJoinInfo = [IntPtr]::Zero

    $retValue = [NetAPI32]::NetGetAadJoinInformation($pcszTenantId, [ref]$ptrJoinInfo);

    if ($retValue -eq 0) 
    {

        $ptrJoinInfoObject = New-Object NetAPI32+DSREG_JOIN_INFO
        $joinInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinInfo, [System.Type] $ptrJoinInfoObject.GetType())

        # $ptrUserInfo = $joinInfo.pUserInfo
        # $ptrUserInfoObject = New-Object NetAPI32+DSREG_USER_INFO
        # $userInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrUserInfo, [System.Type] $ptrUserInfoObject.GetType())
        # $userInfo | fl

        # Write-Host "Device is $([NetAPI32+DSREG_JOIN_TYPE]($joinInfo.joinType))"
        # switch ($joinInfo.joinType)
        # {
        #     ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_DEVICE_JOIN.value__) {
        #         $joinType = "Device is joined"
        #     }
        #     ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_UNKNOWN_JOIN.value__) {
        #         $joinType = "Device is not joined, or unknown type"
        #     }
        #     ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_WORKPLACE_JOIN.value__) {
        #         $joinType = "Device workplace joined"
        #     }
        # }

        # $ptrJoinCertificate = $joinInfo.pJoinCertificate
        # $ptrJoinCertificateObject = New-Object NetAPI32+CERT_CONTEX
        # $joinCertificate = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinCertificate, [System.Type] $ptrJoinCertificateObject.GetType())
        #$JoinCertificate | fl

        #Release pointers
        [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinInfo) | Out-Null
        # [System.Runtime.InterOpServices.Marshal]::Release($ptrUserInfo) | Out-Null
        # [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinCertificate) | Out-Null

        # $returnPSCO = New-Object PSObject
        # $returnPSCO | Add-Member -MemberType NoteProperty -Name 'JoinInfo' -Value $joinInfo
        # $returnPSCO | Add-Member -MemberType NoteProperty -Name 'JoinType' -Value $joinType

        # return $returnPSCO

        return $joinInfo
    }
    else {
        return "Device is not Entra ID Joined"
    }
}
Set-Alias -Name 'Get-AADJoinStatus' -Value 'Get-EntraIDJoinStatus'
Set-Alias -Name 'Get-AzureADJoinStatus' -Value 'Get-EntraIDJoinStatus'