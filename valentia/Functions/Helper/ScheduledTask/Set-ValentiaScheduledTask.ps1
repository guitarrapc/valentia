#Requires -Version 3.0

#-- Scheduler Task Functions --#

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

# Multipole task With Credential

.EXAMPLE
$param = @{
    taskName          = "Sample No Credential Task"
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
}
Set-ValentiaScheduledTask @param

# single task without credential

.EXAMPLE
$param = @{
    taskName          = "Sample High Runlevel without Credential Task"
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
    RunLevel          = "Highest"
}
Set-ValentiaScheduledTask @param

# single task without credential and set Runlevel High

.EXAMPLE
$param = @{
    taskName          = "Sample High Runlevel with Credential Task"
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
    RunLevel          = "Highest"
}
$Credential = Get-ValentiaCredential

Set-ValentiaScheduledTask @param -Credential $Credential

# single task with credential and set Runlevel High

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Set-ValentiaScheduledTask
{
    [CmdletBinding(DefaultParameterSetName = "ScheduledDuration")]
    param
    (
        [parameter(Mandatory = 0, Position  = 0)]
        [string]$Execute,

        [parameter(Mandatory = 0, Position  = 1)]
        [string]$Argument = "",
    
        [parameter(Mandatory = 0, Position  = 2)]
        [string]$WorkingDirectory = "",

        [parameter(Mandatory = 1, Position  = 3)]
        [string]$TaskName,
    
        [parameter(Mandatory = 0, Position  = 4)]
        [string]$TaskPath = "\",

        [parameter(Mandatory = 0, Position  = 5)]
        [datetime[]]$ScheduledAt,

        [parameter(Mandatory = 0, Position  = 6, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledTimeSpan = ([TimeSpan]::FromHours(1)),

        [parameter(Mandatory = 0, Position  = 7, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledDuration = [TimeSpan]::MaxValue,

        [parameter(Mandatory = 0, Position  = 8, parameterSetName = "Daily")]
        [bool]$Daily = $false,

        [parameter(Mandatory = 0, Position  = 9, parameterSetName = "Once")]
        [bool]$Once = $false,

        [parameter(Mandatory = 0, Position  = 10)]
        [string]$Description,

        [parameter(Mandatory = 0, Position  = 11)]
        [PScredential]$Credential = $null,

        [parameter(Mandatory = 0, Position  = 12)]
        [bool]$Disable = $true,

        [parameter(Mandatory = 0, Position  = 13)]
        [bool]$Hidden = $true,

        [parameter(Mandatory = 0, Position  = 14)]
        [TimeSpan]$ExecutionTimeLimit = ([TimeSpan]::FromDays(3)),

        [parameter(Mandatory = 0,Position  = 15)]
        [ValidateSet("At", "Win8", "Win7", "Vista", "V1")]
        [string]$Compatibility = "Win8",

        [parameter(Mandatory = 0,Position  = 16)]
        [ValidateSet("Highest", "Limited")]
        [string]$Runlevel = "Limited",

        [parameter(Mandatory = 0,　Position  = 17)]
        [bool]$Force = $false
    )

    end
    {
        Write-Verbose ($VerboseMessages.CreateTask -f $TaskName, $TaskPath)
        # exist
        $existingTaskParam = 
        @{
            TaskName = $TaskName
            TaskPath = $TaskPath
        }

        $currentTask = GetExistingTaskScheduler @existingTaskParam

    #region Exclude Action Change : Only Disable / Enable Task

        if (($Execute -eq "") -and (TestExistingTaskScheduler -Task $currentTask))
        {
            switch ($Disable)
            {
                $true {
                    $currentTask | Disable-ScheduledTask
                    return;
                }
                $false {
                    $currentTask | Enable-ScheduledTask
                    return;
                }
            }
        }

    #endregion

    #region Include Action Change

        # credential
        if($Credential -ne $null)
        {
            # Credential
            $credentialParam = @{
                User = $Credential.UserName
                Password = $Credential.GetNetworkCredential().Password
            }

            # Principal
            $principalParam = 
            @{
                GroupId = "BUILTIN\Administrators"
                RunLevel = $Runlevel
            }
        }

        # validation
        if ($Execute -eq ""){ throw New-Object System.InvalidOperationException ($ErrorMessages.ExecuteBrank) }
        if (TestExistingTaskSchedulerWithPath @existingTaskParam){ throw New-Object System.InvalidOperationException ($ErrorMessages.SameNameFolderFound -f $taskName) }

        # Action
        $actionParam = 
        @{
            Argument = $Argument
            Execute = $Execute
            WorkingDirectory = $WorkingDirectory
        }

        # trigger
        $triggerParam =
        @{
            ScheduledTimeSpan = $scheduledTimeSpan
            ScheduledDuration = $scheduledDuration
            ScheduledAt = $ScheduledAt
            Daily = $Daily
            Once = $Once
        }

        # Description
        if ($Description -eq ""){ $Description = "No Description"}     

        # Setup Task items
        $action = CreateTaskSchedulerAction @actionParam
        $trigger = CreateTaskSchedulerTrigger @triggerParam
        $settings = New-ScheduledTaskSettingsSet -Disable:$Disable -Hidden:$Hidden -Compatibility $Compatibility -ExecutionTimeLimit $ExecutionTimeLimit
        $registerParam = if ($null -ne $Credential)
        {
            Write-Verbose $VerboseMessages.UsePrincipal
            $principal = New-ScheduledTaskPrincipal @principalParam
            $scheduledTask = New-ScheduledTask -Description $Description -Action $action -Settings $settings -Trigger $trigger -Principal $principal
            @{
                InputObject = $scheduledTask
                TaskName = $TaskName
                TaskPath = $TaskPath
                Force = $Force
            }
        }
        else
        {
            Write-Verbose $VerboseMessages.SkipPrincipal
            @{
                Action = $action
                Settings = $settings
                Trigger = $trigger
                Description = $Description
                TaskName = $TaskName
                TaskPath = $TaskPath
                Runlevel = $Runlevel
                Force = $Force
            }
        }

        # Register
        if ($force -or -not(TestExistingTaskScheduler -Task $currentTask))
        {
            if ($null -ne $Credential)
            {
                Register-ScheduledTask @registerParam @credentialParam
                return;
            }
            else
            {
                Register-ScheduledTask @registerParam
                return;
            }
        }

    #endregion
    }

    begin
    {
        $ErrorMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                InvalidTrigger = "Invalid Operation detected, you can't set same or greater timespan for RepetitionInterval '{0}' than RepetitionDuration '{1}'."
                ExecuteBrank = "Invalid Operation detected, Execute detected as blank. You must set executable string."
                SameNameFolderFound = "Already same FolderName existing as TaskPath : \\{0}\\ . Please change TaskName or Rename TaskFolder.."
"@
        }

        $VerboseMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                CreateTask = "Creating Task Scheduler Name '{0}', Path '{1}'"
                UsePrincipal = "Using principal with Credential. Execution will be fail if not elevated."
                SkipPrincipal = "Skip Principal and Credential. Runlevel Highest requires elevated."
"@
        }

        $WarningMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                TaskAlreadyExist = '"{0}" already exist on path "{1}". Please Set "-Force $true" to overwrite existing task.'
"@
        }

        function GetExistingTaskScheduler ($TaskName, $TaskPath)
        {
            return Get-ScheduledTask | where TaskName -eq $taskName | where TaskPath -eq $taskPath
        }

        function TestExistingTaskScheduler ($Task)
        {
            $result = ($task | Measure-Object).count -ne 0
            if ($result){ Write-Verbose ($WarningMessages.TaskAlreadyExist -f $task.taskName, $task.taskPath) }
            return $result
        }

        function TestExistingTaskSchedulerWithPath ($TaskName, $TaskPath)
        {
            if ($TaskPath -ne "\"){ return $false }

            # only run when taskpath is \
            $path = Join-Path $env:windir "System32\Tasks"
            $result = Get-ChildItem -Path $path -Directory | where Name -eq $TaskName

            if (($result | measure).count -ne 0)
            {
                return $true
            }
            return $false
        }

        function CreateTaskSchedulerAction ($Argument, $Execute, $WorkingDirectory)
        {
            if (($Argument -eq "") -and ($WorkingDirectory -eq ""))
            {
                return New-ScheduledTaskAction -Execute $execute
            }

            if (($Argument -ne "") -and ($WorkingDirectory -eq ""))
            {
                return New-ScheduledTaskAction -Execute $Execute -Argument $Argument
            }

            if (($Argument -ne "") -and ($WorkingDirectory -ne ""))
            {
                return New-ScheduledTaskAction -Execute $Execute -Argument $Argument -WorkingDirectory $WorkingDirectory
            }
        }

        function CreateTaskSchedulerTrigger ($ScheduledTimeSpan, $ScheduledDuration, $ScheduledAt, $Daily, $Once)
        {

            $trigger = if (($false -eq $Daily) -and ($false -eq $Once))
            {
                $ScheduledTimeSpanPair = New-ValentiaZipPairs -first $ScheduledTimeSpan -Second $ScheduledDuration
                $ScheduledAtPair = New-ValentiaZipPairs -first $ScheduledAt -Second $ScheduledTimeSpanPair
                $ScheduledAtPair `
                | %{
                    if ($_.Item2.Item1 -ge $_.Item2.Item2){ throw New-Object System.InvalidOperationException ($ErrorMessages.InvalidTrigger -f $_.Item2.Item1, $_.Item2.Item2)}
                    New-ScheduledTaskTrigger -At $_.Item1 -RepetitionInterval $_.Item2.Item1 -RepetitionDuration $_.Item2.Item2 -Once
                }
            }
            elseif ($Daily)
            {
                $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Daily}
            }
            elseif ($Once)
            {
                $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Once}
            }
            return $trigger
        }
    }
}