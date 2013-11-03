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

# --- Depends on following functions ---
#
#  Task
#  Invoke-ValetinaAsyncCommand
#  Get-valentiaCredential
#  Get-valentiaGroup
#  Import-valentiaConfigration
#  Import-valentiaModules
#  Clean
# 
# ---                                ---

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
        $SuccessStatus = $ErrorMessageDetail = @()

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


        # Swtich ScriptBlock or ScriptFile was selected
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
                                        
                    $SuccessStatus += $TaskFileStatus.SuccessStatus
                    $ErrorMessageDetail += $TaskFileStatus.ErrorMessageDetail                    
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
                $SuccessStatus += $false
                $ErrorMessageDetail += "TaskFile or ScriptBlock parameter must not be null"
                throw "TaskFile or ScriptBlock parameter must not be null"
            }
        }

        # Set Task as CurrentContext with taskkey
        $task = $currentContext.tasks.$taskKey
        $ScriptToRun = $task.Action
  

        # Obtain Remote Login Credential
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
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)

        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: $TotalDuration" -f $TotalDuration)
        ""

    ### Process



        # Create HashTable for Runspace
        $ScriptToRunHash = @{ScriptBlock = $ScriptToRun}
        $credentialHash = @{Credential = $Credential} 
        $TaskParameterHash = @{TaskParameter = $TaskParameter} 

        # Create a pool of 100 runspaces
        $pool = New-ValentiaRunSpacePool -PoolSize 50

        #Initialize AsyncPipelines
        $AsyncPipelines = @() 

        # Run ScriptBlock as Sequence for each DeployMember
        Write-Verbose ("Execute command : {0} " -f $ScriptToRun)
        Write-Verbose ("Target Computers : [{0}]" -f $DeployMembers)

        # Execute Async Job
        foreach ($DeployMember in $DeployMembers)
        {
            $AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRunHash $ScriptToRunHash -Deploymember $DeployMember -CredentialHash $credentialHash -TaskParameterHash $TaskParameterHash
        }

        # Create ScriptBlock to obtain AsyncStatus
        $ReceiveAsyncStatus = {Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines | group state,hostname -NoElement}

        # hide progress or not
        if (!$quiet)
        {
            Write-Warning -Message "$((&$ReceiveAsyncStatus).Name)"
        }

        
        # Monitoring status for Async result (Even if no monitoring, but asynchronous result will obtain after all hosts available)
        $sleepMS = 10
        $limitCount = 10000

        # hide progress or not
        if (!$quiet)
        {
            Write-Warning -Message ("Waiting for Asynchronous staus completed, or {0} sec to be complete." -f ($sleepMS * $limitCount / 1000))
        }

        while (($(&$ReceiveAsyncStatus) | where name -like "Running*").count -ge 1)
        {
            $count++

            # hide progress or not
            if (!$quiet)
            {
                if ($count % 100 -eq 0)
                {
                    # Show Current Status
                    Write-Warning -Message "$((&$ReceiveAsyncStatus).Name)"
                }
            }

            # Wait a moment
            sleep -Milliseconds $sleepMS

            # safety release for 100 sec
            if ($count -ge $limitCount)
            {
                break
            }
        }


        # Obtain Async Command Result
        if (!$quiet)
        {
            Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -ShowProgress | %{
                $result = @{}


            }{
                $ErrorMessageDetail += $_.ErrorMessageDetail           # Get ErrorMessageDetail
                $SuccessStatus += $_.SuccessStatus                     # Get success or error
                if ($_.host -ne $null){$result.$($_.host) = $_.result} # Get Result

                # Output to host
                $_.result
            }
        }
        else
        {
            Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -ShowProgress -quiet | %{
                $result = @{}

            }{
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


        # Remove pssession remains.
        try
        {            
            Write-Verbose "Remove all PSSession."
            Get-PSSession | Remove-PSSession
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            Write-Error $_
        }
        
        # Cleanup previous Job before start
        if ((Get-Job).count -gt 0)
        {
            Write-Verbose "Clean up previous Job"
            Get-Job | Remove-Job -Force
        }

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        throw $_

    }
    finally
    {

    ### End

        # Show Stopwatch for Total section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)


        # Get End Time
        $TimeEnd = (Get-Date).DateTime


        # obtain Result
        $CommandResult = [ordered]@{
            Success = !($SuccessStatus -contains $false)
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
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)

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
