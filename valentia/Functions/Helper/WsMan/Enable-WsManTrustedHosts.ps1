#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Enable WsMan Trusted hosts

.DESCRIPTION
Specify Trustedhosts to allow

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-WsManTrustedHosts
--------------------------------------------
allow all hosts as * 
#>
function Enable-ValentiaWsManTrustedHosts
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Specify TrustedHosts to allow.")]
        [string]$TrustedHosts,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Specify path to WSMan TrustedHosts.")]
        [string]$TrustedHostsPath = "WSman:localhost\client\TrustedHosts"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-ChildItem $TrustedHostsPath).Value -eq $TrustedHosts))
    {
        Set-Item -Path $TrustedHostsPath -Value $TrustedHosts -Force
    }
    else
    {
        ("WinRM Trustedhosts was alredy enabled for {0}." -f $TrustedHosts) | Write-ValentiaVerboseDebug
        Get-ChildItem $TrustedHostsPath
    }
}

