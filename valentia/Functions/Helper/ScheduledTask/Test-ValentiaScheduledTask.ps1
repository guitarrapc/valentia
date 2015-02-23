#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Test is TaskScheduler is same prameter.

.DESCRIPTION
You can test is scheduled task setting is desired.

.NOTES
Author: guitarrapc
Created: 23/Feb/2015

.EXAMPLE
$param = @{
    Execute = "powershell.exe"
    TaskName = "hoge"
    ScheduledAt = [datetime]"2015/1/1 0:0:0"
    Once = $true
}
Set-ValentiaScheduledTask @param -Force $true

Test-ValentiaScheduledTask `
-TaskName hoge `
-Execute "powershell.exe" -Verbose `

# This example is minimum testing and will return $true
# None passed parameter will skip checking

.EXAMPLE
Test-ValentiaScheduledTask `
-TaskName hoge `
-Execute "powershell.exe" `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Once $true

# You can add parameter for strict parameter checking.

.EXAMPLE
$param = @{
    Execute = "powershell.exe"
    Argument = "-Command ''"
    WorkingDirectory = ""
    Description = "hoge"
    TaskName = "hoge"
    TaskPath = "\hoge\"
    ScheduledAt = [datetime]"2015/1/1 0:0:0"
    #Daily = $true
    Once = $true
    Disable = $true
    Hidden = $true
    Credential = Get-ValentiaCredential
}
Set-ValentiaScheduledTask @param -Force $true

Test-ValentiaScheduledTask `
-TaskName hoge `
-TaskPath "\hoge\" `
-Execute "powershell.exe" `
-Argument "-Command ''" `
-Description hoge `
-Credential (Get-ValentiaCredential) `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Once $true

# Testing scheduled task would return true

.EXAMPLE
Test-ValentiaScheduledTask `
-TaskName hoge `
-TaskPath "\hoge\" `
-Execute "powershell.exe" `
-Argument "-Command ''" `
-Description hoge `
-Credential (Get-ValentiaCredential) `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Daily $true -Debug -Verbose

# Testing scheduled task would return false as Daily is invalid. (Should check Once).
# You can check progress with -Debug and -Verbose switch

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation
#>
function Test-ValentiaScheduledTask
{
    [OutputType([Void])]
    [CmdletBinding(DefaultParameterSetName = "ScheduledDuration")]
    param
    (
        [parameter(Mandatory = 1, Position  = 0)]
        [string]$TaskName,
    
        [parameter(Mandatory = 0, Position  = 1)]
        [string]$TaskPath = "\",

        [parameter(Mandatory = 0, Position  = 2)]
        [string]$Execute,

        [parameter(Mandatory = 0, Position  = 3)]
        [string]$Argument,
    
        [parameter(Mandatory = 0, Position  = 4)]
        [string]$WorkingDirectory,

        [parameter(Mandatory = 0, Position  = 5)]
        [datetime[]]$ScheduledAt,

        [parameter(Mandatory = 0, Position  = 6, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledTimeSpan,

        [parameter(Mandatory = 0, Position  = 7, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledDuration,

        [parameter(Mandatory = 0, Position  = 8, parameterSetName = "Daily")]
        [bool]$Daily = $false,

        [parameter(Mandatory = 0, Position  = 9, parameterSetName = "Once")]
        [bool]$Once = $false,

        [parameter(Mandatory = 0, Position  = 10)]
        [string]$Description,

        [parameter(Mandatory = 0, Position  = 11)]
        [PScredential]$Credential,

        [parameter(Mandatory = 0, Position  = 12)]
        [bool]$Disable,

        [parameter(Mandatory = 0, Position  = 13)]
        [bool]$Hidden,

        [parameter(Mandatory = 0, Position  = 14)]
        [TimeSpan]$ExecutionTimeLimit = [TimeSpan]::FromDays(3),

        [parameter(Mandatory = 0,Position  = 15)]
        [ValidateSet("At", "Win8", "Win7", "Vista", "V1")]
        [string]$Compatibility,

        [parameter(Mandatory = 0,Position  = 16)]
        [ValidateSet("Highest", "Limited")]
        [string]$Runlevel
    )

    begin
    {
        function GetScheduledTask
        {
            [OutputType([HashTable])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance[]]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $true)]
                [string]$Value
            )

            Write-Debug ("Checking {0} is exists with : {1}" -f $parameter, $Value)
            $task = $root | where $Parameter -eq $Value
            $uniqueValue = $task.$Parameter | sort -Unique
            $result = $uniqueValue -eq $Value
            Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $uniqueValue)
            return @{
                task = $task
                result = $result
            }
        }

        function TestScheduledTask
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [ValentiaScheduledParameterType]$Type,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [PSObject]$Value,

                [switch]$SkipNullCheck
            )

            # skip null
            if (($Value -eq $null) -or ($Value -eq [string]::Empty))
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            Write-Debug ("Checking {0} is match with : {1}" -f $Parameter, $Value)
            $target = switch ($Type)
            {
                ([ValentiaScheduledParameterType]::Root)
                {
                    $ScheduledTask.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Actions)
                {
                    $ScheduledTask.Actions.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Principal)
                {
                    $ScheduledTask.Principal.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Settings)
                {
                    $ScheduledTask.Settings.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Triggers)
                {
                    $ScheduledTask.Triggers.$Parameter | sort -Unique
                }
            }
            
            # null or empty check
            if ([string]::IsNullOrEmpty($target) -and [string]::IsNullOrEmpty($Value))
            {
                $result = $true
                Write-Debug ("{0} : $result (Detected NullOrEmpty)" -f $Parameter)
                return $result
            }

            # value check
            $result = $target -eq $Value
            Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $target)
            return $result
        }

        function TestScheduledTaskExecutionTimeLimit
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $false)]
                [TimeSpan]$Value
            )

            $private:parameter = "ExecutionTimeLimit"

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            Write-Debug ("Checking {0} is match with : {1}min" -f $parameter, $Value.TotalMinutes)
            $executionTimeLimitTimeSpan = [System.Xml.XmlConvert]::ToTimeSpan($ScheduledTask.Settings.$parameter)
            $result = $Value -eq $executionTimeLimitTimeSpan
            Write-Verbose ("{0} : {1} ({2}min)" -f $parameter, $result, $executionTimeLimitTimeSpan.TotalMinutes)
            return $result            
        }

        function TestScheduledTaskScheduledAt
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $false)]
                [DateTime[]]$Value
            )

            $private:parameter = "StartBoundary"

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            $valueCount = ($Value | measure).Count
            $scheduleCount = ($ScheduledTask.Triggers | measure).Count
            if ($valueCount -ne $scheduleCount)
            {
                throw New-Object System.ArgumentException ("Argument length not match with current ScheduledAt {0} and passed ScheduledAt {1}." -f $scheduleCount, $valueCount)
            }

            $result = @()
            for ($i = 0; $i -le ($ScheduledTask.Triggers.$parameter.Count -1); $i++)
            {
                Write-Debug ("Checking {0} is match with : {1}" -f $parameter, $Value[$i])
                $startBoundaryDateTime = [System.Xml.XmlConvert]::ToDateTime(@($ScheduledTask.Triggers.$parameter)[$i])
                $result += @($Value)[$i] -eq $startBoundaryDateTime
                Write-Verbose ("{0} : {1} ({2})" -f $parameter, $result[$i], $startBoundaryDateTime)
            }
            return $result | sort -Unique
        }

        function TestScheduledTaskScheduledRepetition
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [TimeSpan[]]$Value
            )

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            $valueCount = ($Value | measure).Count
            $scheduleCount = ($ScheduledTask.Triggers | measure).Count
            if ($valueCount -ne $scheduleCount)
            {
                throw New-Object System.ArgumentException ("Arugument length not match with current ScheduledAt {0} and passed ScheduledAt {1}." -f $scheduleCount, $valueCount)
            }

            $result = @()
            for ($i = 0; $i -le ($ScheduledTask.Triggers.Repetition.$Parameter.Count -1); $i++)
            {
                Write-Debug ("Checking {0} is match with : {1}" -f $Parameter, $Value[$i])
                $target = [System.Xml.XmlConvert]::ToTimeSpan(@($ScheduledTask.Triggers.Repetition.$Parameter)[$i])
                $result = @($Value)[$i] -eq $target
                Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result[$i], $target.TotalMinutes)
            }
            return $result | sort -Unique
        }

        function TestScheduledTaskTriggerBy
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [System.Xml.XmlDocument]$ScheduledTaskXml,

                [parameter(Mandatory = $false)]
                [bool]$Daily,

                [parameter(Mandatory = $false)]
                [bool]$Once
            )

            # skip null
            if (($Daily -eq $false) -and ($Once -eq $false))
            {
                Write-Debug ("Skipping Daily, Once as passed value is null")
                return $true
            }

            $trigger = $ScheduledTaskXml.task.Triggers.CalendarTrigger
            $result = $false
            switch ($true)
            {
                $Daily
                {
                    Write-Debug "Checking Trigger is : Daily"
                    $result = ($trigger.ScheduleByDay | measure).Count -ne 0
                    Write-Verbose ("Daily : {0}" -f $result)
                }
                $Once
                {
                    Write-Debug "Checking Trigger is : Once"
                    $result = ($trigger.ScheduleByDay | measure).Count -eq 0
                    Write-Verbose ("Once : {0}" -f $result)
                }
                Default
                {
                    Write-Debug "None of Parameter through Test for Daily/Once"
                }
            }
            return $result
        }
    }
    
    end
    {
        #region Root

            $private:result = $true

            # get whole task
            $root = Get-ScheduledTask

            # TaskPath
            $taskResult = GetScheduledTask -ScheduledTask $root -Parameter TaskPath -Value $TaskPath
            if ($taskResult.result -eq $false){ return $taskResult.Result; }

            # TaskName
            $taskResult = GetScheduledTask -ScheduledTask $taskResult.task -Parameter Taskname -Value $TaskName
            if ($taskResult.result -eq $false){ return $taskResult.Result; }

            # default
            $current = $taskResult.task
            if (($current | measure).Count -eq 0){ return $false }

            # export as xml
            [xml]$script:xml = Export-ScheduledTask -TaskName $current.TaskName -TaskPath $current.TaskPath

            # Description
            $result = TestScheduledTask -ScheduledTask $current -Parameter Description -Value $Description -Type ([ScheduledParameterType]::Root)
            if ($result -eq $false){ return $result; }

        #endregion

        #region Action

            # Execute
            $result = TestScheduledTask -ScheduledTask $current -Parameter Execute -Value $Execute -Type ([ScheduledParameterType]::Actions)
            if ($result -eq $false){ return $result; }

            # Arguments
            $result = TestScheduledTask -ScheduledTask $current -Parameter Arguments -Value $Argument -Type ([ScheduledParameterType]::Actions)
            if ($result -eq $false){ return $result; }

            # WorkingDirectory
            $result = TestScheduledTask -ScheduledTask $current -Parameter WorkingDirectory -Value $WorkingDirectory -Type ([ScheduledParameterType]::Actions)
            if ($result -eq $false){ return $result; }

        #endregion

        #region Principal

            # UserId
            $result = TestScheduledTask -ScheduledTask $current -Parameter UserId -Value $Credential.UserName -Type ([ScheduledParameterType]::Principal)
            if ($result -eq $false){ return $result; }

            # RunLevel
            $result = TestScheduledTask -ScheduledTask $current -Parameter RunLevel -Value $Runlevel -Type ([ScheduledParameterType]::Principal)
            if ($result -eq $false){ return $result; }

        #endregion

        #region Settings

            # Compatibility
            $result = TestScheduledTask -ScheduledTask $current -Parameter Compatibility -Value $Compatibility -Type ([ScheduledParameterType]::Settings)
            if ($result -eq $false){ return $result; }

            # ExecutionTimeLimit
            $result = TestScheduledTaskExecutionTimeLimit -ScheduledTask $current -Value $ExecutionTimeLimit
            if ($result -eq $false){ return $result; }

            # Hidden
            $result = TestScheduledTask -ScheduledTask $current -Parameter Hidden -Value $Hidden -Type ([ScheduledParameterType]::Settings)
            if ($result -eq $false){ return $result; }

        #endregion

        #region Triggers

            # Disable
            $result = TestScheduledTask -ScheduledTask $current -Parameter Enabled -Value $Disable -Type ([ScheduledParameterType]::Triggers)
            if ($result -eq $false){ return $result; }

            # SchduledAt
            $result = TestScheduledTaskScheduledAt -ScheduledTask $current -Value $ScheduledAt
            if ($result -contains $false){ return $false; }

            # ScheduledTimeSpan (Repetition Interval)
            $result = TestScheduledTaskScheduledRepetition -ScheduledTask $current -Value $ScheduledTimeSpan -Parameter Interval
            if ($result -contains $false){ return $false; }

            # ScheduledDuration (Repetition Duration)
            $result = TestScheduledTaskScheduledRepetition -ScheduledTask $current -Value $ScheduledDuration -Parameter Duration
            if ($result -contains $false){ return $false; }

            # Daily
            $result = TestScheduledTaskTriggerBy -ScheduledTaskXml $xml -Daily $Daily -Once $Once
            if ($result -eq $false){ return $result; }

        #endregion

        return $result
    }
}