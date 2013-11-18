#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

# rename
function Set-ValentiaHostName
{

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

    [CmdletBinding()]  
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [string]
        $PrefixHostName = $valentia.prefix.hostname,

        $PrefixIpString = $valentia.prefic.ipstring
    )

    begin
    {
        
        # Get IpAddress
        $ipAddress = ([Net.Dns]::GetHostAddresses('').IPAddressToString | Select-String -Pattern "^\d*.\.\d*.\.\d*.\.\d*.").line

        # Replace . of IpAddress to -
        $ipAddressString = $ipAddress -replace "\.","-"

        # Create New Host Name
        $newHostName = $PrefixHostName + "-" + $HostUsage + "-" + $PrefixIpString + $ipAddressString

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
            Write-Warning -Message ("Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
            Rename-Computer -NewName $newHostName -Force
        }
    }

    end
    {
    }

}
