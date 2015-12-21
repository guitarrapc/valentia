#Requires -Version 3.0

#-- Private Module Function for AsyncPipelline monitor --#

function Watch-ValentiaAsyncPipelineStatus
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, mandatory = $false, HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]$AsyncPipelines
    )

    process
    {
        while ((($ReceiveAsyncStatus = (Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines | group state, hostname -NoElement)) | where name -like "Running*").count -ne 0)
        {
            $count++
            $completed     = $ReceiveAsyncStatus | where name -like "Completed*"
            $running       = $ReceiveAsyncStatus | where name -like "Running*"
            $statusPercent = ($completed.count/$ReceiveAsyncStatus.count) * 100

            # hide progress or not
            if (-not $quiet -and ($sw.Elapsed.TotalMilliseconds -ge 500))
            {
                # hide progress or not
                if ($statusPercent -ne 100)
                {
                    $paramProgress = @{
                        Activity        = 'Async Execution Running Status.... ({0}sec elapsed)' -f $TotalstopwatchSession.Elapsed.TotalSeconds
                        PercentComplete = $statusPercent
                        status          = ("{0}/{1}({2:0.00})% Completed" -f $completed.count, $ReceiveAsyncStatus.count, $statusPercent)
                    }
                    
                    Write-Progress @paramProgress
                    $sw.Reset()
                    $sw.Start()
                }
            }

            # Log Current Status
            if (-not $null -eq $prevRunningCount)
            {
                if ($running.count -lt $prevRunningCount)
                {
                    $ReceiveAsyncStatus.Name | OutValentiaModuleLogHost -hideDataAsString
                    [PSCustomObject]@{
                        Running   = $running.count
                        Completed = $completed.count
                    } | OutValentiaModuleLogHost -hideDataAsString
                }
            }
            $prevRunningCount = $running.count

            # Wait a moment
            sleep -Milliseconds $valentia.runspace.async.sleepMS

            # safety release
            if ($count -ge $valentia.runspace.async.limitCount)
            {
                break
            }
        }
    }

    end
    {
        # Clear Progress bar from Host, YOU MUST CLEAR PROGRESS BAR, other wise host output will be terriblly slow down.
        Write-Progress "done" "done" -Completed

        # Dispose variables
        if (-not ($null -eq $ReceiveAsyncStatus))
        {
            $ReceiveAsyncStatus = $null
        }
    }

    begin
    {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
    }
}
