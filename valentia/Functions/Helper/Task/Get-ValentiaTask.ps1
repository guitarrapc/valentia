#Requires -Version 3.0

#-- Public Module Functions to load Task --#

# Task

<#
.SYNOPSIS 
Load Task File format into $valentia.context.tasks.$taskname hashtable.

.DESCRIPTION
Loading ps1 file which format is task <taskname> -Action { <scriptblock> }

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
task taskname -Action { What you want to do in ScriptBlock}
--------------------------------------------
This is format sample.

.EXAMPLE
task lstest -Action { Get-ChildItem c:\ }
--------------------------------------------
Above example will create taskkey as lstest, run "Get-ChildItem c:\" when invoke.
#>
function Get-ValentiaTask
{
    [CmdletBinding()]  
    param
    (
        [Parameter(Position = 0, mandatory = $true, HelpMessage = "Input TaskName you want to set and not dupricated.")]
        [string]$Name = $null,

        [Parameter(Position = 1, mandatory = $false, HelpMessage = "Write ScriptBlock Action to execute with this task.")]
        [scriptblock]$Action = $null
    )

    # Load Task
    Write-Verbose $valeWarningMessages.warn_import_task_begin
    $newTask = @{
        Name = $Name
        Action = $Action
    }

    # convert into LowerCase for keyname
    Write-Verbose $valeWarningMessages.warn_import_task_end
    $taskKey = $Name.ToLower()

    # Get current context variables
    Write-Verbose $valeWarningMessages.warn_get_current_context
    $currentContext = $valentia.context.Peek()

    # Check dupricate key name
    if ($currentContext.tasks.ContainsKey($taskKey))
    {
        throw $valeErrorMessages.error_duplicate_task_name -F $Name
    }
    else
    {
        $valeWarningMessages.warn_set_taskkey | Write-ValentiaVerboseDebug
        $currentContext.tasks.$taskKey = $newTask
    }

    # return taskkey to determin key name in $valentia.context.tasks.$taskkey
    return $taskKey

}
