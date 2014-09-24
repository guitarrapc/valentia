#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and Unregister Task you selected.

.DESCRIPTION
You can remove task and Empty folder if desired.

.NOTES
Author: guitarrapc
Created: 24/Sep/2014

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath

# remove Task from your selected path

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath -RemoveEmptyFolder $true

# remove Task and Empty Folder

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Get-ScheduledTask -TaskName hoge -TaskPath \fuga\ | Remove-ValentiaScheduledTask

# Remove ScheduledTask passed as CIMInstance

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Remove-ValentiaScheduledTask
{
    [CmdletBinding(DefaultParameterSetName="TaskName")]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ParameterSetName = "TaskName", ValueFrompipelineByPropertyName = 1)]
        [string]$taskName,
    
        [parameter(Mandatory = 0, Position  = 1, ParameterSetName = "TaskName", ValueFrompipelineByPropertyName = 1)]
        [string]$taskPath = "\",

        [parameter(Mandatory = 0, Position  = 1, ParameterSetName = "CimTask", ValueFrompipeline = 1)]
        [CimInstance[]]$InputObject,

        [parameter(Mandatory = 0,　Position  = 2)]
        [bool]$RemoveEmptyFolder = $false,

        [parameter(Mandatory = 0,　Position  = 3)]
        [bool]$Force = $false
    )

    end
    {
        $Confirm = !$Force

        if ($PSBoundParameters.ContainsKey('taskName'))
        {
            # exist
            $existingTaskParam = 
            @{
                TaskName = $taskName
                TaskPath = ValidateTaskPathLastChar -taskPath $taskPath
            }

            # Unregister Task
            $task = GetExistingTaskScheduler @existingTaskParam
            if (($task | measure).count -eq 0)
            {
                Write-Verbose ($VerboseMessages.TaskNotFound -f $existingTaskParam.taskName, $existingTaskParam.taskPath)
            }
            else
            {
                Write-Verbose ($VerboseMessages.RemoveTask -f $existingTaskParam.taskName, $existingTaskParam.taskPath)
                $task | Unregister-ScheduledTask -PassThru -Confirm:$Confirm
            }

        }
        else
        {
            $InputObject | Unregister-ScheduledTask -PassThru -Confirm:$confirm
        }

        # Remove Empty task folder
        if ($RemoveEmptyFolder){ Remove-ValentiaScheduledTaskEmptyDirectoryPath }
    }

    begin
    {
        $VerboseMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                RemoveTask = "Removing Task Scheduler Name '{0}', Path '{1}'"
                TaskNotFound = "Task not found for TaskName '{0}', TaskPath '{1}'. Skip execution."
"@
        }

        function GetExistingTaskScheduler ($TaskName, $TaskPath)
        {
            $task = Get-ScheduledTask | where TaskName -eq $taskName | where TaskPath -eq $taskPath
            return $task
        }

        function ValidateTaskPathLastChar ($taskPath)
        {
            $lastChar = [System.Linq.Enumerable]::ToArray($taskPath) | select -Last 1
            if ($lastChar -ne "\"){ return $taskPath + "\" }
            return $taskPath
        }
    }
}