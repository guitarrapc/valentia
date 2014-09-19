#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Set WsMan Max Memory Per user to prevent PowerShell failed with large memory usage. 

.DESCRIPTION
This user is allowed a maximum memory. 0 will be unlimited.
Default value : 1024 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 15/Feb/2014

.EXAMPLE
Set-ValentiaWsManMaxMemoryPerShellMB -MaxMemoryPerShellMB 0
--------------------------------------------
set as unlimited
#>
function Set-ValentiaWsManMaxMemoryPerShellMB
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input MaxMemoryPerShellMB. 0 will be unlimited.")]
        [int]
        $MaxMemoryPerShellMB,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Set WSMan Path.")]
        [string]
        $MaxMemoryPerShellMBPath = "WSMan:\localhost\Shell\MaxMemoryPerShellMB"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest
    
    if (-not((Get-ChildItem $MaxMemoryPerShellMBPath).Value -eq $MaxMemoryPerShellMB))
    {
        Set-Item -Path $MaxMemoryPerShellMBPath -Value $MaxMemoryPerShellMB -Force -PassThru
    }
    else
    {
        ("Current value for MaxMemoryPerShellMB is {0}." -f $MaxMemoryPerShellMB) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxMemoryPerShellMBPath
    }
}
