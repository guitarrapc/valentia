#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Invoke-ValentiaRunspaceProcess
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [string[]]
        $ComputerNames = $valentia.Result.DeployMembers,

        [parameter(Mandatory = 0)]
        [scriptBlock]
        $ScriptToRun = $valentia.Result.ScriptTorun,

        [parameter(Mandatory = 1)]
        [PSCredential]
        $Credential,

        [parameter(Mandatory = 0)]
        [string[]]
        $TaskParameter,

        [parameter(Mandatory = 1)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]
        $Authentication,

        [parameter(Mandatory = 1)]
        [bool]
        $SkipException,

        [parameter(Mandatory = 0)]
        [bool]
        $quiet
    )

    process
    {
        # Execute Async Job
        $asyncPipelineparam = @{
            scriptBlock    = $scriptBlock
            Credential     = $credential
            TaskParameter  = $TaskParameter
            Authentication = $Authentication
        }
        $AsyncPipelines = InvokeValentiaAsyncPipeline @asyncPipelineparam

        # Monitoring status for Async result (Even if no monitoring, but asynchronous result will obtain after all hosts available)
        MonitorAsyncPipelineStatus -AsyncPipelines $AsyncPipelines
        
        # Obtain Async Command Result
        $asyncResultParam = @{
            Pipelines     = $AsyncPipelines 
            quiet         = $quiet
            ErrorAction   = $ErrorActionPreference
            skipException = $skipException
        }
        Receive-ValentiaAsyncResults @asyncResultParam `
        | %{$valentia.Result.Result = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        }{
            $valentia.Result.ErrorMessageDetail += $_.ErrorMessageDetail
            $valentia.Result.SuccessStatus += $_.SuccessStatus
            if ($_.host -ne $null)
            {
                $hash = [ordered]@{
                    Hostname = $_.host
                    Value    = $_.result
                    Success  = $_.success
                }
                $valentia.Result.Result.Add([PSCustomObject]$hash)
            }

            if (-not $quiet)
            {
                "Show result for host '{0}'" -f $_.host | Write-ValentiaVerboseDebug
                $_.result
            }
        }
    }

    begin
    {

        function InvokeValentiaAsyncPipeline ($scriptBlock, $Credential, $TaskParameter, $Authentication)
        {
            # Create RunSpacePools
            $poolParam = @{
                minPoolSize = $valentia.poolSize.minPoolSize
                maxPoolSize = $valentia.poolSize.maxPoolSize
            }
            $pool = New-ValentiaRunSpacePool @poolParam

            Write-Verbose ("Target Computers : [{0}]" -f ($ComputerNames -join ", "))
            $param = @{
                RunSpacePool       = $pool
                ScriptToRunHash    = @{ScriptBlock    = $ScriptToRun}
                credentialHash     = @{Credential     = $Credential}
                TaskParameterHash  = @{TaskParameter  = $TaskParameter}
                AuthenticationHash = @{Authentication = $Authentication}
            }
            $AsyncPipelines = New-Object System.Collections.Generic.List[AsyncPipeline]

            foreach ($DeployMember in $valentia.Result.DeployMembers)
            {
                $AsyncPipeline = Invoke-ValentiaAsyncCommand @param -Deploymember $DeployMember
                $AsyncPipelines.Add($AsyncPipeline)
            }

            return $AsyncPipelines
        }

        function MonitorAsyncPipelineStatus ($AsyncPipelines)
        {
            process
            {
                while ((($ReceiveAsyncStatus = (Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines | group state,hostname -NoElement)) | where name -like "Running*").count -ne 0)
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
                    sleep -Milliseconds $valentia.async.sleepMS

                    # safety release
                    if ($count -ge $valentia.async.limitCount)
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
    }
}
