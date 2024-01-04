<#
.SYNOPSIS
This function will query the system and return basic information about the module SAToolkit.

.EXAMPLE
Get-SAToolkitInfo
#>
function Get-SAToolkitInfo
{
    $helpTextA = @"
---------------------------------------------------
  _____      _______          _ _    _ _   
 / ____|  /\|__   __|        | | |  (_) |  
| (___   /  \  | | ___   ___ | | | ___| |_ 
 \___ \ / /\ \ | |/ _ \ / _ \| | |/ / | __|
 ____) / ____ \| | (_) | (_) | |   <| | |_ 
|_____/_/    \_\_|\___/ \___/|_|_|\_\_|\__|
                                             
A PowerShell toolkit for system administrators

---------------------------------------------------

Author: Jay Andrade
GitHub: https://github.com/Jay-Andrade/SAToolkit
Latest release: https://github.com/Jay-Andrade/SAToolkit/releases/latest

---------------------------------------------------

This PowerShell module contains a collection of useful tools designed to automate common items for System Administrators who 
manage a primarily Windows-based enviornment. 
                                            
If you find this module useful, please give this module a star in GitHub so others are able to discover it too!

Please check out my blog for more information on myself and on the development for this module: https://gtio.tech

---------------------------------------------------

For information on any of the functions provided by this module, please use PowerShell's built-in help feature. Each function
in this module has a synposis and at least one example useage.
    
"@

    $helpTextB = @"
Get-Help Get-SAToolkitInfo
Get-Help Get-SAToolkitInfo -Full
Get-Help Get-SAToolkitInfo -Examples

"@

    $helpTextC = "---------------------------------------------------"

    Write-Host -ForegroundColor "Magenta" $helpTextA
    Write-Host -ForegroundColor "Green" $helpTextB
    Write-Host -ForegroundColor "Magenta" $helpTextC
}