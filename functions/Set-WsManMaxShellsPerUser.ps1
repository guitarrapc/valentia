#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

function Set-WsManMaxShellsPerUser
{

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
Set-WsManMaxShellsPerUser -ShellsPerUser 100
--------------------------------------------
set as 100

#>

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
    
    if (-not((Get-ChildItem $MaxShellsPerUserPath).Value -eq $ShellsPerUser))
    {
        Set-Item -Path $MaxShellsPerUserPath -Value $ShellsPerUser -Force
    }
    else
    {
        Write-Verbose ("WinRM Trustedhosts was alredy enabled for {0}." -f $ShellsPerUser)
        Get-ChildItem $MaxShellsPerUserPath
    }
}
