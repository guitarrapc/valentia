#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Receives a results of one or more asynchronous pipelines.

.DESCRIPTION
This function receives the results of a pipeline running in a separate runspace.  
Since it is unknown what exists in the results stream of the pipeline, this function will not have a standard return type.
 
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -ShowProgress

--------------------------------------------
Above will retrieve Async Result
#>
function Receive-ValentiaAsyncResults
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]
        $Pipelines,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [bool]
        $quiet,

        [Parameter(
            Position = 2, 
            Mandatory = 0,
            HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]
        $SkipException
    )
    
    process
    {
        foreach($Pipeline in $Pipelines)
        {
            try
            {
                # Get HostName of Pipeline
                $task.host = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
                if (-not $quiet)
                {
                    Write-Warning  -Message ("{0} Asynchronous execution done." -f $task.host)
                }

                # output Asyanc result
                $task.result = $Pipeline.Pipeline.EndInvoke($Pipeline.AsyncResult)
            
                # Check status of stream
                if($Pipeline.Pipeline.Streams.Error)
                {
                    $task.SuccessStatus = $false
                    $task.ErrorMessageDetail = $Pipeline.Pipeline.Streams.Error
                    $task.success = $false

                    if (-not $SkipException)
                    {
                        if ($ErrorActionPreference -eq "Stop")
                        {
                            throw $Pipeline.Pipeline.Streams.Error
                        }
                        else
                        {
                            Write-Error "$($Pipeline.Pipeline.Streams.Error)"
                        }
                    }
                }
                else
                {
                    $task.success = $true
                }
       
                # Output $task variable to file. This will obtain by other cmdlet outside function.
                $task
            }
            catch 
            {
                $task.SuccessStatus += $false
                $task.ErrorMessageDetail += $_
                Write-Error $_
            }
            finally
            {
                # Dispose Pipeline
                $Pipeline.Pipeline.Dispose()                
            }
        }
    }

    begin
    {
        # Inherite variable
        [HashTable]$task = @{}
    }
}
