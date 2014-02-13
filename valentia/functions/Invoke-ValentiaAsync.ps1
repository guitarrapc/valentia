#Requires -Version 3.0

#-- Public Module Asynchronous / Functions for Remote Execution --#

# valea
function Invoke-ValentiaAsync
{

<#

.SYNOPSIS 
Run Asynchronous valentia execution to remote host

.DESCRIPTION
Asynchronous running thread through AsyncPipeLine handling PS Runspace.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  valea 192.168.1.100 {Get-ChildItem}
--------------------------------------------
Get-ChildItem ScriptBlock execute on 192.168.1.100

.EXAMPLE
  valea 192.168.1.100 {Get-ChildItem; hostname}
--------------------------------------------
You can run multiple script in pipeline.

.EXAMPLE
  valea 192.168.1.100 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

.EXAMPLE
  valea 192.168.1.100,192.168.1.200 .\default.ps1
--------------------------------------------
You can target multiple deploymember with comma separated. Running Asynchronously.

.EXAMPLE
  valea DeployGroupFile.ps1 {ScriptBlock}
--------------------------------------------
Specify DeployGroupFile and ScriptBlock

.EXAMPLE
  valea DeployGroupFile.ps1 .\default.ps1
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
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

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
        Write-Verbose $valeWarningMessages.warn_import_configuration
        Import-valentiaConfigration 

        # Import default Modules
        Write-Verbose $valeWarningMessages.warn_import_modules
        Import-valentiaModules

        # Log Setting
        $LogPath = New-ValentiaLog

        # Swtich ScriptBlock or ScriptFile was selected
        switch ($true)
        {
            {$ScriptBlock} {
                # Assign ScriptBlock to run
                Write-Verbose ("ScriptBlock parameter '{0}' was selected." -f $ScriptBlock)
                $taskkey = Task -name ScriptBlock -action $ScriptBlock

                # Read Current Context
                $currentContext = $valentia.context.Peek()

                # Check Key duplicate or not
                if ($currentContext.executedTasks.Contains($taskKey))
                {
                    $valeErrorMessages.error_duplicate_task_name -f $Name
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
                Write-Verbose ("TaskFileName parameter '{0}' was selected." -f $TaskFileName)

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
  
        # Obtain Remote Login Credential (No need if clients are same user/pass)
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            Write-Error $_
        }

        # Obtain DeployMember IP or Hosts for deploy
        Write-Verbose "Get hostaddresses to connect."
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }

        # Show Stopwatch for Begin section
        Write-Verbose ("{0}Duration Second for Begin Section: {1}" -f "`t`t", $TotalstopwatchSession.Elapsed.TotalSeconds)

    #endregion

    #region Process

        # Create RunSpacePools
        $poolParam = @{
            minPoolSize = $valentia.poolSize.minPoolSize
            maxPoolSize = $valentia.poolSize.maxPoolSize
        }
        $pool = New-ValentiaRunSpacePool @poolParam

        # splatting
        $param = @{
            RunSpacePool      = $pool
            ScriptToRunHash   = @{ScriptBlock   = $ScriptToRun}
            credentialHash    = @{Credential    = $Credential}
            TaskParameterHash = @{TaskParameter = $TaskParameter}
        }

        # Execute Async Job
        Write-Verbose ("Execute command : {0} " -f $param.ScriptToRunHash.ScriptBlock)
        Write-Verbose ("Target Computers : [{0}]" -f ($DeployMembers -join ", "))

        $AsyncPipelines = @() 
        foreach ($DeployMember in $DeployMembers)
        {
            $AsyncPipelines += Invoke-ValentiaAsyncCommand @param -Deploymember $DeployMember
        }

        # Monitoring status for Async result (Even if no monitoring, but asynchronous result will obtain after all hosts available)
        Write-Verbose -Message ("Waiting for Asynchronous staus completed, or {0} sec to be complete." -f ($valentia.async.sleepMS * $valentia.async.limitCount / 1000))
        $ReceiveAsyncStatusScriptBlock = {Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines | group state,hostname -NoElement}
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        #region AsyncStatus monitoring
        while ((($ReceiveAsyncStatus = &$ReceiveAsyncStatusScriptBlock) | where name -like "Running*").count -ge 1)
        {
            $count++
            $completed     = $ReceiveAsyncStatus | where name -like "Completed*"
            $running       = $ReceiveAsyncStatus | where name -like "Running*"
            $statusPercent = ($completed.count/$ReceiveAsyncStatus.count) * 100

            # hide progress or not
            if (-not $PSBoundParameters.quiet.IsPresent -and ($sw.Elapsed.TotalMilliseconds -ge 500))
            {
                # hide progress or not
                if ($statusPercent -ne 100)
                {
                    $paramProgress = @{
                        Activity        = 'Async Execution Running Status....'
                        PercentComplete = $statusPercent
                        status          = ("{0}/{1}({2:0.00})% Completed" -f $completed.count, $ReceiveAsyncStatus.count, $statusPercent)
                    }
                    
                    Write-Progress @paramProgress
                    $sw.Reset()
                    $sw.Start()
                }
            }

            # Log Current Status
            if (-not $null-eq $prevRunningCount)
            {
                if ($running.count -lt $prevRunningCount)
                {
                    $ReceiveAsyncStatus.Name | Out-File -FilePath $LogPath -Encoding $valentia.fileEncode -Force -Append
                    [PSCustomObject]@{
                        DateTime  = Get-Date
                        Running   = $running.count
                        Completed = $completed.count
                    } | Out-File -FilePath $LogPath -Encoding $valentia.fileEncode -Force -Append
                }
            }              

            # Wait a moment
            sleep -Milliseconds $valentia.async.sleepMS

            # safety release for 100 sec
            if ($count -ge $valentia.async.limitCount){break;}

            $prevRunningCount = $running.count
        }

        # Clear Progress bar from Host,
        # Make sure this is critical, YOU MUST CLEAR PROGRESS BAR, other wise host output will be terriblly slow down.
        Write-Progress "done" "done" -Completed
        #endregion
        
        # Obtain Async Command Result
        if (-not $PSBoundParameters.quiet.IsPresent)
        {
            Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines `
            | %{$result = @{}}{
                $ErrorMessageDetail += $_.ErrorMessageDetail           # Get ErrorMessageDetail
                $SuccessStatus += $_.SuccessStatus                     # Get success or error
                if ($_.host -ne $null){$result.$($_.host) = $_.result} # Get Result

                # Output to host
                $_.result
            }
        }
        else
        {
            Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -quiet `
            | %{$result = @{}}{
                $ErrorMessageDetail += $_.ErrorMessageDetail           # Get ErrorMessageDetail
                $SuccessStatus += $_.SuccessStatus                     # Get success or error
                if ($_.host -ne $null){$result.$($_.host) = $_.result} # Get Result
            }
        }

        # Check Command Result
        if ($task.SuccessStatus -eq $false)
        {
            $ErrorMessageDetail += $task.ErrorMessageDetail
            $SuccessStatus += $task.SuccessStatus
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

        # Dispose RunspacePool
        Remove-ValentiaRunSpacePool -Pool $pool

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

    #endregion
    }
}