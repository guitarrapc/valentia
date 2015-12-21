#Requires -Version 3.0

#-- Private Module Function for AsyncPipelline execution --#

function Invoke-ValentiaAsyncPipeline
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $false)]
        [scriptBlock]$ScriptBlock,

        [parameter(mandatory = $true)]
        [PSCredential]$Credential,

        [parameter(mandatory = $false)]
        [hashtable]$TaskParameter,

        [parameter(mandatory = $true)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [parameter(mandatory = $true)]
        [bool]$UseSSL
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
        UseSSL             = @{UseSSL         = $UseSSL}
    }
    $valentia.runspace.asyncPipeline = New-Object 'System.Collections.Generic.List[AsyncPipeline]'

    foreach ($DeployMember in $valentia.Result.DeployMembers)
    {
        $AsyncPipeline = Invoke-ValentiaAsyncCommand @param -Deploymember $DeployMember
        $valentia.runspace.asyncPipeline.Add($AsyncPipeline)
    }
}