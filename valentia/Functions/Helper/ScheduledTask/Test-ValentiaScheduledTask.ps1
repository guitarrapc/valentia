#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
#>

function Test-ValentiaScheduledTask
{
    [OutputType([Void])]
    [CmdletBinding(DefaultParameterSetName = "ScheduledDuration")]
    param
    (
        [parameter(Mandatory = 0, Position  = 0)]
        [string]$Execute = [sring]::Empty,

        [parameter(Mandatory = 0, Position  = 1)]
        [string]$Argument = [sring]::Empty,
    
        [parameter(Mandatory = 0, Position  = 2)]
        [string]$WorkingDirectory = [sring]::Empty,

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
        [string]$Description = [string]::Empty,

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
        [string]$Runlevel = "Limited"
    )

    begin
    {
        # Enum for Ensure
        try
        {
        Add-Type -TypeDefinition @"
            public enum ScheduledParameterType
            {
                Root,
                Actions,
                Principal,
                Settings,
                Triggers
            }
"@
        }
        catch
        {
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
                [ScheduledParameterType]$Type,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [PSObject]$Value,

                [switch]$SkipNullCheck
            )

            Write-Debug ("Checking {0} is match with : {1}" -f $Parameter, $Value)
            $target = switch ($Type)
            {
                ([ScheduledParameterType]::Root)
                {
                    $ScheduledTask.$Parameter | sort -Unique
                }
                ([ScheduledParameterType]::Actions)
                {
                    $ScheduledTask.Actions.$Parameter | sort -Unique
                }
                ([ScheduledParameterType]::Principal)
                {
                    $ScheduledTask.Principal.$Parameter | sort -Unique
                }
                ([ScheduledParameterType]::Settings)
                {
                    $ScheduledTask.Settings.$Parameter | sort -Unique
                }
                ([ScheduledParameterType]::Triggers)
                {
                    $ScheduledTask.Triggers.$Parameter | sort -Unique
                }
            }
            
            # null or empty check
            if ([string]::IsNullOrEmpty($target) -and [string]::IsNullOrEmpty($Value))
            {
                Write-Debug ("Parameter {0} was detected NullOrEmpty. : $true" -f $Parameter)
                return $true
            }

            # value check
            $result = $target -eq $Value
            Write-Verbose ("{0} : {1}" -f $Parameter, $result)
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

            $parameter = "ExecutionTimeLimit"
            Write-Debug ("Checking {0} is match with : {1}min" -f $parameter, $Value.TotalMinutes)
            $executionTimeLimitTimeSpan = [System.Xml.XmlConvert]::ToTimeSpan($ScheduledTask.Settings.$parameter)
            $result = $Value -eq $executionTimeLimitTimeSpan
            Write-Verbose ("{0} : {1}" -f $parameter, $result)
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

            $valueCount = ($Value | measure).Count
            $scheduleCount = ($ScheduledTask.Triggers | measure).Count
            if ($valueCount -ne $scheduleCount)
            {
                throw New-Object System.ArgumentException ("Arugument length not match with current ScheduledAt {0} and passed ScheduledAt {1}." -f $scheduleCount, $valueCount)
            }

            $parameter = "StartBoundary"
            $result = @()
            for ($i = 0; $i -le ($ScheduledTask.Triggers.$parameter.Count -1); $i++)
            {
                Write-Debug ("Checking {0} is match with : {1}" -f $parameter, $Value[$i])
                $startBoundaryDateTime = [System.Xml.XmlConvert]::ToDateTime(@($ScheduledTask.Triggers.$parameter)[$i])
                $result += $Value[$i] -eq $startBoundaryDateTime
                Write-Verbose ("{0} : {1}" -f $parameter, $result[$i])
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

            $trigger = $ScheduledTaskXml.task.Triggers.CalendarTrigger
            $result = $false
            if ($Daily)
            {
                Write-Debug "Checking Trigger is as Daily"
                $result = ($trigger.ScheduleByDay | measure).Count -ne 0
                Write-Verbose ("Daily : {0}" -f $result)
            }
            if ($Once)
            {
                Write-Debug "Checking Trigger is as Once"
                $result = ($trigger.ScheduleByDay | measure).Count -eq 0
                Write-Verbose ("Once : {0}" -f $result)
            }
            else
            {
                Write-Debug "None of Parameter through Test for Daily/Once"
            }
            return $result
        }
    }
    
    end
    {
        #region Root
            $script:current = Get-ScheduledTask | where TaskPath -eq $TaskPath | where TaskName -eq $TaskName
            [xml]$script:xml = Export-ScheduledTask -TaskName $current.TaskName -TaskPath $current.TaskPath

            # default
            if (($current | measure).Count -eq 0){ return $false}
            $script:result = $true

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
            $result = TestScheduledTask -ScheduledTask $current -Parameter Enabled -Value $Disable -Type Triggers
            if ($result -eq $false){ return $result; }

            # SchduledAt
            $result = TestScheduledTaskScheduledAt -ScheduledTask $current -Value $ScheduledAt
            if ($result -contains $false){ return $false; }

            # Daily
            $result = TestScheduledTaskTriggerBy -ScheduledTaskXml $xml -Daily $Daily -Once $Once
            if ($result -eq $false){ return $result; }

        #endregion

        return $result
    }
}
