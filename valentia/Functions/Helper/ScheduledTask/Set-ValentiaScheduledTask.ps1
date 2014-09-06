#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and define them as enumerable.

.DESCRIPTION
You can pass several task scheduler definition at once.

.NOTES
Author: guitarrapc
Created: 11/Aug/2014

.EXAMPLE
$param = @{
    taskName          = "Sample Repeatable Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]::Now
    ScheduledTimeSpan = (New-TimeSpan -Minutes 5)
    ScheduledDuration = ([TimeSpan]::MaxValue)
    Hidden            = $true
    Disable           = $false
    Force             = $true
},
@{
    taskName          = "Sample Daily Task"
    Description       = "None"
    taskPath          = "\"
    execute          = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]"00:00:00"
    Daily             = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
},
@{
    taskName          = "Sample OneTime Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
}

$Credential = Get-ValentiaCredential

foreach ($p in $param.GetEnumerator())
{
    Set-ValentiaScheduledTask @p -Credential $Credential
}
#>

function Set-ValentiaScheduledTask
{
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0)]
        [string]
        $execute,

        [parameter(
            Mandatory = 0,
            Position  = 1)]
        [string]
        $argument,
    
        [parameter(
            Mandatory = 1,
            Position  = 2)]
        [string]
        $taskName,
    
        [parameter(
            Mandatory = 1,
            Position  = 3)]
        [string]
        $taskPath,

        [parameter(
            Mandatory = 1,
            Position  = 4)]
        [datetime[]]
        $ScheduledAt,

        [parameter(
            Mandatory = 0,
            Position  = 5,
            parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]
        $ScheduledTimeSpan,

        [parameter(
            Mandatory = 0,
            Position  = 6,
            parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]
        $ScheduledDuration,

        [parameter(
            Mandatory = 0,
            Position  = 7,
            parameterSetName = "Daily")]
        [bool]
        $Daily,

        [parameter(
            Mandatory = 0,
            Position  = 8,
            parameterSetName = "Once")]
        [bool]
        $Once,

        [parameter(
            Mandatory = 0,
            Position  = 9)]
        [string]
        $Description,

        [parameter(
            Mandatory = 0,
            Position  = 10)]
        [PScredential]
        $Credential = $null,

        [parameter(
            Mandatory = 0,
            Position  = 11)]
        [bool]
        $Disable = $true,

        [parameter(
            Mandatory = 0,
            Position  = 12)]
        [bool]
        $Hidden = $true,

        [parameter(
            Mandatory = 0,
            Position  = 13)]
        [bool]
        $Force = $false
    )

    if (Test-Path $execute)
    {
        $action = if ($argument -ne "")
        {
            New-ScheduledTaskAction -Execute $execute -Argument $Argument
        }
        else
        {
            New-ScheduledTaskAction -Execute $execute
        }

        $trigger = if ($ScheduledTimeSpan)
        {
            $ScheduledTimeSpanPair = New-valentiaZipPairs -first $ScheduledTimeSpan -Second $ScheduledDuration
            $ScheduledAtPair = New-valentiaZipPairs -first $ScheduledAt -Second $ScheduledTimeSpanPair
            $ScheduledAtPair | %{New-ScheduledTaskTrigger -At $_.Item1 -RepetitionInterval $_.Item2.Item1 -RepetitionDuration $_.Item2.Item2 -Once}
        }
        elseif ($Daily)
        {
            $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Daily}
        }
        elseif ($Once)
        {
            $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Once}
        }

        $settings = New-ScheduledTaskSettingsSet -Disable:$Disable -Hidden:$Hidden
        $scheduledTask = New-ScheduledTask -Description $Description -Action $action -Settings $settings -Trigger $trigger

        if ($force)
        {
            if ($null -ne $Credential)
            {
                Register-ScheduledTask -InputObject $scheduledTask -TaskName $taskName -TaskPath $taskPath -User $Credential.UserName -Password $Credential.GetNetworkCredential().Password -Force
            }
            else
            {
                Register-ScheduledTask -InputObject $scheduledTask -TaskName $taskName -TaskPath $taskPath
            }
        }
        elseif (-not(Get-ScheduledTask | where TaskName -eq $taskName | where TaskPath -eq $taskPath))
        {
            if ($null -ne $Credential)
            {
                Register-ScheduledTask -InputObject $scheduledTask -TaskName $taskName -TaskPath $taskPath -User $Credential.UserName -Password $Credential.GetNetworkCredential().Password
            }
            else
            {
                Register-ScheduledTask -InputObject $scheduledTask -TaskName $taskName -TaskPath $taskPath
            }
        }
        else
        {
            Write-Warning ("'{0}' already exist on path '{1}'." -f $taskName, $taskPath)
        }
    }
    else
    {
        Write-Warning ("'{0}' not found." -f $execute)
    }
}