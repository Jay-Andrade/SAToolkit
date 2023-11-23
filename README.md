SACommon is a publically available PowerShell module, it contains numerous common standardized functions that can be used in scripting and automation on client devices.

Please use GitHub issues to note any bugs or request new functions (Prepend new functions with "Function Request:)

#######################################################################################

Development Guidelines:

General:
- Any code that is considered essential and must run when the module is imported must be added to SACommon.psm1
- All code should be commented to a reasonable degree
- When a new version of the module is ready to be published, it will need to be 'released' in order to be picked up by Chocolatey
- At least ** hours should be given after a release before it can be assumed that the new version has been disseminated to most devices

ALL Functions (Production and Utility):
- Should have their own .ps1 file named after the function, containing only the function and it's comments
- Should follow standard Microsoft naming guidelines Verb-Noun, using approved verbs only (Get-Verb)
- All logging should be done using Write-Syslog, always call both -displayMessage and -displaySource
- Should be developed to allow for multiple possible use cases
- Should be reasonably resliant against scripter error
- Should aim to never fail silently, and should always log on success or failure
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

