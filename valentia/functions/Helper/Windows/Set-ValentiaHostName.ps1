#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

# rename

<#
.SYNOPSIS 
Change Computer name as specified usage.

.DESCRIPTION
To control hosts, set prefix for each client with IPAddress octets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-valentiaHostName -HostUsage web
--------------------------------------------
Change Hostname as web-$PrefixHostName-$PrefixIpString-Ip1-Ip2-Ip3-Ip4
#>
function Set-ValentiaHostName
{
    [CmdletBinding()]  
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Set Prefix IpString for hostname if required.")]
        [string]
        $PrefixIpString = $valentia.prefic.ipstring,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Set this switch to check whatif.")]
        [switch]
        $WhatIf
    )

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        # Get IpAddress
        $ipAddress = ([Net.Dns]::GetHostAddresses('').IPAddressToString | Select-String -Pattern "^\d*.\.\d*.\.\d*.\.\d*.").line

        # Replace . of IpAddress to -
        $ipAddressString = $ipAddress -replace "\.","-"

        # Create New Host Name
        $newHostName = $HostUsage + "-" + $PrefixIpString + $ipAddressString

        $currentHostName = [Net.Dns]::GetHostName()
    }
    
    process
    {
        if ( $currentHostName -eq $newHostName)
        {
            Write-Verbose ("Current HostName [ {0} ] was same as new HostName [ {1} ]. Nothing Changed." -f $currentHostName, $newHostName)
        }
        else
        {
            if ($PSBoundParameters.WhatIf.IsPresent -ne $true)
            {
                Write-Warning -Message ("Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
                Rename-Computer -NewName $newHostName -Force
            }
            else
            {
                $Host.UI.WriteLine("what if: Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
            }
        }
    }
}
