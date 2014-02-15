#Requires -Version 3.0

#-- Helper for valentia --#

# clean
function Invoke-ValentiaClean
{

<#
.SYNOPSIS 
Clean up valentia task variables.

.DESCRIPTION
Clear valentia variables for each task, and remove then.
valentia only keep default variables after this cmdlet has been run.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
Invoke-ValentiaClean
--------------------------------------------
Clean up valentia variables stacked in the $valentia variables.

#>

    [CmdletBinding()]
    param
    (
    )

    if ($valentia.context.Count -gt 0) 
    {
        $currentContext = $valentia.context.Peek()
        $env:path = $currentContext.originalEnvPath
        Set-Location $currentContext.originalDirectory
        $global:ErrorActionPreference = $currentContext.originalErrorActionPreference

        # Erase Context
        [void] $valentia.context.Clear()
    }

}
