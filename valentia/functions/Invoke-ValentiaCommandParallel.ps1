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
            Mandatory =$true,
            HelpMessage = "Input wsmanSession Threshold number to restart wsman")]
        [int]
        $wsmanSessionlimit,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter
    )
    
    $ErrorActionPreference = $valentia.errorPreference

    foreach -Parallel ($DeployMember in $PSComputerName){
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
                $task.result = Invoke-Command -ScriptBlock {&$WorkflowScript} -ArgumentList $TaskParameter
                $task.WSManInstanceflag = $false
            }
            catch 
            {
                # Show Error Message
                Write-Error $_

                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
            }


            # Get Duration Seconds for each command
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            $DurationMessage = {"$($using:DeployMember) exec Duration Sec :$Duration"}
            $MessageStopwatch = Invoke-Command -ScriptBlock {&$DurationMessage}

            # Show Duration Seconds
            if (!$quiet)
            {
                Write-Warning -Message ("`t`t{0}" -f $MessageStopwatch)
            }
            
            # Get Current host WSManInstance (No need set Connection URI as it were already connecting
            $WSManInstance = Get-WSManInstance shell -Enumerate

            # Close Remote Connection existing by workflow session if session count up to $valentia.wsmanSessionlimit
            # Remove or Restart session will cause error but already session is over and usually session terminated in 90 seconds
            if ($WSManInstance.count -ge $using:wsmanSessionlimit)
            {

                # Will remove specific session you select include current. (In this command will be all session)
                $WSManInstance | %{Remove-WSManInstance -ConnectionURI http://localhost:5985/wsman shell @{shellid=$_.ShellId}}
                
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
            return $task
        }
    }
   
}
