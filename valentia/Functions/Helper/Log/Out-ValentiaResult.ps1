#Requires -Version 3.0

#-- Helper for valentia --#
#-- End Result Execution -- #

function Out-ValentiaResult
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [System.Diagnostics.Stopwatch]$StopWatch,

        [parameter(Mandatory = 1)]
        [string]$Cmdlet,

        [parameter(Mandatory = 0)]
        [string]$TaskFileName = "",

        [parameter(Mandatory = 1)]
        [string[]]$DeployGroups,

        [parameter(Mandatory = 1)]
        [bool]$SkipException,

        [parameter(Mandatory = 1)]
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