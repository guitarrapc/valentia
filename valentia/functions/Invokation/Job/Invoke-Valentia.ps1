#Requires -Version 3.0

#-- Public Module Job / Functions for Remote Execution --#

# vale
function Invoke-Valentia
{

<#

.SYNOPSIS 
1 of invoking valentia by PowerShell Backgroud Job execution to remote host

.DESCRIPTION
Run Job valentia execution to remote host

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  vale 192.168.1.100 {Get-ChildItem}
--------------------------------------------
Get-ChildItem ScriptBlock execute on 192.168.1.100

.EXAMPLE
  vale 192.168.1.100 {Get-ChildItem; hostname}
--------------------------------------------
You can run multiple script in pipeline.

.EXAMPLE
  vale 192.168.1.100 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

.EXAMPLE
  vale 192.168.1.100,192.168.1.200 .\default.ps1
--------------------------------------------
You can target multiple deploymember with comma separated. Running Synchronously.

.EXAMPLE
  vale DeployGroupFile.ps1 {ScriptBlock}
--------------------------------------------
Specify DeployGroupFile and ScriptBlock

.EXAMPLE
  vale DeployGroupFile.ps1 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

#>

    [CmdletBinding(DefaultParameterSetName = "TaskFileName")]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]
        $DeployGroups,

        [Parameter(
            Position = 1, 
            Mandatory = 1, 
            ParameterSetName = "TaskFileName",
            HelpMessage = "Move to Brach folder you sat taskfile, then input TaskFileName. exclusive with ScriptBlock.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskFileName,

        [Parameter(
            Position = 1,
            Mandatory = 1,
            ParameterSetName = "SctriptBlock",
            HelpMessage = "Input Script Block {hogehoge} you want to execute with this commandlet. exclusive with TaskFileName")]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(
            Position = 2, 
            Mandatory = 0,
            HelpMessage = "Usually automatically sat to DeployGroup Folder. No need to modify.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(
            Position = 3, 
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $TaskParameter,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [switch]
        $quiet
    )

    #region Begin

    try
    {
        # Preference
        $script:ErrorActionPreference = $valentia.errorPreference

        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime

        # Import default Configurations
        $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
        Import-valentiaConfigration

        # Import default Modules
        $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
        Import-valentiaModules

        # Log Setting
        $LogPath = New-ValentiaLog

        # Swtich ScriptBlock or ScriptFile was selected
        switch ($true)
        {
            {$ScriptBlock} {
                # Assign ScriptBlock to run
                ("ScriptBlock parameter [ {0} ] was selected." -f $ScriptBlock) | Write-ValentiaVerboseDebug
                $taskkey = Task -name ScriptBlock -action $ScriptBlock

                # Read Current Context
                $currentContext = $valentia.context.Peek()

                # Check Key duplicate or not
                if ($currentContext.executedTasks.Contains($taskKey))
                {
                    $valeErrorMessages.error_duplicate_task_name -F $Name
                }
            }
            {$TaskFileName} {
                # check file exist or not
                if (-not(Test-Path (Join-Path (Get-Location).Path $TaskFileName)))
                {
                    $TaskFileStatus = [PSCustomObject]@{
                        ErrorMessageDetail = "TaskFileName '{0}' not found in '{1}' exception!!" -f $TaskFileName,(Join-Path (Get-Location).Path $TaskFileName)
                        SuccessStatus = $false
                    }             
                    $SuccessStatus += $TaskFileStatus.SuccessStatus
                    $ErrorMessageDetail += $TaskFileStatus.ErrorMessageDetail                    
                }
                
                # Read Task File and get Action to run
                ("TaskFileName parameter '{0}' was selected." -f $TaskFileName) | Write-ValentiaVerboseDebug

                # run Task $TaskFileName inside functions and obtain scriptblock written in.
                $taskkey = & $TaskFileName
                $currentContext = $valentia.context.Peek()

                # Check Key duplicate or not
                if ($currentContext.executedTasks.Contains($taskKey))
                {
                    $valeErrorMessages.error_duplicate_task_name -F $Name
                    $SuccessStatus += $false
                }
            }
            default {
                $SuccessStatus += $false
                $ErrorMessageDetail += "TaskFile or ScriptBlock parameter must not be null"
                throw "TaskFile or ScriptBlock parameter must not be null"
            }
        }
  
        # Set Task as CurrentContext with taskkey
        $task = $currentContext.tasks.$taskKey
        $ScriptToRun = $task.Action

        # Cleanup previous Job before start
        if ((Get-Job).count -gt 0)
        {
            "Clean up previous Job" | Write-ValentiaVerboseDebug
            Get-Job | Remove-Job -Force -Verbose:$VerbosePreference
        }

        # Obtain Remote Login Credential (No need if clients are same user/pass)
        try
        {
            $Credential = Get-ValentiaCredential -Verbose:$VerbosePreference
            $SuccessStatus += $true
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            Write-Error $_
        }

        # Obtain DeployMember IP or Hosts for deploy
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups

        # Show Stopwatch for Begin section
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalstopwatchSession.Elapsed.TotalSeconds)

    #endregion

    #region Process

        # Splatting
        $param = @{
            ComputerNames = $DeployMembers
            ScriptToRun   = $ScriptToRun
            Credential    = $Credential
            TaskParameter = $TaskParameter
        }

        # Run ScriptBlock as Sequence for each DeployMember
        Write-Verbose ("Execute command : {0}" -f $param.ScriptToRun)
        Write-Verbose ("Target Computers : '{0}'" -f ($param.ComputerNames -join ", "))

        # Executing job
        Invoke-ValentiaCommand @param  `
        | %{$result = @{}}{
            # Obtain parameter to show on log
            $ErrorMessageDetail += $_.ErrorMessageDetail           # Get ErrorMessageDetail
            $SuccessStatus += $_.SuccessStatus                     # Get success or error
            if ($_.host -ne $null){$result.$($_.host) = $_.result} # Get Result

            if(!$quiet)
            {
                "Show result for host '{0}'" -f $_.host | Write-ValentiaVerboseDebug
                $_.result
            }
        }

    #endregion
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        throw $_
    }
    finally
    {
    #region End

        # reverse Error Action Preference
        $script:ErrorActionPreference = $valentia.originalErrorActionPreference

        # obtain Result
        $CommandResult = [ordered]@{
            Success        = !($SuccessStatus -contains $false)
            TimeStart      = $TimeStart
            TimeEnd        = (Get-Date).DateTime
            TotalDuration  = $TotalstopwatchSession.Elapsed.TotalSeconds
            Module         = "$($MyInvocation.MyCommand.Module)"
            Cmdlet         = "$($MyInvocation.MyCommand.Name)"
            Alias          = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            TaskFileName   = $TaskFileName
            ScriptBlock    = "$ScriptToRun"
            DeployGroup    = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts    = "$DeployMembers"
            Result         = $result
            ErrorMessage   = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        if (-not $PSBoundParameters.quiet.IsPresent)
        {
            # Show Stopwatch for Total section
            Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $CommandResult.TotalDuration)

            [PSCustomObject]$CommandResult
        }
        else
        {
            ([PSCustomObject]$Commandresult).Success
        }

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding $valentia.fileEncode -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    #endRegion
    }
}
