#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

function Invoke-ValentiaJobProcess
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
        $SkipException
    )

    # Splatting
    $param = @{
        ComputerNames   = $ComputerNames
        ScriptToRun     = $ScriptToRun
        Credential      = $Credential
        TaskParameter   = $TaskParameter
        Authentication  = $Authentication
        SkipException   = $SkipException
        ErrorAction     = $ErrorActionPreference
    }

    # Run ScriptBlock as Sequence for each DeployMember
    Write-Verbose ("Execute command : {0}" -f $param.ScriptToRun)
    Write-Verbose ("Target Computers : '{0}'" -f ($param.ComputerNames -join ", "))

    # Executing job
    Invoke-ValentiaCommand @param  `
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

        if(!$quiet)
        {
            "Show result for host '{0}'" -f $_.host | Write-ValentiaVerboseDebug
            $_.result
        }
    }
}