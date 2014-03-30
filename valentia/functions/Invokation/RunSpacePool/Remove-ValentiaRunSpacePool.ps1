#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Close and Dispose PowerShell Runspace Pool.

.DESCRIPTION
This function Close runspace pool, then dispose.

.NOTES
Author: guitarrapc
Created: 14/Feb/2014

.EXAMPLE
Remove-ValentiaRunspacePool -RunSpacePool $pool
#>
function Remove-ValentiaRunSpacePool
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Specify RunSpace Pool to close and dispose.")]
        [System.Management.Automation.Runspaces.RunspacePool]
        $Pool
    )

    try
    {
        $script:ErrorActionPreference = $valentia.errorPreference
        $Pool.Close()
        $Pool.Dispose()
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        Write-Error $_
    }
}