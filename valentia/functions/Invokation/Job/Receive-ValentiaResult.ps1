#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

function Receive-ValentiaResult
{

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
--------------------------------------------
#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1,
            HelpMessage = "Input list<job> to recieve result of each job.")]
        [System.Collections.Generic.List[System.Management.Automation.Job]]
        $listJob
    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference

        # Set variable for output
        $task = @{}
    }

    process
    {
        foreach ($job in $listJob)
        {
            try
            {
                ("Recieve ScriptBlock result from Job for '{0}'" -f $job.Location) | Write-ValentiaVerboseDebug
                $task.host = $job.Location
                $task.result = Receive-Job -Job $job
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

                ("Removing Job ID '{0}'" -f $job.id) | Write-ValentiaVerboseDebug
                Remove-Job -Job $job -Force
            }
        }
    }
}