#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Receive-ValentiaAsyncStatus
{

<#
.SYNOPSIS 
Receives one or more Asynchronous pipeline State.

.DESCRIPTION
Asynchronous execution required to check status whether it done or not.
  
.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines

--------------------------------------------
Above will retrieve Async Result
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]
        $Pipelines
    )
    
    foreach($Pipeline in $Pipelines)
    {
       [PSCustomObject]@{
            HostName   = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
            InstanceID = $Pipeline.Pipeline.Instance_Id
            State      = $Pipeline.Pipeline.InvocationStateInfo.State
            Reason     = $Pipeline.Pipeline.InvocationStateInfo.Reason
            Completed  = $Pipeline.AsyncResult.IsCompleted
            AsyncState = $Pipeline.AsyncResult.AsyncState			
            Error      = $Pipeline.Pipeline.Streams.Error
       }
    } 
}