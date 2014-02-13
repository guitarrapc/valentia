#Requires -Version 3.0

#-- Private Module workflow / Functions for Remote Execution --#

workflow Invoke-ValentiaCommandParallel
{

<#

.SYNOPSIS 
Invoke workflow valentia execution to remote host

.DESCRIPTION
Concurrent running thread through WmiPrvSE.exe
workflow not allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

# --- Depends on following functions ---
#
#  Invoke-ValetinaParallel
# 
# ---                                ---


.EXAMPLE
  CommandParallel -ScriptToRun $ScriptToRun
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommandParallel -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommandParallel {test-connection localhost}
--------------------------------------------

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory =$true,
            HelpMessage = "Input ScriptBlock. ex) Get-ChildItem; Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]
        $ScriptToRun,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter,

        [Parameter(
            Position = 2, 
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [switch]
        $quiet
    )
    
    $ErrorActionPreference = $valentia.errorPreference

    foreach -Parallel ($DeployMember in $PSComputerName)
    {
        InlineScript
        {
            # Initializing stopwatch
            $stopwatchSession = Invoke-Command {[System.Diagnostics.Stopwatch]::StartNew()}
            
            # Inherite variable
            [HashTable]$task = @{}

            # Get Host
            $task.host = $using:DeployMember

            # Executing query
            try
            {
                # Create ScriptBlock
                $WorkflowScript = [ScriptBlock]::Create($using:ScriptToRun)

                # Run ScriptBlock
                $task.result = Invoke-Command -ScriptBlock {&$WorkflowScript} -ArgumentList $using:TaskParameter
            }
            catch 
            {
                # Show Error Message
                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
                Write-Error $_
            }

            # Get Duration Seconds for each command
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            $DurationMessage = {"$($using:DeployMember) exec Duration Sec :$Duration"}
            $MessageStopwatch = Invoke-Command -ScriptBlock {&$DurationMessage}

            # Show Duration Seconds
            if (-not $using:quiet)
            {
                Write-Warning -Message ("`t`t{0}" -f $MessageStopwatch)
            }
            
            # Output $task variable to file. This will obtain by other cmdlet outside workflow.
            return $task
        }
    }

    # Clear Progress bar from Host,
    # Make sure this is critical, YOU MUST CLEAR PROGRESS BAR, other wise host output will be terriblly slow down.
    Write-Progress -Activity "done" -Status "done" -Completed   
}