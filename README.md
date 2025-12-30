SAToolkit is a publically available PowerShell module for Systems Administrators, it contains numerous common standardized functions that can be used in scripting and automation on client devices. It is mainly intended a Windows Powershell environment and some functions may be incompatable with non-Windows environment.

Please use GitHub issues to note any bugs or request new functions (Prepend new functions with "Function Request:")

#######################################################################################

If you're interested in learning more about the module or it's development, please check out this blog post: https://gtio.tech/developing-a-powershell-module/

#######################################################################################

Development Guidelines:

General:
- Any code that is considered essential and must run when the module is imported must be added to SAToolkit.psm1
- All code should be commented to a reasonable degree

ALL Functions (Production and Utility):
- Should have their own .ps1 file named after the function, containing only the function, it's comments, and any aliases
- Should follow standard Microsoft naming guidelines Verb-Noun, using approved verbs only (reference Get-Verb)
- All logging should be done using Write-Syslog
- Should be developed to allow for multiple possible use cases
- Should be reasonably resliant against scripter error
- Should aim to never fail silently, and never make changes silently
- Only mandatory parameters should have the tag (Mandatory = $TRUE) for clarity purposes
- Should aim to use clear and readable code that is still concise

Production Functions:
- A production function is a function that is made available to the scripter using the module
- Should go in the "Functions" folder
- Should have a comment-based help system that provides a useful return when referenced by Get-Help (IE: Parameter explinations and examples).
- Must have their name defined in the manifest (.psd1) file, along with any aliases to export

Utility Functions
- A utility function is a function that is not made available to the scripter using the module and is only used internally in the module's code
- Should be placed in the "Utility Functions" sub folder of the "Functions" folder
- Utility functions do not need a comment-based help system, regular commenting is sufficuent

#######################################################################################

Credit:

- [DeployWindowsCom](https://github.com/DeployWindowsCom/DeployWindows-Scripts/blob/master/Azure%20AD/Get-AadJoinInformation.ps1) for the bones of Get-EntraIDJoinStatus, and all of it's associated C# code

#######################################################################################