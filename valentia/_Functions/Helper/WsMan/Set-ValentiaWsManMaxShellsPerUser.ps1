#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Set WsMan Max Shells Per user to prevent "The WS-Management service cannot process the request. 

.DESCRIPTION
This user is allowed a maximum number of xx concurrent shells, which has been exceeded."
Default value : 25 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-ValentiaWsManMaxShellsPerUser -ShellsPerUser 100
--------------------------------------------
set as 100
#>
function Set-ValentiaWsManMaxShellsPerUser
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input ShellsPerUser count.")]
        [int]
        $ShellsPerUser,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Set path to WSMan MaxShellsPerUser.")]
        [string]
        $MaxShellsPerUserPath = "WSMan:\localhost\Shell\MaxShellsPerUser"
    )
    
    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-ChildItem $MaxShellsPerUserPath).Value -eq $ShellsPerUser))
    {
        Set-Item -Path $MaxShellsPerUserPath -Value $ShellsPerUser -Force -PassThru
    }
    else
    {
        ("Current value for MaxShellsPerUser is {0}." -f $ShellsPerUser) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxShellsPerUserPath
    }
}
