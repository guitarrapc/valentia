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
            Mandatory = 1,
            ParameterSetName = "Default",
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1,
            HelpMessage = "Input Session")]
        [string[]]
        $ComputerNames,

        [Parameter(
            Position = 1,
            Mandatory = 1,
            ParameterSetName = "Default",
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1,
            HelpMessage = "Input ScriptBlock. ex) Get-ChildItem, Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]
        $ScriptToRun,

        [Parameter(
            Position = 2,
            Mandatory = 1,
            HelpMessage = "Input PSCredential for Remote Command execution.")]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(
            Position = 3, 
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter
    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference
        $list = New-Object System.Collections.Generic.List[System.Management.Automation.Job]

        # Set variable for Stopwatch
        [decimal]$DurationTotal = 0

        # Set variable for output each task result
        $task = @{}
    }

    process
    {
        #region execute to host
        try
        {
            foreach ($computerName in $ComputerNames)
            {
                # Initializing stopwatch
                $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

                # Check parameter for Invoke-Command
                Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
                Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))

                # Run ScriptBlock in Job
                Write-Verbose ("Running ScriptBlock to {0} as Job" -f $computerName)
                $job = Invoke-Command -ScriptBlock $ScriptToRun -ArgumentList $TaskParameter -ComputerName $computerName -Credential $Credential -AsJob
                $list.Add($job)
            }
        }
        catch [System.Management.Automation.ActionPreferenceStopException]
        {
            # Show Error Message
            Write-Error $_

            # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
            $task.SuccessStatus = $false
            $task.ErrorMessageDetail = $_
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException]
        {
            # Show Error Message
            Write-Error $_

            # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
            $task.SuccessStatus = $false
            $task.ErrorMessageDetail = $_
        }
        #endregion

        #region monitor job status
        while (((Get-Job).State) -contains "Running")
        {
            Write-Verbose "Waiting for job running complete."
            sleep -Milliseconds 10
        }
        #endregion

        #region recieve job result
        foreach ($listJob in $list)
        {
            try
            {
                Write-Verbose ("Recieve ScriptBlock result from Job for '{0}'" -f $listJob.Location)
                $task.host = $listJob.Location
                $task.result = Receive-Job -Job $listJob
            }
            catch
            {
                # Show Error Message
                Write-Error $_

                # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
            }
            finally
            {
                # Output
                $task

                # initialize
                $task.host = $null
                $task.result = $null

                Write-Verbose "Clean up Job"
                Remove-Job -Job $listJob -Force
            }
        }
        #endregion
    }

    end
    {
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

        # Output $task variable to file. This will obtain by other cmdlet outside workflow.

        # Show stopwatch result
        Write-Verbose ("`t`tTotal exec Command Sec: {0}" -f $DurationTotal)
        "" | Out-Default
    }
}