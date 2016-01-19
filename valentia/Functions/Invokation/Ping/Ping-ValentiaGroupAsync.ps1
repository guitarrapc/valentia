#Requires -Version 3.0

#-- ping Connection to the host --#

# PingAsync

<#
.SYNOPSIS 
Ping to the host by IP Address Asynchronous

.DESCRIPTION
This Cmdlet will ping and get reachability to the host.

.NOTES
Author: guitarrapc
Created: 03/Feb/2014

.EXAMPLE
Ping-ValentiaGroupAsync production-hoge.ps1
--------------------------------------------
Ping production-hoge.ps1 from deploy group branch path
#>

function Ping-ValentiaGroupAsync
{
    [OutputType([PingEx.PingResponse[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $true, ValueFromPipeLine = 1, ValueFromPipeLineByPropertyName = 1, HelpMessage = "Input target computer name or ipaddress to test ping.")]
        [string[]]$HostNameOrAddresses,

        [Parameter(Position = 1, mandatory = $false, HelpMessage = "Input timeout ms wait for the responce answer.")]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout = $valentia.ping.timeout,

        [Parameter(Position = 2, mandatory = $false, HelpMessage = "Input timeout ms wait for the responce answer.")]
        [ValidateNotNullOrEmpty()]
        [int]$DnsTimeout = $valentia.ping.timeout,

        [Parameter(Position = 3, mandatory = $false, HelpMessage = "Change return type to bool only.")]
        [ValidateNotNullOrEmpty()]
        [switch]$quiet
    )

    begin
    {
        $list = New-Object System.Collections.Generic.List["string"];
    }

    process
    {
        $target = (Get-ValentiaGroup -DeployGroup $HostNameOrAddresses);
        foreach ($item in $target){ $list.Add($item); }
    }

    end
    {
        if ($quiet)
        {
            [PingEx.NetworkInformationExtensions]::PingAsync($list, [TimeSpan]::FromMilliseconds($Timeout), [TimeSpan]::FromMilliseconds($DnsTimeout)).Result.Status;
        }
        else
        {
            [PingEx.NetworkInformationExtensions]::PingAsync($list, [TimeSpan]::FromMilliseconds($Timeout), [TimeSpan]::FromMilliseconds($DnsTimeout)).Result;
        }        
    }
}