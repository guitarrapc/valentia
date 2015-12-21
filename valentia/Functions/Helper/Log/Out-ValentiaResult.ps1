#Requires -Version 3.0

#-- Helper for valentia --#
#-- End Result Execution -- #

function Out-ValentiaResult
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [System.Diagnostics.Stopwatch]$StopWatch,

        [parameter(mandatory = $true)]
        [string]$Cmdlet,

        [parameter(mandatory = $false)]
        [string]$TaskFileName = "",

        [parameter(mandatory = $true)]
        [string[]]$DeployGroups,

        [parameter(mandatory = $true)]
        [bool]$SkipException,

        [parameter(mandatory = $true)]
        [bool]$Quiet
    )

    # obtain Result
    $CommandResult = [ordered]@{
        Success         = !($valentia.Result.SuccessStatus -contains $false)
        TimeStart       = $valentia.Result.TimeStart
        TimeEnd         = (Get-Date).DateTime
        TotalDuration   = $stopwatch.Elapsed.TotalSeconds
        Module          = "$($MyInvocation.MyCommand.Module)"
        Cmdlet          = $Cmdlet
        Alias           = "$((Get-Alias | where ResolvedCommandName -eq $Cmdlet).Name)"
        TaskFileName    = $TaskFileName
        ScriptBlock     = "{0}" -f $valentia.Result.ScriptTorun
        DeployGroup     = "{0}" -f "$($DeployGroups -join ', ')"
        TargetHostCount = $($valentia.Result.DeployMembers).count
        TargetHosts     = "{0}" -f ($valentia.Result.DeployMembers -join ', ')
        Result          = $valentia.Result.Result
        SkipException   = $SkipException
        ErrorMessage    = $($valentia.Result.ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
    }

    # show result
    WriteValentiaResultHost -quiet $Quiet -CommandResult $CommandResult

    # output result Log as json
    OutValentiaResultLog -CommandResult $CommandResult
}