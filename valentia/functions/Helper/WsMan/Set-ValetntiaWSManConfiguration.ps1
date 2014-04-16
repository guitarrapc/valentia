#Requires -Version 3.0

#-- Public Functions for WSMan Parameter Configuration --#

function Set-ValetntiaWSManConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'")]
        [ValidateNotNullOrEmpty()]
        [int]
        $ShellsPerUser = $valentia.wsman.MaxShellsPerUser,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'")]
        [ValidateNotNullOrEmpty()]
        [int]
        $MaxMemoryPerShellMB = $valentia.wsman.MaxMemoryPerShellMB,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Configure WSMan MaxProccessesPerShell to improve performance")]
        [ValidateNotNullOrEmpty()]
        [int]
        $MaxProccessesPerShell = $valentia.wsman.MaxProccessesPerShell
    )

    $ErrorActionPreference = $valentia.errorPreference
    Set-StrictMode -Version latest

    "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'" | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxShellsPerUser -ShellsPerUser $ShellsPerUser

    "Configure WSMan MaxMBPerUser to prevent huge memory consumption crach PowerShell issue." | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxMemoryPerShellMB -MaxMemoryPerShellMB $MaxMemoryPerShellMB

    "Configure WSMan MaxProccessesPerShell to improve performance" | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxProccessesPerShell -MaxProccessesPerShell $MaxProccessesPerShell

    "Restart-Service WinRM -PassThru" | Write-ValentiaVerboseDebug
    Restart-Service WinRM -PassThru
}