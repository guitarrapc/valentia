#Requires -Version 3.0

#-- Private Module Function for AsyncPipelline execution --#

function Invoke-ValentiaAsyncPipeline
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [scriptBlock]
        $ScriptBlock,

        [parameter(Mandatory = 1)]
        [PSCredential]
        $Credential,

        [parameter(Mandatory = 0)]
        [string[]]
        $TaskParameter,

        [parameter(Mandatory = 1)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]
        $Authentication
    )

    # Create RunSpacePools
    [System.Management.Automation.Runspaces.RunspacePool]$valentia.runspace.pool.instance = New-ValentiaRunSpacePool

    Write-Verbose ("Target Computers : [{0}]" -f ($ComputerNames -join ", "))
    $param = @{
        RunSpacePool       = $valentia.runspace.pool.instance
        ScriptToRunHash    = @{ScriptBlock    = $ScriptToRun}
        credentialHash     = @{Credential     = $Credential}
        TaskParameterHash  = @{TaskParameter  = $TaskParameter}
        AuthenticationHash = @{Authentication = $Authentication}
    }
    $valentia.runspace.asyncPipeline = New-Object 'System.Collections.Generic.List[AsyncPipeline]'

    foreach ($DeployMember in $valentia.Result.DeployMembers)
    {
        $AsyncPipeline = Invoke-ValentiaAsyncCommand @param -Deploymember $DeployMember
        $valentia.runspace.asyncPipeline.Add($AsyncPipeline)
    }
}