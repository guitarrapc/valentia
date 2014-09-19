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
Remove-ValentiaRunspacePool -RunSpacePool $valentia.runspace.pool.instance
#>
function Remove-ValentiaRunSpacePool
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Specify RunSpace Pool to close and dispose.")]
        [System.Management.Automation.Runspaces.RunspacePool]$Pool = $valentia.runspace.pool.instance
    )

    $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

    try
    {
        if ($Pool)
        {
            $Pool.Close()
            $Pool.Dispose()
        }
    }
    catch
    {
        $valentia.Result.SuccessStatus += $false
        $valentia.Result.ErrorMessageDetail += $_
        Write-Error $_
    }
}