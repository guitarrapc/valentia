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
        try
        {
            # Execute Async Job
            $asyncPipelineparam = @{
                scriptBlock    = $scriptBlock
                Credential     = $credential
                TaskParameter  = $TaskParameter
                Authentication = $Authentication
            }
            Invoke-ValentiaAsyncPipeline @asyncPipelineparam

            # Monitoring status for Async result (Even if no monitoring, but asynchronous result will obtain after all hosts available)
            Watch-ValentiaAsyncPipelineStatus -AsyncPipelines $valentia.runspace.asyncPipeline
        
            # Obtain Async Command Result
            $asyncResultParam = @{
                AsyncPipelines = $valentia.runspace.asyncPipeline
                quiet          = $quiet
                ErrorAction    = $ErrorActionPreference
                skipException  = $skipException
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
                        Values    = $_.result
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
        finally
        {
            # Dispose RunspacePool
            Remove-ValentiaRunSpacePool

            # Dispose AsyncPipeline variables
            $valentia.runspace.asyncPipeline = $null
        }
    }
}
