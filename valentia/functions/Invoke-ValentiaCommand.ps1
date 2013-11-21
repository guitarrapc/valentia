#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

function Invoke-ValentiaCommand
{

<#

.SYNOPSIS 
Invoke Command as Job to remote host

.DESCRIPTION
Background job execution with Invoke-Command.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

# --- Depends on following functions ---
#
#  Invoke-Valetina
# 
# ---                                ---

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun $ScriptToRun
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand {test-connection localhost}
--------------------------------------------

#>

    [CmdletBinding(DefaultParameterSetName = "All")]
    param
    (
        [Parameter(
            Position = 0,
            ParameterSetName = "Default",
            ValueFromPipeline =$True,
            ValueFromPipelineByPropertyName =$True,
            Mandatory =$true,
            HelpMessage = "Input Session")]
        [System.Management.Automation.Runspaces.PSSession[]]
        $Sessions,

        [Parameter(
            Position = 1,
            ParameterSetName = "Default",
            ValueFromPipeline =$True,
            ValueFromPipelineByPropertyName =$True,
            Mandatory =$true,
            HelpMessage = "Input ScriptBlock. ex) Get-ChildItem, Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]
        $ScriptToRun,

        [Parameter(
            Position = 2,
            Mandatory =$true,
            HelpMessage = "Input wsmanSession Threshold number to restart wsman")]
        [int]
        $wsmanSessionlimit,

        [Parameter(
            Position = 3, 
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter
    )


    $ErrorActionPreference = $valentia.errorPreference

    # Set variable for Stopwatch
    [decimal]$DurationTotal = 0

    foreach ($session in $Sessions)
    {
        # Initializing stopwatch
        $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Inherite variable
        [HashTable]$task = @{}

        # set wsmanflag to check command success or not
        $task.WSManInstanceflag = $True

        # Get Host
        $task.host = $session.ComputerName

        # Check parameter for Invoke-Command
        Write-Verbose ("Session..... {0}" -f $($Sessions))
        Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
        Write-Verbose ("wsmanSessionlimit..... {0}" -f $($wsmanSessionlimit))
        Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))

        # Run ScriptBlock in Job
        Write-Verbose ("Running ScriptBlock to {0} as Job" -f $session)
        $job = Invoke-Command -Session $session -ScriptBlock $ScriptToRun -ArgumentList $TaskParameter -AsJob

        try
        {
            # Recieve ScriptBlock result from Job
            Write-Verbose "Receiving Job result."
            $task.result = Receive-Job -Job $job -Wait
            $task.WSManInstanceflag = $false
            
        }
        catch [System.Management.Automation.ActionPreferenceStopException]
        {
            # Show Error Message
            Write-Error $_

            # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
            $task.SuccessStatus = $false
            $task.ErrorMessageDetail = $_

        }

        # Get Duration Seconds for each command
        $Duration = $stopwatchSession.Elapsed.TotalSeconds
        $DurationMessage = "{0} exec Duration Sec :{1}" -f $session.ComputerName, $Duration
        $MessageStopwatch = Invoke-Command -ScriptBlock {$DurationMessage}

        # Show Duration Seconds
        if (-not $quiet)
        {
            Write-Warning -Message $MessageStopwatch
        }

        # Add each command exec time to Totaltime
        $DurationTotal += $Duration
        

        # Get Current host WSManInstance (No need set Connection URI as it were already connecting
        $WSManInstance = Invoke-Command -ScriptBlock {Get-WSManInstance shell -Enumerate} -Session $session
        Write-Verbose ("Current WSManInstance count is $($WSManInstance.count)")

        # Close Remote Connection existing by restart wsman if current wsmanInstance count greater than $valentia.wsmanSessionlimit
        # Remove or Restart session will cause error but already session is over and usually session terminated in 90 seconds
        if ($WSManInstance.count -ge $valentia.wsmanSessionlimit)
        {     
            # Will Restart WinRM and kill all sessions
            try
            {
                # if restart WinRM happens, all result in this session will be voided
                Restart-Service -Name WinRM -Force -PassThru
            }
            catch
            {
                Write-Error $_

                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
            }

        }

        # Output $task variable to file. This will obtain by other cmdlet outside workflow.
        $task

    }

    # Show stopwatch result
    Write-Verbose ("`t`tTotal exec Command Sec: {0}" -f $DurationTotal)
    "" | Out-Default

}