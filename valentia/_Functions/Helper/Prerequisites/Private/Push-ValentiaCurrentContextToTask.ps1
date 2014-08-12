#Requires -Version 3.0

#-- Public Module Functions to load Task --#

# Task

<#
.SYNOPSIS 
Execute Task and push into CurrentContext

.NOTES
Author: guitarrapc
Created: 31/July/2014

.EXAMPLE
Push-ValentiaCurrentContextToTask -ScriptBlock $scriptBlock -TaskFileName $TaskFileName
#>
function Push-ValentiaCurrentContextToTask
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [ScriptBlock]
        $ScriptBlock,

        [parameter(Mandatory = 0)]
        [string]
        $TaskFileName
    )

    # Swtich ScriptBlock or ScriptFile was selected
    switch ($true)
    {
        {$ScriptBlock} {
            # run Task with ScriptBlock
            ("ScriptBlock parameter [ {0} ] was selected." -f $ScriptBlock) | Write-ValentiaVerboseDebug
            $taskkey = Task -name ScriptBlock -action $ScriptBlock

            # Read Current Context
            $currentContext = $valentia.context.Peek()
        }
        {$TaskFileName} {
            # check file exist or not
            if (-not(Test-Path (Join-Path (Get-Location).Path $TaskFileName)))
            {
                $TaskFileStatus = [PSCustomObject]@{
                    ErrorMessageDetail = "TaskFileName '{0}' not found in '{1}' exception!!" -f $TaskFileName,(Join-Path (Get-Location).Path $TaskFileName)
                    SuccessStatus = $false
                }             
                $valentia.Result.SuccessStatus += $TaskFileStatus.SuccessStatus
                $valentia.Result.ErrorMessageDetail += $TaskFileStatus.ErrorMessageDetail                    
            }
                
            # Read Task File and get Action to run
            ("TaskFileName parameter '{0}' was selected." -f $TaskFileName) | Write-ValentiaVerboseDebug

            # run Task $TaskFileName inside functions and obtain scriptblock written in.
            $taskkey = & $TaskFileName

            # Read Current Context
            $currentContext = $valentia.context.Peek()
        }
        default {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += "TaskFile or ScriptBlock parameter must not be null"
            throw "TaskFile or ScriptBlock parameter must not be null"
        }
    }

    return $currentContext.tasks.$taskKey
}
