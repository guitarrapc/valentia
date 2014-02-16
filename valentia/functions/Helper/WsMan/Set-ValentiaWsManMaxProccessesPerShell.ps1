#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

function Set-ValentiaWsManMaxProccessesPerShell
{

<#

.SYNOPSIS 
Set WsMan Max Proccesses Per Shell. 

.DESCRIPTION
Unlimit process.
Default value : 100 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 15/Feb/2014

.EXAMPLE
Set-ValentiaWsManMaxProccessesPerShell -MaxProccessesPerShell 0
--------------------------------------------
set as 100

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input MaxProccessesPerShell value.")]
        [int]
        $MaxProccessesPerShell,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Set path to WSMan MaxProccessesPerShell.")]
        [string]
        $MaxProccessesPerShellPath = "WSMan:\localhost\Shell\MaxProcessesPerShell"
    )
    
    if (-not((Get-ChildItem $MaxProccessesPerShellPath).Value -eq $MaxProccessesPerShell))
    {
        Set-Item -Path $MaxProccessesPerShellPath -Value $MaxProccessesPerShell -Force -PassThru
    }
    else
    {
        ("Current value for MaxShellsPerUser is {0}." -f $MaxProccessesPerShell) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxProccessesPerShellPath
    }
}
