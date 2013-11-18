#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Receive-ValentiaAsyncResults
{
<#
.SYNOPSIS 
Receives a results of one or more asynchronous pipelines.

.DESCRIPTION
This function receives the results of a pipeline running in a separate runspace.  
Since it is unknown what exists in the results stream of the pipeline, this function will not have a standard return type.
 
.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -ShowProgress

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
        [AsyncPipeline[]]
        $Pipelines,

		[Parameter(
            Position=1,
            Mandatory = 0,
            HelpMessage = "An optional switch to display a progress indicator.")]
        [Switch]
        $ShowProgress,

		[Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [Switch]
        $quiet
    )
	
    # Initialising for Write-Progress
    $i = 1 
	
    foreach($Pipeline in $Pipelines)
    {
		try
		{

            # Inherite variable
            [HashTable]$task = @{}

            # Get HostName of Pipeline
            $task.host = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
            if (!$quiet)
            {
                Write-Warning  -Message ("{0} Asynchronous execution done." -f $task.host)
            }

            # output Asyanc result
        	$task.result = $Pipeline.Pipeline.EndInvoke($Pipeline.AsyncResult)
			
            # Check status of stream
			if($Pipeline.Pipeline.Streams.Error)
			{
                $task.SuccessStatus += $false
                $task.ErrorMessageDetail += $_
				throw $Pipeline.Pipeline.Streams.Error
			}
        }
        catch 
        {
            $task.SuccessStatus += $false
            $task.ErrorMessageDetail += $_
            Write-Error $_
		}
        
        # Dispose Pipeline
        $Pipeline.Pipeline.Dispose()
		
        # Dispose RunspacePool
        $pool.Close()
        $pool.Dispose()

        # Show Progress bar
		if($ShowProgress)
		{
            if (!$quiet)
            {
			    Write-Progress -Activity 'Receiving AsyncPipeline Results' `
                    -PercentComplete $(($i/$Pipelines.Length) * 100) `
				    -Status "Percent Complete"
            }
		}
		
        # Incrementing for Write-Progress
        $i++

        # Output $task variable to file. This will obtain by other cmdlet outside function.
        $task
    }

}