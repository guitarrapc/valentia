#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

<#
.SYNOPSIS 
Receives a results of one or more jobs.

.DESCRIPTION
Get background job execution result.

.NOTES
Author: guitarrapc
Created: 14/Feb/2014

.EXAMPLE
  Receive-ValentiaResult -listJob $listJob
#>
function Receive-ValentiaResult
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $true, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input list<job> to recieve result of each job.")]
        [System.Collections.Generic.List[System.Management.Automation.Job]]$listJob,

        [Parameter(Position = 1, mandatory = $false, HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]$SkipException
    )

    process
    {
        # monitor job status
        "Waiting for job running complete." | Write-ValentiaVerboseDebug
        Wait-Job -Job $listJob -Force > $null

        foreach ($job in $listJob)
        {
            # Obtain HostName
            $task.host = $job.Location

            ("Receive ScriptBlock result from Job for '{0}'" -f $job.Location) | Write-ValentiaVerboseDebug
            if ($SkipException)
            {
                $task.result = Receive-Job -Job $job -ErrorAction SilentlyContinue -ErrorVariable ErrorVariable
            }
            else
            {
                $task.result = Receive-Job -Job $job -ErrorVariable ErrorVariable
            }

            # Error actions
            if (($ErrorVariable | measure).Count -ne 0)
            {
                $task.ErrorMessageDetail = $ErrorVariable
                $task.SuccessStatus = $false
                $task.success = $false

                if (-not $SkipException)
                {
                    if ($ErrorActionPreference -eq 'Stop')
                    {
                        throw $ErrorVariable
                    }
                }
            }
            else
            {
                $task.success = $true
            }

            # output
            $task

            ("Removing Job ID '{0}'" -f $job.id) | Write-ValentiaVerboseDebug
            Remove-Job -Job $job -Force
        }
    }

    begin
    {
        # Set variable for output
        $task = @{}
    }
}
