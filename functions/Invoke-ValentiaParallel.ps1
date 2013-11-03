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

# --- Depends on following functions ---
#
#  Task
#  Invoke-ValetinaCommandParallel
#  Get-valentiaCredential
#  Get-valentiaGroup
#  Import-valentiaConfigration
#  Import-valentiaModules
#  Clean
# 
# ---                                ---


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
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

        [Parameter(
            Position = 3, 
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [switch]
        $quiet
    )

    ### Begin

    try
    {        
        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = New-Object 'System.Collections.Generic.List[System.String]'

        # Get Start Time
        $TimeStart = (Get-Date).DateTime


        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            Write-Verbose $valeWarningMessages.warn_import_configuration
            Import-valentiaConfigration -Verbose

            # Import default Modules
            Write-Verbose $valeWarningMessages.warn_import_modules
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-valentiaConfigration
            Import-valentiaModules
        }
        

        # Log Setting
        $LogPath = New-ValentiaLog


        # Swtich ScriptBlock or ScriptFile(Task) was selected
        switch ($true)
        {
            {$ScriptBlock} {
                # Assign ScriptBlock to run
                Write-Verbose ("ScriptBlock parameter [ {0} ] was selected." -f $ScriptBlock)
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
                Write-Verbose ("TaskFileName parameter [ {0} ] was selected." -f $TaskFileName)

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
            $Credential = Get-ValentiaCredential
        }
        catch
        {
            $SuccessStatus.Add($false)
            $ErrorMessageDetail.Add($_)
            Write-Error $_
        }
        

        # Obtain DeployMember IP or Hosts for deploy
        $DeployMembers = Get-ValentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)

        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus.Add($DeployMembers.SuccessStatus)
            $ErrorMessageDetail.Add($DeployMembers.ErrorMessageDetail)
        }        


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""
        

    ### Process


        # Run ScriptBlock as Parallel for each DeployMember
        Write-Verbose ("Execute command {0} " -f $ScriptToRun)
        Write-Verbose ("Target Computers : [ {0} ] `n" -f $DeployMembers)
        
        try
        {
            # Flag for WSManInstance restart detection
            $WSManInstanceflag = $true

            # Check parameter for Invoke-Command
            Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
            Write-Verbose ("wsmanSessionlimit..... {0}" -f $($valentia.wsmanSessionlimit))
            Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))

            # execute workflow
            Invoke-ValentiaCommandParallel -PSComputerName $DeployMembers -ScriptToRun $ScriptToRun -wsmanSessionlimit $valentia.wsmanSessionlimit -TaskParameter $TaskParameter -PSCredential $Credential -ErrorAction Stop | %{
                $result = @{}
            
            }{
                $ErrorMessageDetail.Add([string]($_.ErrorMessageDetail))                        # Get ErrorMessageDetail
                $SuccessStatus.Add([string]($_.SuccessStatus))                                  # Get success or error
                if ($_.host -ne $null){$result.$($_.host) = $_.result}                          # Get Result
                

                # Output to host
                if(!$quiet)
                {
                    # Output to host
                    $_.result
                }

                # For wsman trap hit
                $WSManInstanceflag = $_.WSManInstanceflag
            }
            
            # Check WSManInstance flag if there are restart WinRM happens or not
            if ($WSManInstanceflag -eq $true)
            {
                Write-Warning ("WinRM session exceeded {0} and neerly limit of 25. Restarted WinRM on Remote Server to reset WinRM session." -f $valentia.wsmanSessionlimit)
                Write-Warning "Restart Complete, trying remote session again."

                # if hit then automatically rerun workflow
                Invoke-ValentiaCommandParallel -PSComputerName $DeployMembers -ScriptToRun $ScriptToRun -wsmanSessionlimit $valentia.wsmanSessionlimit -TaskParameter $TaskParameter -PSCredential $Credential -ErrorAction Stop | %{
                    $result = @{}
            
                }{
                    $ErrorMessageDetail.Add([string]($_.ErrorMessageDetail))                        # Get ErrorMessageDetail
                    $SuccessStatus.Add([string]($_.SuccessStatus))                                  # Get success or error
                    if ($_.host -ne $null){$result.$($_.host) = $_.result}                          # Get Result


                    if(!$quiet)
                    {
                        # Output to host
                        $_.result
                    }
                }
            }
        }
        catch
        {
            $SuccessStatus.Add($false)
            $ErrorMessageDetail.Add($_)
            Write-Error $_
        }
       
    }
    catch
    {
        $SuccessStatus.Add($false)
        $ErrorMessageDetail.Add($_)
        throw $_
    }
    finally
    {

    ### End

        # Show Stopwatch for Total section
        $TotalDuration += $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)

        # Get End Time
        $TimeEnd = (Get-Date).DateTime

        # obtain Result
        $CommandResult = [ordered]@{
            Success = ($SuccessStatus.FindAll({$args[0] -eq $false}).count -eq 0)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            TaskFileName = $TaskFileName
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            Result = $result
            ErrorMessage = $($ErrorMessageDetail.FindAll({$args[0] | where {$_ -ne ""} | where {$_ -ne $false}}) | sort -Unique)
        }
            
        # show result
        if (!$quiet)
        {
            [PSCustomObject]$CommandResult
        }
        else
        {
            ([PSCustomObject]$Commandresult).Success
        }
        
        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }

}
