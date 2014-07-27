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
        [parameter(
            Mandatory = 1,
            position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $deploygroups,

        [parameter(
            Mandatory = 1,
            position  = 1)]
        [ValidateNotNullOrEmpty()]
        [bool]
        $DesiredStatus = $true,

        [parameter(
            Mandatory = 0,
            position  = 2)]
        [ValidateNotNullOrEmpty()]
        [int]
        $sleepSec = 1,

        [parameter(
            Mandatory = 0,
            position  = 3)]
        [ValidateNotNullOrEmpty()]
        [int]
        $limitCount = 100
    )

    process
    {
        $i = 0
        while ($true)
        {
            $date = Get-Date
            $hash = Get-ValentiaGroup -DeployGroups $deploygroups `
            | pingAsync `
            | %{
                Add-Member -InputObject $_ -MemberType NoteProperty -Name Date -Value $date -Force -PassThru
            }
        
            Write-Verbose ("Filtering status as '{0}'" -f $DesiredStatus)
            $count = ($hash | where IsSuccess -ne $DesiredStatus | measure).count

            if ($count -eq 0)
            {
                Write-Host ("HostnameOrAddress '{0}' IsSuccess : '{1}'. break monitoring" -f $($hash.HostNameOrAddress -join ","), $DesiredStatus) -ForegroundColor Cyan
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
    }
}
