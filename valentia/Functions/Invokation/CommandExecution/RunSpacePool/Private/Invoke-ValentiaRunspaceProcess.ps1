#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Invoke-ValentiaRunspaceProcess
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $false)]
        [string[]]$ComputerNames = $valentia.Result.DeployMembers,

        [parameter(mandatory = $false)]
        [scriptBlock]$ScriptToRun = $valentia.Result.ScriptTorun,

        [parameter(mandatory = $true)]
        [PSCredential]$Credential,

        [parameter(mandatory = $false)]
        [hashtable]$TaskParameter,

        [parameter(mandatory = $true)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [parameter(mandatory = $true)]
        [bool]$UseSSL,

        [parameter(mandatory = $true)]
        [bool]$SkipException,

        [parameter(mandatory = $false)]
        [bool]$quiet
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
                UseSSL         = $UseSSL
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
