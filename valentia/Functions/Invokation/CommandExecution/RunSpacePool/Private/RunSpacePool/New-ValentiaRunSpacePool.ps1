#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Create a PowerShell Runspace Pool.

.DESCRIPTION
This function returns a runspace pool, a collection of runspaces that PowerShell pipelines can be executed.
The number of available pools determines the maximum number of processes that can be running concurrently.
This enables multithreaded execution of PowerShell code.

.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$pool = New-ValentiaRunspacePool -minPoolSize 50 -maxPoolSize 50

--------------------------------------------
Above will creates a pool of 10 runspaces
#>
function New-ValentiaRunSpacePool
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position =0, mandatory = $false, HelpMessage = "Defines the minium number of pipelines that can be concurrently (asynchronously) executed on the pool.")]
        [int]$minPoolSize = $valentia.runspace.pool.minSize,

        [Parameter(Position = 1, mandatory = $false, HelpMessage = "Defines the maximum number of pipelines that can be concurrently (asynchronously) executed on the pool.")]
        [int]$maxPoolSize = $valentia.runspace.pool.maxSize
    )

    try
    {
        $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # RunspaceFactory.CreateRunspacePool (Int32, Int32, InitialSessionState, PSHost)
        #   - Creates a runspace pool that specifies minimum and maximum number of opened runspaces, 
        #     and a custom host and initial session state information that is used by each runspace in the pool.
        $pool = [runspacefactory]::CreateRunspacePool($minPoolSize, $maxPoolSize,  $sessionstate, $Host)	
    
        # Only support STA mode. No MTA mode.
        $pool.ApartmentState = "STA"
    
        # open RunSpacePool
        $pool.Open()
    
        return $pool
    }
    catch
    {
        $valentia.Result.SuccessStatus += $false
        $valentia.Result.ErrorMessageDetail += $_
        Write-Error $_
    }
}