#Requires -Version 3.0

#-- Public Module workflow / Functions for Remote Execution --#

# valep
function Invoke-ValentiaParallel
{

<#
.SYNOPSIS 
1 of invoking valentia by workflow execution to remote host

.DESCRIPTION
Concurrent running thread through WmiPrvSE.exe
workflow not allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  valep 192.168.1.100 {Get-ChildItem}
--------------------------------------------
Get-ChildItem ScriptBlock execute on 192.168.1.100

.EXAMPLE
  valep 192.168.1.100 {Get-ChildItem; hostname}
--------------------------------------------
You can run multiple script in pipeline.

.EXAMPLE
  valep 192.168.1.100 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

.EXAMPLE
  valep 192.168.1.100,192.168.1.200 .\default.ps1
--------------------------------------------
You can target multiple deploymember with comma separated. Running Parallel with 5 each runspace.

.EXAMPLE
  valep DeployGroupFile.ps1 {ScriptBlock}
--------------------------------------------
Specify DeployGroupFile and ScriptBlock

.EXAMPLE
  valep DeployGroupFile.ps1 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.
#>


    [CmdletBinding(
    DefaultParameterSetName = "TaskFileName")]
    param
    (
        [Parameter(
            Position = 0, 
            Mandatory = 1,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress]." )]
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
            HelpMessage = "Input Script Block {Cmdlet} you want to execute with this commandlet. exclusive with TaskFileName.")]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(
            Position = 2, 
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
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
        $SuccessStatus = $ErrorMessageDetail = New-Object 'System.Collections.Generic.List[System.String]'

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

        # Swtich ScriptBlock or ScriptFile(Task) was selected
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
                        ErrorMessageDetail = "TaskFileName [ {0} ] not found in {1} exception!!" -f $TaskFileName,(Join-Path (Get-Location).Path $TaskFileName)
                        SuccessStatus = $false
                    }      
                    $SuccessStatus.Add($TaskFileStatus.SuccessStatus)
                    $ErrorMessageDetail.Add($TaskFileStatus.ErrorMessageDetail)
                }

                # Read Task File and get Action to run
                ("TaskFileName parameter [ {0} ] was selected." -f $TaskFileName) | Write-ValentiaVerboseDebug

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
                $SuccessStatus.Add($false)
                $ErrorMessageDetail.Add("TaskFile or ScriptBlock parameter must not be null")
                throw "TaskFile or ScriptBlock parameter must not be null"
            }
        }

        # Set Task as CurrentContext with taskkey
        $task = $currentContext.tasks.$taskKey
        $ScriptToRun = $task.Action

        # Obtain Remote Login Credential (No need if clients are same user/pass)
        try
        {
            $Credential = Get-ValentiaCredential -Verbose:$VerbosePreference
        }
        catch
        {
            $SuccessStatus.Add($false)
            $ErrorMessageDetail.Add($_)
            Write-Error $_
        }
        
        # Obtain DeployMember IP or Hosts for deploy
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-ValentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups

        # Show Stopwatch for Begin section
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalstopwatchSession.Elapsed.TotalSeconds)
        
    #endregion

    #region Process

        # Run ScriptBlock as Parallel for each DeployMember
        Write-Verbose ("Execute command {0} " -f $ScriptToRun)
        Write-Verbose ("Target Computers : [ {0} ] `n" -f $DeployMembers)
        
        try
        {
            # execute workflow
            if (-not $PSBoundParameters.quiet.IsPresent)
            {
                Invoke-ValentiaCommandParallel -PSComputerName $DeployMembers -ScriptToRun $ScriptToRun -TaskParameter $TaskParameter -PSCredential $Credential `
                | %{$result = @{}}{
                    $ErrorMessageDetail.Add([string]($_.ErrorMessageDetail))                        # Get ErrorMessageDetail
                    $SuccessStatus.Add([string]($_.SuccessStatus))                                  # Get success or error
                    if ($_.host -ne $null){$result.$($_.host) = $_.result}                          # Get Result
                    
                    # Output to host
                    $_.result
                }
            }
            else
            {
                Invoke-ValentiaCommandParallel -PSComputerName $DeployMembers -ScriptToRun $ScriptToRun -TaskParameter $TaskParameter -PSCredential $Credential -quiet `
                | %{$result = @{}}{
                    $ErrorMessageDetail.Add([string]($_.ErrorMessageDetail))                        # Get ErrorMessageDetail
                    $SuccessStatus.Add([string]($_.SuccessStatus))                                  # Get success or error
                    if ($_.host -ne $null){$result.$($_.host) = $_.result}                          # Get Result
                }
            }
        }
        catch
        {
            $SuccessStatus.Add($false)
            $ErrorMessageDetail.Add($_)
            Write-Error $_
        }

    #endregion       
    }
    catch
    {
        $SuccessStatus.Add($false)
        $ErrorMessageDetail.Add($_)
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
            ErrorMessage   = $($ErrorMessageDetail.FindAll({$args[0] | where {$_ -ne ""} | where {$_ -ne $false}}) | sort -Unique)
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
