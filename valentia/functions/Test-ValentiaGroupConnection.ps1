#Requires -Version 3.0

#-- Test Connection to the host --#

# pingAsync
function Test-ValentiaGroupConnection
{

<#
.SYNOPSIS 
return ipaddress with selected status of the 

.DESCRIPTION
This Cmdlet will test reachability to the host with ping result.

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
        [PSObject[]]
        $DeployGroupPingResults
    )

    dynamicParam
    {
        $parameters = [enum]::GetNames([System.Net.NetworkInformation.IPStatus]) `
        | %{$count = 1}{
            @{name         = $_
              options      = $true
              mandatory    = $false
              validateSet  = $true
              position     = $count}
            $count++
        }

        $dynamicParamLists = New-ValentiaDynamicParamList -dynamicParams $parameters
        New-ValentiaDynamicParamMulti -dynamicParamLists $dynamicParamLists
    }

    begin
    {
        # Preference
        $script:ErrorActionPreference = $valentia.errorPreference

        # return parameters which used for function
        $ipStatuses = $PSBoundParameters.Keys | where {$_ -in [enum]::GetNames([System.Net.NetworkInformation.IPStatus])}
    }

    process
    {
        foreach ($DeployGroupPingResult in $DeployGroupPingResults)
        {
            Write-Verbose ("filter ipaddress for status for status selected '{0}'" -f ($ipStatuses -join ", "))
            $DeployGroupPingResult | where Status -in $ipStatuses
        }
    }
}