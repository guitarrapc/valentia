#Requires -Version 3.0

#-- Helper for valentia --#

# cleanResult
<#
.SYNOPSIS 
Clean up valentia task previous result.

.DESCRIPTION
Clear valentia last result.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
Invoke-ValentiaCleanResult
#>
function Invoke-ValentiaCleanResult
{
    [CmdletBinding()]
    param
    (
    )

    $valentia.Result.Clear()
    $valentia.Result = [ordered]@{
        SuccessStatus         = @()
        TimeStart             = [datetime]::Now.DateTime
        ScriptToRun           = ""
        DeployMembers         = @()
        Result                = $valentia.Result.Result = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        ErrorMessageDetail    = @()
    }
}
