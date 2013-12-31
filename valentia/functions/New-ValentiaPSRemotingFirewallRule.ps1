#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

function New-ValentiaPSRemotingFirewallRule
{

<#

.SYNOPSIS 
Create New Firewall Rule for PowerShell Remoting

.DESCRIPTION
Will allow PowerShell Remoting port for firewall

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-PSRemotingFirewallRule
--------------------------------------------
Add PowerShellRemoting-In accessible rule to Firewall.

#>


    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Input PowerShellRemoting-In port. default is 5985")]
        [int]
        $PSRemotePort = 5985,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input Name of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Name = "PowerShellRemoting-In",

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input Decription of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Description = "Windows PowerShell Remoting required to open for public connection. not for private network.",

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input Group of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Group = "Windows Remote Management"
    )

    if (-not((Get-NetFirewallRule | where Name -eq $Name) -and (Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq $PSRemotePort)))
    {
        Write-Verbose ("Windows PowerShell Remoting port TCP $PSRemotePort was not opend. Set new rule '{1}'" -f $PSRemotePort, $Name)
        New-NetFirewallRule `
            -Name $Name `
            -DisplayName $Name `
            -Description $Description `
            -Group $Group `
            -Enabled True `
            -Profile Any `
            -Direction Inbound `
            -Action Allow `
            -EdgeTraversalPolicy Block `
            -LooseSourceMapping $False `
            -LocalOnlyMapping $False `
            -OverrideBlockRules $False `
            -Program Any `
            -LocalAddress Any `
            -RemoteAddress Any `
            -Protocol TCP `
            -LocalPort $PSRemotePort `
            -RemotePort Any `
            -LocalUser Any `
            -RemoteUser Any 
    }
    else
    {
        Write-Verbose "Windows PowerShell Remoting port TCP 5985 was alredy opened. Get Firewall Rule."
        Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq 5985
    }

    if ((Get-WinSystemLocale).Name -eq "ja-JP")
    {
        $japanesePSRemoteingEnableRule = "Windows リモート管理 (HTTP 受信)"
        if (-not((Get-NetFirewallRule | where DisplayName -eq $japanesePSRemoteingEnableRule | where Profile -ne "Any") -and (Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq $PSRemotePort)))
        {
            Write-Verbose ("日本語OSと検知しました。'{0}' という名称で TCP '{1}' をファイアウォールに許可します。" -f $japanesePSRemoteingEnableRule, 5985)
            New-NetFirewallRule `
                -Name $japanesePSRemoteingEnableRule `
                -DisplayName $japanesePSRemoteingEnableRule `
                -Description $Description `
                -Group $Group `
                -Enabled True `
                -Profile Any `
                -Direction Inbound `
                -Action Allow `
                -EdgeTraversalPolicy Block `
                -LooseSourceMapping $False `
                -LocalOnlyMapping $False `
                -OverrideBlockRules $False `
                -Program Any `
                -LocalAddress Any `
                -RemoteAddress Any `
                -Protocol TCP `
                -LocalPort $PSRemotePort `
                -RemotePort Any `
                -LocalUser Any `
                -RemoteUser Any 
        }
    }
}
