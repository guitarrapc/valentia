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
        $Buffer = $valentia.ping.buffer
    )

    begin
    {
        # Preference
        $script:ErrorActionPreference = $valentia.errorPreference

        # new object for event and job
        $script:jobs= New-Object System.Collections.Generic.List[System.Management.Automation.PSEventJob]
        $global:____responceList = New-Object System.Collections.Generic.List[PSCustomObject]
    }

    process
    {
        try
        {
            foreach ($hostNameOrAddress in $HostNameOrAddresses)
            {
                # create ping object
                $ping  = New-Object System.Net.NetworkInformation.Ping

                Write-Verbose ("Register Event for Ping '{0}' and return object with PSCustomObject" -f $hostNameOrAddress)
                $eventResult = Register-ObjectEvent -Action {
                    $returnObject = $($event.SourceArgs[1].Reply `
                    | %{ [PSCustomObject]@{
                        Address       = $_.Address
                        Status        = $_.Status
                        RoundtripTime = $_.RoundtripTime
                        DeployMember  = $event.SourceArgs[1].UserState}
                    })
                    $____responceList.Add($returnObject)
                    Unregister-Event -SourceIdentifier $EventSubscriber.SourceIdentifier
                } -EventName PingCompleted -InputObject $ping

                if ($null -eq $eventResult)
                {
                    throw "event register null exception!"
                }
                else
                {
                    Write-Verbose "Add event result to the job."
                    $jobs.Add($eventResult)
                }

                Write-Verbose ("Execute Ping SendAsync event to host '{0}'." -f $hostNameOrAddress)
                $ping.SendAsync($hostNameOrAddress, $timeout, $buffer, $hostNameOrAddress);
            }

            Write-Verbose "Recieve Jon for the event."
            $result = Receive-Job $jobs

            while($____responceList.Count -lt $HostNameOrAddresses.count)
            {
                Write-Verbose ("Monitor job result until finished. Count for ____responceList : {0}, HostNameOrAddresses :{1}" -f $____responceList.count, $HostNameOrAddresses.count)
                Start-Sleep -Milliseconds 5
            }

            $____responceList
        }
        finally
        {
            Write-Verbose "Remove event Object variable"
            Remove-Variable -Name ____responceList -Force -Scope Global

            Write-Verbose "Dispose ping Object"
            $ping.Dispose()
        }
    }
}