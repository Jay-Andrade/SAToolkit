[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$functions = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -Recurse -ErrorAction SilentlyContinue)

#Import the functions
#Defining functions in individual files for legibility
ForEach ($import in @($functions)) {
    Try {
        Import-Module $import.fullname
    } Catch {
        Write-Error -Message "Failed to import funtion $($import.fullname): $_"
    }
}