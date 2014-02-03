#Requires -Version 3.0

#-- ping Connection to the host --#

# PingAsync
function Ping-ValentiaGroupAsync
{

<#
.SYNOPSIS 
Ping to the host by IP Address Asynchronous

.DESCRIPTION
This Cmdlet will ping and get reachability to the host.

.NOTES
Author: guitarrapc
Created: 02/03/2014

.EXAMPLE
Ping-ValentiaGroupAsync production-hoge.ps1
--------------------------------------------
Ping production-hoge.ps1 from deploy group branch path

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            ValueFromPipeLine = 1,
            ValueFromPipeLineByPropertyName = 1,
            HelpMessage = "Input target computer name or ipaddress to test ping.")]
        [string[]]
        $HostNameOrAddresses,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input timeout ms wait for the responce answer.")]
        [ValidateNotNullOrEmpty()]
        [int]
        $Timeout = $valentia.ping.timeout,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input buffer size for the data size send/recieve with ICMP send.")]
        [ValidateNotNullOrEmpty()]
        [byte[]]
        $Buffer = $valentia.ping.buffer,

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Input ttl for the ping option.")]
        [ValidateNotNullOrEmpty()]
        [int]
        $Ttl = $valentia.ping.pingOption.ttl,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Input dontFragment for the ping option.")]
        [ValidateNotNullOrEmpty()]
        [bool]
        $dontFragment = $valentia.ping.pingOption.dontfragment
    )

    begin
    {
        # Preference
        $script:ErrorActionPreference = $valentia.errorPreference

        # new object for event and job
        $pingOptions = New-Object Net.NetworkInformation.PingOptions($Ttl, $dontFragment)
        $tasks = New-Object System.Collections.Generic.List[PSCustomObject]
    }

    process
    {
        foreach ($hostNameOrAddress in $HostNameOrAddresses)
        {
            $ping  = New-Object System.Net.NetworkInformation.Ping

            Write-Verbose ("Execute SendPingAsync to host '{0}'." -f $hostNameOrAddress)
            $PingReply = $ping.SendPingAsync($hostNameOrAddress, $timeout, $buffer, $pingOptions)

            $task = [PSCustomObject]@{
                HostNameOrAddress = $hostNameOrAddress
                Task              = $PingReply
                Ping              = $ping}
            $tasks.Add($task)
        }
    }

    end
    {
        Write-Verbose "WaitAll for Task PingReply have been completed."
        [System.Threading.Tasks.Task]::WaitAll($tasks.Task)
        
        foreach ($task in $tasks)
        {
            [System.Net.NetworkInformation.PingReply]$result = $task.Task.Result
            [PSCustomObject]@{
                Id                 = $task.Task.Id
                HostNameOrAddress  = $task.HostNameOrAddress
                Status             = $result.Status
                IsSuccess          = $result.Status -eq [Net.NetworkInformation.IPStatus]::Success
                RoundtripTime      = $result.RoundtripTime
            }

            Write-Debug "Dispose Ping Object"
            $task.Ping.Dispose()
            
            Write-Debug "Dispose PingReply Object"
            $task.Task.Dispose()
        }
    }
}