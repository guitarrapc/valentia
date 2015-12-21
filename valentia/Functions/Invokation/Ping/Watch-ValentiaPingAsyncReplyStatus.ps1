#Requires -Version 3.0

#-- ping Connection to the host --#

# PingAsync

<#
.SYNOPSIS 
Monitor host by Ping for selected Second

.DESCRIPTION
This function will pingasync to the host.
You can set Interval seconds and endup limitCount to prevent eternal execution.

.NOTES
Author: guitarrapc
Created: 27/July/2014

.EXAMPLE
Watch-ValentiaPingAsyncReplyStatus -deploygroups 192.168.100.100 -DesiredStatus $true -limitCount 1000 | ft
--------------------------------------------
Continuous ping to the 192.168.100.100 for sleepSec 1 sec. (default)
This will break if host is reachable or when count up to limitCount 1000.
#>
function Watch-ValentiaPingAsyncReplyStatus
{

    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$deploygroups,

        [parameter(mandatory = $true, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [bool]$DesiredStatus = $true,

        [parameter(mandatory = $false, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [int]$sleepSec = 1,

        [parameter(mandatory = $false, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [int]$limitCount = 100
    )

    process
    {
        $i = 0
        while ($true)
        {
            $date = Get-Date
            $hash = pingAsync -HostNameOrAddresses $ipaddress `
            | %{
                Add-Member -InputObject $_ -MemberType NoteProperty -Name Date -Value $date -Force -PassThru
            }
        
            Write-Verbose ("Filtering status as '{0}'" -f $DesiredStatus)
            $hash `
            | where IsSuccess -eq $DesiredStatus `
            | where HostNameOrAddress -in $ipaddress.IPAddressToString `
            | %{$result = $ipaddress.Remove($_.HostNameOrAddress)
                if ($result -eq $false)
                {
                    throw "failed to remove ipaddress '{0}' from list" -f $_.HostNameOrAddress
                }
                else
                {
                    Write-Host ("ipaddress '{0}' turned to be DesiredStatus '{1}'" -f "$($_.HostNameOrAddress -join ', ')", $DesiredStatus) -ForegroundColor Green
                }
            }

            $count = ($ipaddress | measure).count

            if ($count -eq 0)
            {
                Write-Host ("HostnameOrAddress '{0}' IsSuccess : '{1}'. break monitoring" -f $($hash.HostNameOrAddress -join ", "), $DesiredStatus) -ForegroundColor Cyan
                $hash
                break;
            }
            elseif ($i -ge $limitCount)
            {
                write-Warning ("exceeed {0} count of sleep. break." -f $limitCount)
                $hash
                break;
            }
            else
            {
                Write-Verbose ("sleep {0} second for next status check." -f $sleepSec)
                $hash
                sleep -Seconds $sleepSec
                $i++
            }
        }
    }

    end
    {
        $end = Get-Date
        Write-Host ("Start Time  : {0}" -f $start) -ForegroundColor Cyan
        Write-Host ("End   Time  : {0}" -f $end) -ForegroundColor Cyan
        Write-Host ("Total Watch : {0}sec" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Cyan
    }

    begin
    {
        $start = Get-Date
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        $ipaddress = New-Object 'System.Collections.Generic.List[ipaddress]'
        Get-ValentiaGroup -DeployGroups $deploygroups | %{$ipaddress.Add($_)}
    }
}