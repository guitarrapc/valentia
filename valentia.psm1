#Requires -Version 3.0

Write-Verbose "Loading valentia.psm1"

# valentia
#
# Copyright (c) 2013 guitarrapc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


#-- Public Class load for Asynchronous execution (MultiThread) --#

Add-Type @'
public class AsyncPipeline
{
    public System.Management.Automation.PowerShell Pipeline ;
    public System.IAsyncResult AsyncResult ;
}
'@



#-- Public Module Functions to load Task --#

# Task
function Get-ValentiaTask{

<#

.SYNOPSIS 
Load Task File format into $valentia.context.tasks.$taskname hashtable.

.DESCRIPTION
Loading ps1 file which format is task <taskname> -Action { <scriptblock> }

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
task taskname -Action { What you want to do in ScriptBlock}
--------------------------------------------
This is format sample.

.EXAMPLE
task lstest -Action { Get-ChildItem c:\ }
--------------------------------------------
Above example will create taskkey as lstest, run "Get-ChildItem c:\" when invoke.

#>


    [CmdletBinding()]  
    param(
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input TaskName you want to set and not dupricated.")]
        [string]
        $Name = $null,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Write ScriptBlock Action to execute with this task.")]
        [scriptblock]
        $Action = $null
    )

    # Load Task
    Write-Verbose $valeWarningMessages.warn_import_task_begin
    $newTask = @{
        Name = $Name
        Action = $Action
    }

    # convert into LowerCase for keyname
    Write-Verbose $valeWarningMessages.warn_import_task_end
    $taskKey = $Name.ToLower()

    # Get current context variables
    Write-Verbose $valeWarningMessages.warn_get_current_context
    $currentContext = $valentia.context.Peek()

    # Check dupricate key name
    if ($currentContext.tasks.ContainsKey($taskKey))
    {
        throw $valeErrorMessages.error_duplicate_task_name -F $Name
    }
    else
    {
        Write-Verbose $valeWarningMessages.warn_set_taskkey
        $currentContext.tasks.$taskKey = $newTask
    }

    # return taskkey to determin key name in $valentia.context.tasks.$taskkey
    return $taskKey

}




#-- Public Module workflow / Functions for Remote Execution --#


# valep
function Invoke-ValentiaParallel{

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
    param(
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
        $CommandResult = [PSCustomObject]@{
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
            $CommandResult
        }
        else
        {
            $CommandResult.success
        }
        
        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }

}


workflow Invoke-ValentiaCommandParallel{

<#

.SYNOPSIS 
Invoke workflow valentia execution to remote host

.DESCRIPTION
Concurrent running thread through WmiPrvSE.exe
workflow not allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

# --- Depends on following functions ---
#
#  Invoke-ValetinaParallel
# 
# ---                                ---


.EXAMPLE
  CommandParallel -ScriptToRun $ScriptToRun
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommandParallel -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommandParallel {test-connection localhost}
--------------------------------------------

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory =$true,
            HelpMessage = "Input ScriptBlock. ex) Get-ChildItem; Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]
        $ScriptToRun,

        [Parameter(
            Position = 1,
            Mandatory =$true,
            HelpMessage = "Input wsmanSession Threshold number to restart wsman")]
        [int]
        $wsmanSessionlimit,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter
    )

    foreach -Parallel ($DeployMember in $PSComputerName){
        InlineScript
        {
            
            # Initializing stopwatch
            $stopwatchSession = Invoke-Command {[System.Diagnostics.Stopwatch]::StartNew()}
            
            # Inherite variable
            [HashTable]$task = @{}

            # Get Host
            $task.host = $using:DeployMember

            # Executing query
            try
            {
                # Create ScriptBlock
                $WorkflowScript = [ScriptBlock]::Create($using:ScriptToRun)

                # Run ScriptBlock
                $task.result = Invoke-Command -ScriptBlock {&$WorkflowScript} -ErrorAction Stop -ArgumentList $TaskParameter
                $task.WSManInstanceflag = $false
            }
            catch 
            {
                # Show Error Message
                Write-Error $_

                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
            }


            # Get Duration Seconds for each command
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            $DurationMessage = {"$($using:DeployMember) exec Duration Sec :$Duration"}
            $MessageStopwatch = Invoke-Command -ScriptBlock {&$DurationMessage}

            # Show Duration Seconds
            if (!$quiet)
            {
                Write-Warning -Message ("`t`t{0}" -f $MessageStopwatch)
            }
            
            # Get Current host WSManInstance (No need set Connection URI as it were already connecting
            $WSManInstance = Get-WSManInstance shell -Enumerate

            # Close Remote Connection existing by workflow session if session count up to $valentia.wsmanSessionlimit
            # Remove or Restart session will cause error but already session is over and usually session terminated in 90 seconds
            if ($WSManInstance.count -ge $using:wsmanSessionlimit)
            {

                # Will remove specific session you select include current. (In this command will be all session)
                $WSManInstance | %{Remove-WSManInstance -ConnectionURI http://localhost:5985/wsman shell @{shellid=$_.ShellId}}
                
                # Will Restart WinRM and kill all sessions
                try
                {
                    # if restart WinRM happens, all result in this session will be voided
                    Restart-Service -Name WinRM -Force -PassThru -ErrorAction Stop
                }
                catch
                {
                    Write-Error $_

                    $task.SuccessStatus = $false
                    $task.ErrorMessageDetail = $_
                }

            }
            
            # Output $task variable to file. This will obtain by other cmdlet outside workflow.
            return $task
        }
    }
   
}



#-- Public Module Job / Functions for Remote Execution --#


# vale
function Invoke-Valentia{

<#

.SYNOPSIS 
1 of invoking valentia by PowerShell Backgroud Job execution to remote host

.DESCRIPTION
Run Job valentia execution to remote host

.NOTES
Author: guitarrapc
Created: 20/June/2013

# --- Depends on following functions ---
#
#  Task
#  Invoke-ValetinaCommand
#  Get-valentiaCredential
#  Get-valentiaGroup
#  Import-valentiaConfigration
#  Import-valentiaModules
#  Clean
# 
# ---                                ---

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
    param(
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


        # Cleanup previous PSSession before start
        if ((Get-PSSession).count -gt 0)
        {
            Write-Verbose "Clean up previous PSSession"
            Get-PSSession | Remove-PSSession
        }

        # Cleanup previous Job before start
        if ((Get-Job).count -gt 0)
        {
            Write-Verbose "Clean up previous Job"
            Get-Job | Remove-Job -Force
        }


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


        # Create PSSessions
        Write-Verbose "Starting create PSSession."

        try
        {
            $Sessions = New-PSSession -ComputerName $DeployMembers -Credential $Credential -Name $($DeployMember -replace ".","")
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            Write-Error $_
        }

        # Check Connection Status
        if (!$quiet)
        {
            if ($Sessions.State -eq "opened")
            {
                Write-Verbose ("Session [ {0} ] created with [ {1} ]" -f $Sessions.State, $Sessions.ComputerName)
            }
            else
            {
                Write-Warning ("Session [ {0} ] not created with [ {1} ]" -f $Sessions.State, $Sessions.ComputerName)
            }
        }


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""

    ### Process

        # Run ScriptBlock as Sequence for each DeployMember
        Write-Verbose ("Execute command : {0}" -f $ScriptToRun)
        Write-Verbose ("Target Computers : [{0}]" -f $Sessions.ComputerName)

        # Flag for WSManInstance restart detection
        $WSManInstanceflag = $true

        # Executing job
        Invoke-ValentiaCommand -Session $Sessions -ScriptToRun $ScriptToRun -wsmanSessionlimit $valentia.wsmanSessionlimit -TaskParameter $TaskParameter | %{
            $result = @{}
            
        }{
            # Obtain parameter to show on log
            $ErrorMessageDetail += $_.ErrorMessageDetail
            $SuccessStatus += $_.SuccessStatus

            # Output to host
            if(!$quiet)
            {
                # Output to host
                $_.result
            }

            # For wsman trap hit
            $WSManInstanceflag = $_.WSManInstanceflag
        }


        # Check WinRM trap was hit or not
        if ($WSManInstanceflag -eq $true)
        {
            Write-Warning ("WinRM session exceeded {0} and neerly limit of 25. Restarted WinRM on Remote Server to reset WinRM session." -f $valentia.wsmanSessionlimit)
            Write-Warning "Restart Complete, trying remote session again."

            # if hit then automatically rerun command
            Invoke-ValentiaCommand -Session $Sessions -ScriptToRun $ScriptToRun -wsmanSessionlimit $valentia.wsmanSessionlimit -TaskParameter $TaskParameter | %{
                $result = @{}
            
            }{
                # Obtain parameter to show on log
                $ErrorMessageDetail += $_.ErrorMessageDetail
                $SuccessStatus += $_.SuccessStatus

                # Output to host
                if(!$quiet)
                {
                    $_.result
                }

            }
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
        $CommandResult = [PSCustomObject]@{
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
            $CommandResult
        }
        else
        {
            $CommandResult.success
        }

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}




function Invoke-ValentiaCommand{

<#

.SYNOPSIS 
Invoke Command as Job to remote host

.DESCRIPTION
Background job execution with Invoke-Command.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

# --- Depends on following functions ---
#
#  Invoke-Valetina
# 
# ---                                ---

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun $ScriptToRun
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}
--------------------------------------------

.EXAMPLE
  Invoke-ValentiaCommand {test-connection localhost}
--------------------------------------------

#>

    [CmdletBinding(DefaultParameterSetName = "All")]
    param(
        [Parameter(
            Position = 0,
            ParameterSetName = "Default",
            ValueFromPipeline =$True,
            ValueFromPipelineByPropertyName =$True,
            Mandatory =$true,
            HelpMessage = "Input Session")]
        [System.Management.Automation.Runspaces.PSSession[]]
        $Sessions,

        [Parameter(
            Position = 1,
            ParameterSetName = "Default",
            ValueFromPipeline =$True,
            ValueFromPipelineByPropertyName =$True,
            Mandatory =$true,
            HelpMessage = "Input ScriptBlock. ex) Get-ChildItem, Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]
        $ScriptToRun,

        [Parameter(
            Position = 2,
            Mandatory =$true,
            HelpMessage = "Input wsmanSession Threshold number to restart wsman")]
        [int]
        $wsmanSessionlimit,

        [Parameter(
            Position = 3, 
            Mandatory = 0,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [string[]]
        $TaskParameter
    )


    # Set variable for Stopwatch
    [decimal]$DurationTotal = 0

    foreach ($session in $Sessions)
    {
        # Initializing stopwatch
        $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Inherite variable
        [HashTable]$task = @{}

        # Get Host
        $task.host = $session.ComputerName

        # Check parameter for Invoke-Command
        Write-Verbose ("Session..... {0}" -f $($Sessions))
        Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
        Write-Verbose ("wsmanSessionlimit..... {0}" -f $($wsmanSessionlimit))
        Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))

        # Run ScriptBlock in Job
        Write-Verbose ("Running ScriptBlock to {0} as Job" -f $session)
        $job = Invoke-Command -Session $session -ScriptBlock $ScriptToRun -ArgumentList $TaskParameter -AsJob

        try
        {
            # Recieve ScriptBlock result from Job
            Write-Verbose "Receiving Job result."
            $task.result = Receive-Job -Job $job -Wait -ErrorAction Stop
            $task.WSManInstanceflag = $false
            
        }
        catch [System.Management.Automation.ActionPreferenceStopException]
        {
            # Show Error Message
            Write-Error $_

            # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
            $task.SuccessStatus = $false
            $task.ErrorMessageDetail = $_

        }

        # Get Duration Seconds for each command
        $Duration = $stopwatchSession.Elapsed.TotalSeconds
        $DurationMessage = "{0} exec Duration Sec :{1}" -f $session.ComputerName, $Duration
        $MessageStopwatch = Invoke-Command -ScriptBlock {$DurationMessage}

        # Show Duration Seconds
        if(!$quiet)
        {
            Write-Warning -Message $MessageStopwatch
        }

        # Add each command exec time to Totaltime
        $DurationTotal += $Duration
        

        # Get Current host WSManInstance (No need set Connection URI as it were already connecting
        $WSManInstance = Get-WSManInstance shell -Enumerate

        # Close Remote Connection existing by restart wsman if current wsmanInstance count greater than $valentia.wsmanSessionlimit
        # Remove or Restart session will cause error but already session is over and usually session terminated in 90 seconds
        if ($WSManInstance.count -ge $valentia.wsmanSessionlimit)
        {     
            # Will Restart WinRM and kill all sessions
            try
            {
                # if restart WinRM happens, all result in this session will be voided
                Restart-Service -Name WinRM -Force -PassThru -ErrorAction Stop 
            }
            catch
            {
                Write-Error $_

                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
            }

        }

        # Output $task variable to file. This will obtain by other cmdlet outside workflow.
        $task

    }

    # Show stopwatch result
    Write-Verbose ("`t`tTotal exec Command Sec: {0}" -f $DurationTotal)
    "" | Out-Default

}





#-- Public Module Asynchronous / Functions for Remote Execution --#


# valea
function Invoke-ValentiaAsync{

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
    param(
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
        $pool = New-ValentiaRunSpacePool -PoolSize 10

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
        $CommandResult = [PSCustomObject]@{
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
            $CommandResult
        }
        else
        {
            $CommandResult.success
        }

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}


#-- Private Module Function for Async execution --#

function Invoke-ValentiaAsyncCommand{

<#
.SYNOPSIS 
Creating a PowerShell pipeline then executes a ScriptBlock Asynchronous with Remote Host.

.DESCRIPTION
Pipeline will execute less overhead then Invoke-Command, Job, or PowerShell Cmdlet.
All cmdlet will execute with Invoke-Command -ComputerName -Credential wrapped by Invoke-ValentiaAsync pipeline.
Wrapped by Pipeline will give you avility to run Invoke-Command Asynchronous. (Usually Sencronous)
Asynchrnous execution will complete much faster then Syncronous execution.
   
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
Invoke-ValeinaAsyncCommand -RunspacePool $(New-ValentiaRunspacePool 10) `
    -ScriptBlock { Get-ChildItem } `
    -Computers $(Get-Content .\ComputerList.txt)
    -Credential $(Get-Credential)

--------------------------------------------
Above example will concurrently running with 10 processes for each Computers.

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "Runspace Poll required to set one or more, easy to create by New-ValentiaRunSpacePool.")]
        $RunspacePool,
        
        [Parameter(
            Position=1,
            Mandatory,
            HelpMessage = "The scriptblock to be executed to the Remote host.")]
        [HashTable]
        $ScriptToRunHash,
        
        [Parameter(
            Position=2,
            Mandatory,
            HelpMessage = "Target Computers to be execute.")]
        [string[]]
        $DeployMembers,
        
        [Parameter(
            Position=3,
            Mandatory,
            HelpMessage = "Remote Login PSCredentail for PS Remoting. (Get-Credential format)")]
        [HashTable]
        $CredentialHash,

        [Parameter(
            Position=4,
            Mandatory,
            HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [HashTable]
        $TaskParameterHash
    )


    try
    {
        # Declare execute Comdlet format as Invoke-Command
        $InvokeCommand = {
            param(
                $ScriptToRunHash,
                $ComputerName,
                $CredentialHash,
                $TaskParameterHash
            )
        
            Invoke-Command -ScriptBlock $($ScriptToRunHash.Values) -ComputerName $($ComputerName.Values) -Credential $($CredentialHash.Values) -ArgumentList $($TaskParameterHash.Values)
        }

        # Create Hashtable for ComputerName passed to Pipeline
        $ComputerName = @{ComputerName = $DeployMember}

        # Create PowerShell Instance
        Write-Verbose "Creating PowerShell Instance"
        $Pipeline = [System.Management.Automation.PowerShell]::Create()

        # Add Script and Parameter arguments from Hashtables
        Write-Verbose "Adding Script and Arguments Hastables to PowerShell Instance"
        Write-Verbose ('Add InvokeCommand Script : {0}' -f $InvokeCommand)
        Write-Verbose ("Add ScriptBlock Argument..... Keys : {0}, Values : {1}" -f $($ScriptToRunHash.Keys), $($ScriptToRunHash.Values))
        Write-Verbose ("Add ComputerName Argument..... Keys : {0}, Values : {1}" -f $($ComputerName.Keys), $($ComputerName.Values))
        Write-Verbose ("Add Credential Argument..... Keys : {0}, Values : {1}" -f $($CredentialHash.Keys), $($CredentialHash.Values))
        Write-Verbose ("Add ArgumentList Argument..... Keys : {0}, Values : {1}" -f $($TaskParameterHash.Keys), $($TaskParameterHash.Values))
        $Pipeline.AddScript($InvokeCommand).AddArgument($ScriptToRunHash).AddArgument($ComputerName).AddArgument($CredentialHash).AddArgument($TaskParameterHash) > $null

        # Add RunSpacePool to PowerShell Instance
	    Write-Verbose ("Adding Runspaces {0}" -f $RunspacePool)
        $Pipeline.RunspacePool = $RunspacePool

        # Invoke PowerShell Command
        Write-Verbose "Invoking PowerShell Instance"
	    $AsyncResult = $Pipeline.BeginInvoke() 

        # Get Result
        Write-Verbose "Obtain result"
	    $Output = New-Object AsyncPipeline 
	
        # Output Pipeline Infomation
	    $Output.Pipeline = $Pipeline

        # Output AsyncCommand Result
	    $Output.AsyncResult = $AsyncResult
	
        Write-Verbose ("Output Result '{0}' and '{1}'" -f $Output.Pipeline, $Output.AsyncResult)
	    return $Output

    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        Write-Error $_
    }
}



function New-ValentiaRunSpacePool{
<#
.SYNOPSIS 
Create a PowerShell Runspace Pool.

.DESCRIPTION
This function returns a runspace pool, a collection of runspaces that PowerShell pipelines can be executed.
The number of available pools determines the maximum number of processes that can be running concurrently.
This enables multithreaded execution of PowerShell code.

.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$pool = New-ValentiaRunspacePool 10

--------------------------------------------
Above will creates a pool of 10 runspaces

#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "Defines the maximum number of pipelines that can be concurrently (asynchronously) executed on the pool.")]
        [int]
        $PoolSize
    )

    try
    {
        $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # RunspaceFactory.CreateRunspacePool (Int32, Int32, InitialSessionState, PSHost)
        #   - Creates a runspace pool that specifies minimum and maximum number of opened runspaces, 
        #     and a custom host and initial session state information that is used by each runspace in the pool.
        $pool = [runspacefactory]::CreateRunspacePool(10, $PoolSize,  $sessionstate, $Host)	
    
        # Only support STA mode. No MTA mode.
        $pool.ApartmentState = "STA"
    
        # open RunSpacePool
        $pool.Open()
    
        return $pool
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        Write-Error $_
    }
}



function Receive-ValentiaAsyncResults{
<#
.SYNOPSIS 
Receives a results of one or more asynchronous pipelines.

.DESCRIPTION
This function receives the results of a pipeline running in a separate runspace.  
Since it is unknown what exists in the results stream of the pipeline, this function will not have a standard return type.
 
.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncResults -Pipelines $AsyncPipelines -ShowProgress

--------------------------------------------
Above will retrieve Async Result
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [AsyncPipeline[]]
        $Pipelines,

		[Parameter(
            Position=1,
            Mandatory = 0,
            HelpMessage = "An optional switch to display a progress indicator.")]
        [Switch]
        $ShowProgress,

		[Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Hide execution progress.")]
        [Switch]
        $quiet
    )
	
    # Initialising for Write-Progress
    $i = 1 
	
    foreach($Pipeline in $Pipelines)
    {
		try
		{

            # Inherite variable
            [HashTable]$task = @{}

            # Get HostName of Pipeline
            $task.host = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
            if (!$quiet)
            {
                Write-Warning  -Message ("{0} Asynchronous execution done." -f $task.host)
            }

            # output Asyanc result
        	$task.result = $Pipeline.Pipeline.EndInvoke($Pipeline.AsyncResult)
			
            # Check status of stream
			if($Pipeline.Pipeline.Streams.Error)
			{
                $task.SuccessStatus += $false
                $task.ErrorMessageDetail += $_
				throw $Pipeline.Pipeline.Streams.Error
			}
        }
        catch 
        {
            $task.SuccessStatus += $false
            $task.ErrorMessageDetail += $_
            Write-Error $_
		}
        
        # Dispose Pipeline
        $Pipeline.Pipeline.Dispose()
		
        # Dispose RunspacePool
        $pool.Close()
        $pool.Dispose()

        # Show Progress bar
		if($ShowProgress)
		{
            if (!$quiet)
            {
			    Write-Progress -Activity 'Receiving AsyncPipeline Results' `
                    -PercentComplete $(($i/$Pipelines.Length) * 100) `
				    -Status "Percent Complete"
            }
		}
		
        # Incrementing for Write-Progress
        $i++

        # Output $task variable to file. This will obtain by other cmdlet outside function.
        $task
    }

}



function Receive-ValentiaAsyncStatus{

<#
.SYNOPSIS 
Receives one or more Asynchronous pipeline State.

.DESCRIPTION
Asynchronous execution required to check status whether it done or not.
  
.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $pool -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines

--------------------------------------------
Above will retrieve Async Result
#>

    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Position=0,
            Mandatory,
            HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [AsyncPipeline[]]
        $Pipelines
    )
    
    foreach($Pipeline in $Pipelines)
    {
	   [PSCustomObject]@{
            HostName = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
	   		InstanceID = $Pipeline.Pipeline.Instance_Id
	   		State = $Pipeline.Pipeline.InvocationStateInfo.State
			Reason = $Pipeline.Pipeline.InvocationStateInfo.Reason
			Completed = $Pipeline.AsyncResult.IsCompleted
			AsyncState = $Pipeline.AsyncResult.AsyncState			
			Error = $Pipeline.Pipeline.Streams.Error
       }
	} 
}






#-- Public Module Functions for Upload/Sync Files --#


# upload
function Invoke-ValentiaUpload{

<#
.SYNOPSIS 
Use BITS Transfer to upload a file to remote server.

.DESCRIPTION
This function supports multiple file transfer, if you want to fix file in list then use uploadList function.
  
.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
upload -SourcePath C:\hogehoge.txt -DestinationPath c:\ -DeployGroup production-first.ps1 -File
--------------------------------------------
upload file to destination for hosts written in production-first.ps1

.EXAMPLE
upload -SourcePath C:\deployment\Upload -DestinationPath c:\ -DeployGroup production-first.ps1 -Directory
--------------------------------------------
upload folder to destination for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload folder as Background Async job for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory 192.168.0.10 -Async
--------------------------------------------
upload file to Directory as Background Async job for host ip 192.168.0.10

.EXAMPLE
upload C:\hogehoge* c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload files in target to Directory as Background Async job for hosts written in production-first.ps1

#>

    [CmdletBinding(DefaultParameterSetName = "File")]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Deploy Server SourcePath to be uploaded.")]
        [string]
        $SourcePath, 

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [String]
        $DestinationPath = $null,

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            position = 3,
            Mandatory = 0,
            ParameterSetName = "File",
            HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]
        $File = $null,

        [Parameter(
            position = 3,
            Mandatory = 0,
            ParameterSetName = "Directory",
            HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]
        $Directory,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]
        $Async = $false,

        [Parameter(
            Position = 5,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup)
    )

    try
    {

    ### Begin

    
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


        # Import Bits Transfer Module
        try
        {
            Write-Verbose "Importing BitsTransfer Module to ready File Transfer."
            Import-Module BitsTransfer
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }
        

        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }


        # Obtain DeployMember IP or Hosts for BITsTransfer
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        


        # Parse Network Destination Path
        Write-Verbose ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder)
        $DestinationPath = "$DestinationPath".Replace(":","$")

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process


        Write-Verbose ("Uploading {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers)

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers)
        {
            
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")


            if ($Directory)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-ChildItem -Path $SourcePath -ErrorAction Stop
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            elseif ($File)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-Item -Path $SourcePath -ErrorAction Stop
                    
                    if ($SourceFiles.Attributes -eq "Directory")
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += "Target is Directory, you must set Filename with -File Switch."
                        throw "Target is Directory, you must set Filename with -File Switch."
                    }
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            else
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += $_
                throw "Missing File or Directory switch. Please set -File or -Directory Switch to specify download type."
            }


            # Show Start-BitsTransfer Parameter
            Write-Verbose ("Uploading {0} to {1}." -f $SourceFile, $Destination)
            Write-Verbose ("SourcePath : {0}" -f $SourcePath)
            Write-Verbose ("DeployMember : {0}" -f $DeployMembers)
            Write-Verbose ("DestinationDeployFolder : {0}" -f $DeployFolder)
            Write-Verbose ("DestinationPath : {0}" -f $Destination)
            Write-Verbose ("Aync Mode : {0}" -f $Async)


            if (Test-Path $SourcePath)
            {
                try
                {
                    switch ($true)
                    {
                        # Async Transfer
                        $Async {
                    
                            Write-Verbose 'Command : Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload -ErrorAction Stop'
                            $ScriptToRun = "Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload -ErrorAction Stop"

                            try
                            {
                                foreach ($SourceFile in $SourceFiles)
                                {
                                    try
                                    {
                                        # Run Job
                                        Write-Warning ("Running Async Job upload to {0}" -f $DeployMember)
                                        $Job = Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload -ErrorAction Stop

                                        # Waiting for complete job
                                        $Sleepms = 10

                                        Write-Warning ("Current States was {0}" -f $Job.JobState)
                                    }
                                    catch
                                    {
                                        $SuccessStatus += $false
                                        $ErrorMessageDetail += $_

                                        # Show Error Message
                                        throw $_
                                    }

                                }

                                $Sleepms = 10
                                # Retrieving transfer status and monitor for transffered
                                while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                { 
                                    Write-Warning ("Current Job States was {0}, waiting for {1} ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)))
                                    Sleep -Milliseconds $Sleepms
                                }

                                # Retrieve all files when completed
                                Get-BitsTransfer | Complete-BitsTransfer

                            }
                            catch
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                                $DurationTotal += $Duration
                            }

                        }
                        # NOT Async Transfer
                        default {
                            Write-Verbose 'Command : Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType -ErrorAction Stop' 
                            $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType -ErrorAction Stop"

                            try
                            {
                                foreach($SourceFile in $SourceFiles)
                                {
                                    #Only start upload for file.
                                    if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                    {
                                        Write-Warning ("Uploading {0} to {1}'s {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                        Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -ErrorAction Stop
                                    }
                                }
                            }
                            catch [System.Management.Automation.ActionPreferenceStopException]
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                            }
                        }
                    }
                }
                catch
                {

                    # Show Error Message
                    Write-Error $_

                    # Set ErrorResult
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_

                }
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    ### End


    Write-Verbose "All transfer with BitsTransfer had been removed."


    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        throw $_

    }
    finally
    {

        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default


        # Get End Time
        $TimeEnd = (Get-Date).DateTime


        # obtain Result
        $CommandResult = [PSCustomObject]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048


        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }
}



# uploadL
function Invoke-ValentiaUploadList{

<#
.SYNOPSIS 
Use BITS Transfer to upload list files to remote server.

.DESCRIPTION
This function only support files listed in csv sat in upload context.
Make sure destination path format is not "c:\" but use "c$\" as UNC path.

.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013


.EXAMPLE
uploadList -ListFile list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt


.EXAMPLE
uploadList list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1. You can omit -listFile parameter.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0, 
            Mandatory,
            HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [string]
        $ListFile,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]
        $Async = $false
    )

    try
    {
       
    ### Begin
            

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


        # Import Bits Transfer Module
        try
        {
            Write-Verbose "Importing BitsTransfer Module to ready File Transfer."
            Import-Module BitsTransfer
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }


        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }


        # Obtain DeployMember IP or Hosts for BITsTransfer
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        



        # Set SourcePath to retrieve target File full path (default Upload folder of deployment)
        $SourceFolder = Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.Upload

        if (-not(Test-Path $SourceFolder))
        {
            Write-Verbose ("SourceFolder not found creating {0}" -f $SourceFolder)
            New-Item -Path $SourceFolder -ItemType Directory            
        }

        try
        {
            Write-Verbose "Defining ListFile full path."
            $SourcePath = Join-Path $SourceFolder $ListFile
            Get-Item $SourcePath -ErrorAction Stop > $null
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }


        # Obtain List of File upload
        Write-Verbose ("Retrive souce file list from {0} `n" -f $SourcePath)
        $List = Import-Csv $SourcePath -Delimiter "," 

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process


        Write-Verbose (" Uploading Files written in {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers)

        # Stopwatch
        [decimal]$DurationTotal = 0

        Write-Verbose ("Starting Upload {0} ." -f $List.Source)
        foreach ($DeployMember in $DeployMembers){

            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
            #Create New List
            $NewList = $List | %{
                [PSCustomObject]@{
                    Source = $_.source
                    Destination = "\\" + $DeployMember + "\" + $($_.destination)
                }
            }
            
            try
            {
                # Run Start-BitsTransfer
                Write-Verbose ("Uploading {0} to {1} ." -f $NewList.Source, $NewList.Destination)
                Write-Verbose ("ListFile : {0}" -f $SourcePath)
                Write-Verbose ("SourcePath : {0}" -f $NewList.Source)
                Write-Verbose ("DestinationPath : {0}" -f $List.Destination)
                Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                Write-Verbose ("Aysnc : {0}" -f $Async)

                if ($Async)
                {
                    #Command Detail
                    Write-Verbose 'Command : $NewList | Start-BitsTransfer -Credential $Credebtial -Async -ErrorAction stop'
                    $ScriptToRun = '$NewList | Start-BitsTransfer -Credential $Credential -Async -ErrorAction stop'

                    # Run Start-BitsTransfer retrieving files from List csv with Async switch
                    Write-Warning ("Running Async uploadL to {0}" -f $DeployMember)
                    $BitsJob = $NewList | Start-BitsTransfer -Credential $Credential -Async -ErrorAction stop

                    # Monitoring Bits Transfer States complete
                    $Sleepms = 10
                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                    {
                        Write-Warning ("Current Job States was {0}, waiting for {1} ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)))
                        sleep -Milliseconds $Sleepms
                    }

                    # Send Complete message to make file from ****.Tmp
                    Write-Warning ("Completing Async uploadL to {0}" -f $DeployMember)
                    # Retrieve all files when completed
                    Get-BitsTransfer | Complete-BitsTransfer

                }
                else
                {
                    #Command Detail
                    Write-Verbose 'Command : $NewList | Start-BitsTransfer -Credential $Credebtial -ErrorAction stop'
                    $ScriptToRun = "$NewList | Start-BitsTransfer -Credential $Credential  -ErrorAction stop"

                    # Run Start-BitsTransfer retrieving files from List csv
                    Write-Warning ("Running Sync uploadL to {0}" -f $DeployMember)
                    $NewList | Start-BitsTransfer -Credential $Credential -ErrorAction stop
                }
            }
            catch
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += $_

                # Show Error Message
                throw $_
            }
            finally
            {
                # Delete all not compelte job
                Get-BitsTransfer | Remove-BitsTransfer

                # Stopwatch
                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                Write-Verbose ("Session duration Second : {0}" -f $Duration)

                # Add current session to Total
                $DurationTotal += $Duration
                ""
            }
        }


    ### End


        Write-Verbose "All transfer with BitsTransfer had been removed."

    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        $_
    }
    finally
    {

        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default


        # Get End Time
        $TimeEnd = (Get-Date).DateTime


        # obtain Result
        $CommandResult = [PSCustomObject]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048


        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }
}


# Sync
function Invoke-ValentiaSync{

<#
.SYNOPSIS 
Use fastcopy.exe to Sync Folder for Diff folder/files not consider Diff from remote server.

.DESCRIPTION
You must install fastcopy.exe to use this function.

.NOTES
Author: Ikiru Yoshizaki
Created: 13/July/2013

.EXAMPLE
Sync -Source sourcepath -Destination desitinationSharePath -DeployGroup DeployGroup.ps1
--------------------------------------------
Sync sourthpath and destinationsharepath directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync c:\deployment\upload c:\deployment\upload 192.168.1.100
--------------------------------------------
Sync c:\deployment\upload directory and remote server listed in new.ps1 c:\deployment\upload directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync -Source c:\upload.txt -Destination c:\share\ -DeployGroup 192.168.1.100,192.168.1.102
--------------------------------------------
Sync c:\upload.txt file and c:\share directory in Diff mode. (Will not delete items but only update to add new)
#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Deploy Server Source Folder Sync to Client PC.")]
        [string]
        $SourceFolder, 

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Client Destination Folder Sync with Desploy Server.")]
        [String]
        $DestinationFolder,

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

        [Parameter(
            Mandatory = 0,
            HelpMessage = "Input fastCopy.exe location folder if changed.")]
        [string]
        $FastCopyFolder = $valentia.fastcopy.folder,
        
        [Parameter(
            Mandatory = 0,
            HelpMessage = "Input fastCopy.exe name if changed.")]
        [string]
        $FastcopyExe =  $valentia.fastcopy.exe
    )

    try
    {


    ### Begin


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


        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }

    
        # Check FastCopy.exe path
        Write-Verbose "Checking FastCopy Folder is exist or not."
        if (-not(Test-Path $FastCopyFolder))
        {
            New-Item -Path $FastCopyFolder -ItemType Directory
        }

        # Set FastCopy.exe path
        try
        {
            Write-Verbose "Set FastCopy.exe path."
            $FastCopy = Join-Path $FastCopyFolder $FastcopyExe
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += "$FastCopyFolder or $FastcopyExe not found exceptions! Please set $FastCopy under $FastCopyFolder "
            throw "{0} or {1} not found exceptions! Please set {2} under {3}" -f $FastCopyFolder, $FastcopyExe, $FastCopy, $FastCopyFolder
        }


        # Check SourceFolder Exist or not
        if (-not(Test-Path $SourceFolder))
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += "SourceFolder [ $SourceFolder ] not found exeptions! exit job."
            throw "SourceFolder [ {0} ] not found exeptions! exit job." -f $SourceFolder
        }
                

        # Obtain DeployMember IP or Hosts for FastCopy
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose ("Connecting to Target Computer : [{0}] `n" -f $DeployMembers)
        

        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        


        # Parse Network Destination Path
        Write-Verbose ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder)
        $DestinationPath = "$DestinationFolder".Replace(":","$")


        # Safety exit for root drive
        if ($SourceFolder.Length -ge 3)
        {
            Write-Verbose ("SourceFolder[-2]`t:`t$($SourceFolder[-2])")
            Write-Verbose ("SourceFolder[-1]`t:`t$($SourceFolder[-1])")
            if (($SourceFolder[-2] + $SourceFolder[-1]) -in (":\",":/"))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)

                throw ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)
            }
        }


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process


        Write-Verbose (" Syncing {0} to Target Computer : [{1}] {2} `n" -f $SourceFolder, $DeployMembers, $DestinationFolder)

        # Create PSSession  for each DeployMember
        Write-Warning "Starting Sync Below files"
        (Get-ChildItem $SourceFolder).FullName

        # Stopwatch
        [decimal]$DurationTotal = 0

        foreach ($DeployMember in $DeployMembers){
            
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

            # Create Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")

            # Set FastCopy.exe Argument for Sync
            $FastCopyArgument = "/cmd=sync /bufsize=512 /speed=full /wipe_del=FALSE /acl /stream /reparse /force_close /estimate /error_stop=FALSE /log=True /logfile=""$LogPath"" ""$SourceFolder"" /to=""$Destination"""

            # Run FastCopy
            Write-Verbose ("Uploading {0} to {1}." -f $SourceFolder, $Destination)
            Write-Verbose ("SourceFolder : {0}" -f $SourceFolder)
            Write-Verbose ("DeployMember : {0}" -f $DeployMember)
            Write-Verbose ("DestinationPath : {0}" -f $Destination)
            Write-Verbose ("FastCopy : {0}" -f $FastCopy)
            Write-Verbose ("FastCopyArgument : {0}" -f $FastCopyArgument)

            
            if(Test-Connection $DeployMember -Count 1 -Quiet)
            {
                try
                {
                    Write-Warning ("running command to DeployMember: {0}" -f $DeployMember)
                    Write-Verbose 'Command : Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -ErrorAction Stop -PassThru -Credential $Credential'
                    $Result = Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -ErrorAction Stop -PassThru -Credential $Credential
                }
                catch
                {
                    Write-Error $_

                    # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_ 

                }
            }
            else
            {
                    Write-Error ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)

                    # Set ErrorResult as CurrentContext with taskkey KV. This will allow you to check variables through functions.
                    $SuccessStatus += $false
                    $ErrorMessageDetail += ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)
            }


            # Stopwatch
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            Write-Verbose ("Session duration Second : {0}" -f $Duration)
            ""
            $DurationTotal += $Duration

        }


    ### End

   
        Write-Verbose "All Sync job complete."
        if (Test-Path $LogPath)
        {
            if (-not((Select-String -Path $LogPath -Pattern "No Errors").count -ge $DeployMembers.count))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
                Write-Error ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
            }
        }
        else
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
            Write-Error ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
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

        # Show Stopwatch for Total section
        $TotalDuration += $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)


        # Get End Time
        $TimeEnd = (Get-Date).DateTime


        # obtain Result
        $CommandResult = [PSCustomObject]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            Result = $result
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048 -Append

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}




#-- Public Module Functions for Download/Sync Files --#



# download
function Invoke-ValentiaDownload{

<#
.SYNOPSIS 
Use BITS Transfer to downlpad a file from remote server.
If -Force switch enable, then use smbmapping and copy -force will run.

.DESCRIPTION
If target path was directory then download files below path. (None recurse)
If target path was file then download specific file.

.NOTES
Author: Ikiru Yoshizaki
Created: 14/Aug/2013

.EXAMPLE
download -SourcePath c:\logs\white\20130719 -DestinationFolder c:\logs\white -DeployGroup production-g1.ps1 -Directory -Async
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job.

.EXAMPLE
download -SourcePath c:\logs\white\20130716\Http.0001.log -DestinationFolder c:\test -DeployGroup.ps1 production-first -File
--------------------------------------------
download remote sourth item to local destinationfolder

.EXAMPLE
download -SourcePath c:\logs\white\20130716 -DestinationFolder c:\test -DeployGroup production-first.ps1 -Directory
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job. Omit parameter name.

#>

    [CmdletBinding(DefaultParameterSetName = "File")]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input Client SourcePath to be downloaded.")]
        [String]
        $SourcePath,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input Server Destination Folder to save download items.")]
        [string]
        $DestinationFolder = $null, 

        [Parameter(
            Position = 2,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]
        $DeployGroups,

        [Parameter(
            position = 3,
            ParameterSetName = "File",
            HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]
        $File = $true,

        [Parameter(
            position = 3,
            ParameterSetName = "Directory",
            HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]
        $Directory,

        [Parameter(
            position = 4,
            Mandatory = 0,
            HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]
        $Async = $false,

        [Parameter(
            Position = 5,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup),

        [Parameter(
            Position = 6,
            Mandatory = 0,
            HelpMessage = "Set this switch if you want to Force download. This will smbmap with source folder and Copy-Item -Force. (default is BitTransfer)")]
        [switch]
        $force = $false
    )

    try
    {


    ### Begin

    
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


        # Import Bits Transfer Module
        try
        {
            Write-Verbose "Importing BitsTransfer Module to ready File Transfer."
            Import-Module BitsTransfer
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }
        

        # Obtain Remote Login Credential
        try
        {
            $Credential = Get-ValentiaCredential
            $SuccessStatus += $true
        }
        catch
        {
            Write-Error $_
            $SuccessStatus += $false
        }


        # Obtain DeployMember IP or Hosts for BITsTransfer
        $DeployMembers = Get-ValentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        Write-Verbose (" Connecting to Target Computer : [{0}] `n" -f $DeployMembers)
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        


        # Parse Network Source
        Write-Verbose ("Parsing Network SourcePath {0} as :\ should change to $." -f $SourcrePath)
        $SourcePath = "$SourcePath".Replace(":","$")


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process


        Write-Verbose ("Downloading {0} from Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers)

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers){
            
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Source 
            $Source = Join-Path "\\" $(Join-Path "$DeployMember" "$SourcePath")

            if (Test-Path $Source)
            {

                if ($Directory)
                {
                    # Set Source files in source
                    try
                    {
                        # Remove last letter of \ or /
                        if (($Source[-1] -eq "\") -or ($Source[-1] -eq "/"))
                        {
                            $Source = $Source.Substring(0,($Source.Length-1))
                        }

                        # Get File Information - No recurse
                        $SourceFiles = Get-ChildItem -Path $Source -ErrorAction Stop
                    }
                    catch
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_
                        throw $_
                    }
                }
                elseif ($File)
                {
                    # Set Source files in source
                    try
                    {
                        # Get File Information
                        $SourceFiles = Get-Item -Path $Source -ErrorAction Stop
                    
                        if ($SourceFiles.Attributes -eq "Directory")
                        {
                            $SuccessStatus += $false
                            $ErrorMessageDetail += "Target is Directory, you must set Filename with -File Switch."
                            throw "Target is Directory, you must set Filename with -File Switch."
                        }
                    }
                    catch
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_
                        throw $_
                    }
                }
                else
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw "Missing File or Directory switch. Please set -File or -Directory Switch to specify download type."
                }


                # Set Destination with date and DeproyMemberName
                if ($DestinationFolder -eq $null)
                {
                    $DestinationFolder = $(Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.Download)
                }

                $Date = (Get-Date).ToString("yyyyMMdd")
                $DestinationPath = Join-Path $DestinationFolder $Date
                $Destination = Join-Path $DestinationPath $DeployMember

                # Create Destination if not exist
                if (-not(Test-Path $Destination))
                {
                    New-Item -Path $Destination -ItemType Directory -Force > $null
                }

                if ($force)
                {
                    # Show Start-BitsTransfer Parameter
                    Write-Verbose ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember)
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose "Aync Mode : You cannot use Async switch with force"

                    # Get Cimsession for target Computer
                    Write-Verbose 'cim : New-CimSession -Credential $Credential -ComputerName $DeployMember'
                    $cim = New-CimSession -Credential $Credential -ComputerName $DeployMember
                        
                    # Create SMB Mapping to target parent directory
                    if ($Directory)
                    {
                        Write-Verbose "Directory switch Selected"
                        $smbRemotePath = (Get-Item $Source).FullName
                    }
                    elseif ($file)
                    {
                        Write-Verbose "File switch Selected"
                        $smbRemotePath = (Get-Item $source).DirectoryName
                    }

                    Write-Verbose 'smb : New-SmbMapping -LocalPath $valentia.PSDrive -RemotePath ($smbRemotePath) -CimSession $cim'
                    $smb = New-SmbMapping -LocalPath $valentia.PSDrive -RemotePath $smbRemotePath -CimSession $cim

                    # Check cim and smb variables
                    Write-Verbose ("cim : {0}" -f $cim)
                    Write-Verbose ("smb : {0}" -f $smb)

                    # Running Copy-Item cmdlet, switch with $force
                    try
                    {                     
                        #Only start download for file.
                        foreach($SourceFile in $SourceFiles)
                        {
                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                            {
                                Write-Verbose 'Command : Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force -ErrorAction Stop'
                                $ScriptToRun = "Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force -ErrorAction Stop"

                                Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force -ErrorAction Stop
                            }
                        }
                    }
                    catch [System.Management.Automation.ActionPreferenceStopException]
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_

                        # Show Error Message
                        throw $_
                    }
                    finally
                    {
                        # Remove All SMB Mapping
                        Get-SmbMapping $smb -CimSession $cim | Remove-SmbMapping -Force -CimSession $cim
                        Get-CimSession | Remove-CimSession
                        # Stopwatch
                        $Duration = $stopwatchSession.Elapsed.TotalSeconds
                        Write-Verbose ("Session duration Second : {0}" -f $Duration)
                        ""
                    }
                }
                else # Not Force Swtich
                {

                    # Show Start-BitsTransfer Parameter
                    Write-Verbose ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember)
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose ("Aync Mode : {0}" -f $Async)


                    # Running Bits Transfer, switch with $Async and no $Async
                    try
                    {
                        switch ($true)
                        {
                            # Async Transfer
                            $Async {
                    
                                Write-Verbose 'Command : Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download -ErrorAction Stop'
                                $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download -ErrorAction Stop"

                                try
                                {
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        try
                                        {
                                            #Only start download for file.
                                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                            {
                                                # Run Job
                                                Write-Warning ("Async Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                                $Job = Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download -ErrorAction Stop
                                        
                                                # Waiting for complete job
                                                $Sleepms = 10

                                                Write-Warning ("Current States was {0}" -f $Job.JobState)
                                            }
                                        }
                                        catch
                                        {
                                            $SuccessStatus += $false
                                            $ErrorMessageDetail += $_

                                            # Show Error Message
                                            throw $_
                                        }
                                    }

                                    # Retrieving transfer status and monitor for transffered
                                    $Sleepms = 10
                                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                    { 
                                        Write-Warning ("Current Job States was {0}, waiting for {1} ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)))
                                        Sleep -Milliseconds $Sleepms
                                    }

                                    # Retrieve all files when completed
                                    Get-BitsTransfer | Complete-BitsTransfer

                                }
                                catch
                                {
                                    $SuccessStatus += $false
                                    $ErrorMessageDetail += $_

                                    # Show Error Message
                                    throw $_
                                }
                                finally
                                {

                                    # Delete all not compelte job
                                    Get-BitsTransfer | Remove-BitsTransfer

                                    # Stopwatch
                                    $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                    Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                    ""
                                    $DurationTotal += $Duration
                                }

                            }
                            default {
                                # NOT Async Transfer
                                Write-Verbose 'Command : Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType Download -ErrorAction Stop' 
                                $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType Download -ErrorAction Stop"

                                # Run Download
                                try
                                {
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        #Only start download for file.
                                        if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                        {
                                            Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                            Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -TransferType Download -ErrorAction Stop
                                        }
                                    }
                                }
                                catch [System.Management.Automation.ActionPreferenceStopException]
                                {
                                    $SuccessStatus += $false
                                    $ErrorMessageDetail += $_

                                    # Show Error Message
                                    throw $_
                                }
                                finally
                                {
                                    # Delete all not compelte job
                                    Get-BitsTransfer | Remove-BitsTransfer

                                    # Stopwatch
                                    $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                    Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                    ""
                                }
                            }
                        }
                    }
                    catch
                    {

                        # Show Error Message
                        Write-Error $_

                        # Set ErrorResult
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_

                    }
                }
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    
    ### End

        Write-Verbose "All transfer with BitsTransfer had been removed."

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        throw $_

    }
    finally
    {

        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default


        # Get End Time
        $TimeEnd = (Get-Date).DateTime


        # obtain Result
        $CommandResult = [PSCustomObject]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $CommandResult

        # output result
        $CommandResult | ConvertTo-Json | Out-File -FilePath $LogPath -Encoding utf8 -Force -Width 1048

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }

}





#-- Helper for valentia --#


# clean
function Invoke-ValentiaClean{

<#
.SYNOPSIS 
Clean up valentia task variables.

.DESCRIPTION
Clear valentia variables for each task, and remove then.
valentia only keep default variables after this cmdlet has been run.

.NOTES
Author: Ikiru Yoshizaki
Created: 13/Jul/2013

.EXAMPLE
Invoke-ValentiaClean
--------------------------------------------
Clean up valentia variables stacked in the $valentia variables.

#>

    [CmdletBinding()]
    param(
    )

    if ($valentia.context.Count -gt 0) 
    {
        $currentContext = $valentia.context.Peek()
        $env:path = $currentContext.originalEnvPath
        Set-Location $currentContext.originalDirectory
        $global:ErrorActionPreference = $currentContext.originalErrorActionPreference

        # Erase Context
        [void] $valentia.context.Clear()
    }

}


# go
function Set-ValentiaLocation{

<#
.SYNOPSIS 
Move location to valentia folder

.DESCRIPTION
You can specify branch path in configuration.
If you changed from default, then change validation set for BranchPath for intellisence.

.NOTES
Author: Ikiru Yoshizaki
Created: 13/Jul/2013

.EXAMPLE
go -BrachPath BranchPathName
--------------------------------------------
Move location to valentia root path

.EXAMPLE
go
--------------------------------------------
just move to root path

.EXAMPLE
go application
--------------------------------------------
change location to BranchPath c:\deployment\application (in default)

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Select branch deploy folder to change directory.")]
        [validateSet(
            "Application",
            "Bin",
            "DeployGroup",
            "Download",
            "Maintenance",
            "Upload",
            "Utils"
        )]
        [string]
        $BranchPath
    )

    $prevLocation = (Get-Location).Path

    # replace \ to \\ for regexpression
    $valentiaroot = $valentia.RootPath -replace "\\","\\"

    # Create target path
    $newlocation = (Join-Path $valentia.RootPath $valentia.BranchFolder.$BranchPath)

    # Move to BrachPath if exist
    Write-Verbose ("{0} : {1}" -f $BranchPath, $newlocation)
    if (Test-Path $newlocation)
    {
        switch ($BranchPath) {
            $valentia.BranchFolder.$BranchPath {Set-Location $newlocation}
            default {}
        }
    }
    else
    {
        throw "{0} not found exception! Make sure {1} is exist." -f $newlocation, $newlocation
    }

    # Show current Loacation
    Write-Verbose ("(Get-Location).Path : {0}" -f (Get-Location).Path)
    Write-Verbose ("prevLocation : {0}" -f $prevLocation)
    if ((Get-Location).Path -eq $prevLocation)
    {
        Write-Warning "Location not changed."
    }
    else
    {
        Write-Verbose ("Location change to {0}" -f (Get-Location).Path)
    }
}


#-- Log Settings -- #


function New-ValentiaLog{

<#

.SYNOPSIS 
Setup Valentia Log Folder

.DESCRIPTION
Check Valentia Log folder and return log full path

.NOTES
Author: guitarrapc
Created: 18/Sep/2013

.EXAMPLE
New-ValentiaLog -LogFolder c:\logs\deployment -LogFile "hoge.log"
--------------------------------------------
This is format sample.

.EXAMPLE
New-ValentiaLog
--------------------------------------------
As New-ValentiaLog have default value in parameter, you do not required to specify log information

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0, 
            Mandatory = 0,
            HelpMessage = "Path to LogFolder.")]
        [string]
        $LogFolder = $(Join-Path $valentia.Log.path (Get-Date).ToString("yyyyMMdd")),

        [Parameter(
            Position = 1, 
            Mandatory = 0,
            HelpMessage = "Name of LogFile.")]
        [string]
        $LogFile = "$($valentia.Log.name)_$((Get-Date).ToString("yyyyMMdd_HHmmss"))$($valentia.Log.extension)"
    )


    if (-not(Test-Path $LogFolder))
    {
        Write-Verbose ("LogFolder not found creating {0}" -f $LogFolder)
        New-Item -Path $LogFolder -ItemType Directory > $null
    }

    try
    {
        Write-Verbose "Defining LogFile full path."
        $LogPath = Join-Path $LogFolder $LogFile
        return $LogPath
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        $ErrorCmdletName += ($MyInvocation.MyCommand).Name
        throw $_
    }

}


#-- PSRemoting Connect Credential Module Functions --#


function New-ValentiaCredential{

<#

.SYNOPSIS 
Create Remote Login Credential for valentia

.DESCRIPTION
Log-in credential will preserve for this machine only. You could not copy and reuse.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-ValentiaCredential
--------------------------------------------
This will create credential with default deploy user specified config as $valentia.users.DeployUser

.EXAMPLE
New-ValentiaCredential -User hogehoge
--------------------------------------------
You can specify other user credential if required.

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Enter user and Password.")]
        [string]
        $BinFolder = (Join-Path $Script:valentia.RootPath $($valentia.BranchFolder).Bin),

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Enter Secure string output path.")]
        [string]
        $User = $valentia.users.DeployUser
    )


    $cred = Get-Credential -UserName $User -Message ("Input {0} Password to be save." -f $User)


    if ($User -eq "")
    {
        $User = $cred.UserName
    }
        
    if (-not([string]::IsNullOrEmpty($cred.Password)))
    {

        try
        {
            # Set Credential save path        
            $currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $replaceuser = $currentuser.Replace("\","_")
            $CredFolder = Join-Path $BinFolder $replaceuser

            # check credentail save path exist or not
            if (-not(Test-Path $CredFolder))
            {
                New-Item -ItemType Directory -Path $BinFolder -Name $replaceuser -Force -ErrorAction Stop
            }

            # Set CredPath with current Username
            $CredPath = Join-Path $CredFolder "$User.pass"
        }
        catch
        {
            throw $_
        }

        # get SecureString
        try
        {
            $savePass = $cred.Password | ConvertFrom-SecureString
        }
        catch
        {
            throw 'Credential input was empty!! "None pass" is not allowed.'
        }

        
        
        if (Test-Path $CredPath)
        {
            Write-Verbose ("Remove existing Credential Password for {0} found in {1}" -f $User, $CredPath)
            Remove-Item -Path $CredPath -Force -Confirm
        }


        Write-Verbose ("Save Credential Password for {0} set in {1}" -f $User, $CredPath)
        $savePass | Set-Content -Path $CredPath -Force


        Write-Verbose ("Completed: Credential Password for {0} had been sat in {1}" -f $User, $CredPath)
    }
    else
    {
        throw 'Credential input had been aborted or empty!! "None pass" is not allowed and make sure input "UserName" and "Password" to be use for valentia!'
    }

    # Cleanup valentia Environment
    Invoke-ValentiaClean
}


# cred
function Get-ValentiaCredential{

<#

.SYNOPSIS 
Get Secure String of Deployment User / Password

.DESCRIPTION
Decript password file and set as PSCredential.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Get-ValentiaCredential
--------------------------------------------
This will get credential with default deploy user specified config as $valentia.users.DeployUser. Make sure credential was already created by New-ValentiaCredential.

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Enter user and Password.")]
        [string]
        $User = $valentia.users.DeployUser,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Enter Secure string saved path.")]
        [string]
        $BinFolder = (Join-Path $Script:valentia.RootPath $($valentia.BranchFolder).Bin)
    )

    begin
    {
        if([string]::IsNullOrEmpty($User))
        {
            throw '"$User" was "", input User.'
        }
    }

    process
    {

        # Set Credential save path        
        $currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $replaceuser = $currentuser.Replace("\","_")
        $credFolder = Join-Path $BinFolder $replaceuser

        # check credential save path exist or not
        if (-not(Test-Path $credFolder))
        {
            New-Item -ItemType Directory -Path $BinFolder -Name $replaceuser -Force -ErrorAction Stop
        }

        # Set CredPath with current Username
        $credPath = Join-Path $credFolder "$User.pass"

        if (Test-Path $CredPath)
        {
            $credPassword = Get-Content -Path $credPath | ConvertTo-SecureString

            Write-Verbose ("Obtain credential for User [ {0} ] from {1} " -f $User, $credPath)
            $credential = New-Object System.Management.Automation.PSCredential $User,$credPassword                
        }
    }
    
    end
    {
        $credential
    }
}


#-- Deploy Folder/File Module Functions --#


function New-ValentiaGroup{

<#

.SYNOPSIS 
Create new DeployGroup File written "target PC IP/hostname" for PS-RemoteSession

.DESCRIPTION
This cmdlet will create valentis deploy group file to specify deploy targets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaGroup -DeployClients "10.0.4.100","10.0.4.101" -FileName new.ps1
--------------------------------------------
write 10.0.4.100 and 10.0.4.101 to create deploy group file as "new.ps1".

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Specify IpAddress or NetBIOS name for deploy target clients.")]
        [string[]]
        $DeployClients,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input filename to output DeployClients")]
        [string]
        $FileName,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Specify folder path to deploy group. defailt is Deploygroup branchpath")]
        [string]
        $DeployGroupsFolder = (Join-Path $Script:valentia.RootPath $($valentia.BranchFolder).Deploygroup),

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "If you want to popup confirm message when file created.")]
        [switch]
        $Confirm,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "If you want to confiem what will happen.")]
        [switch]
        $WhatIf

    )


    begin
    {       
        function Get-WhatifConfirm{
            if($WhatIf)
            {
                $DeployClients | Set-Content -Path $DeployPath -Encoding utf8 -Whatif -Confirm
            }
            else
            {
                $DeployClients | Set-Content -Path $DeployPath -Encoding utf8 -Confirm
            }
        }

        function Get-Whatif{
            if($WhatIf)
            {
                $DeployClients | Set-Content -Path $DeployPath -Encoding utf8 -Whatif
            }
            else
            {
                $DeployClients | Set-Content -Path $DeployPath -Encoding utf8
            }
        }

        # check FileName is null or empty
        try
        {
            if ([string]::IsNullOrEmpty($FileName))
            {
                throw '"$FileName" was Null or Enpty, input DeployGroup FileName.'
            }
            else
            {
                $DeployPath = Join-Path $DeployGroupsFolder $FileName -Resolve -ErrorAction Stop
            }
        }
        catch
        {
            throw $_
        }
    }

    process
    {
        if($Confirm)
        {
            Get-WhatifConfirm
        }
        else
        {
            Get-Whatif
        }

    }

    end
    {
        if (Test-Path $DeployPath)
        {
            Get-ChildItem -Path $DeployPath
        }
        else
        {
            Write-Error ("{0} not existing." -f $DeployPath)
        }

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }
}


# target
function Get-ValentiaGroup{

<#

.SYNOPSIS 
Get ipaddress or NetBIOS from DeployGroup File specified

.DESCRIPTION
This cmdlet will read Deploy Group path and set them into array of Deploygroups.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
target production-hoge.ps1
--------------------------------------------
read production-hoge.ps1 from deploy group branch path.

.EXAMPLE
target production-hoge.ps1 c:\test
--------------------------------------------
read production-hoge.ps1 from c:\test.

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]
        $DeployGroups,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup)
    )


    # Get valentiaGroup
    function Resolve-ValentiaGroup{

        param(
            [Parameter(Position = 0,Mandatory)]
            [string]
            $DeployGroup
        )

        if ($DeployGroup.EndsWith($DeployExtension)) # if DeployGroup last letter is same as $DeployExtension
        {
            $DeployFile = $DeployGroup

            Write-Verbose ("Creating Deploy Path with DeployFolder [{0}] and DeployGroup [{1}] ." -f $DeployFolder, $DeployFile)
            $DeployGroupPath = Join-Path $DeployFolder $DeployFile

            Write-Verbose ("Check DeployGroupPath {0}" -f $DeployGroupPath)
            if(Test-Path $DeployGroupPath)
            {
                # Obtain IP only by selecting leter start from decimal
                Write-Verbose ("Read DeployGroupPath {0} where letter not contain # inline." -f $DeployGroupPath)
                Write-Verbose 'code : Select-String -path $DeployGroupPath -Pattern "".*#.*"" -notmatch -Encoding utf8 | Select-String -Pattern ""\w"" -Encoding utf8 | select -ExpandProperty line'
                $Readlines = Select-String -path $DeployGroupPath -Pattern ".*#.*" -notmatch -Encoding utf8 | Select-String -Pattern "\w" -Encoding utf8 | select -ExpandProperty line
                return $Readlines
            }
            else
            {
                $errorDetail = [PSCustomObject]@{
                    ErrorMessageDetail = ("DeployGroup [ {0} ] not found exception!!" -f $DeployGroup)
                    SuccessStatus = $false
                }
            
                Write-Error $errorDetail.ErrorMessageDetail
            }

        }
        elseif (Test-Connection -ComputerName $DeployGroup -Count 1 -Quiet) # if deploygroup not have extension $valentia.deployextension, try test-connection
        {
            return $DeployGroup
        }
        else
        {
            throw ('"$DeployGroups" was null or empty or could not resolve connection. deploygroups : {0}' -f $DeployGroups)
        }
    }
    

    # Initialize DeployMembers variable
    $DeployMembers = @()


    # Get valentia.deployextension information
    Write-Verbose ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension)
    $DeployExtension = $valentia.deployextension
    $extensionlength = $DeployExtension.length


    switch ($DeployGroups.Length)
    {
        0 {throw '"$DeployGroups" was Null or Empty, input DeployGroup.'}
        1 {
            # Parse DeplotGroup from [string[]] to [String]
            [string]$DeployGroup = $DeployGroups

            # Resolve DeployGroup is filename or IPAddress/Hostname and return $DeployMemebers
            $Deploymembers += Resolve-ValentiaGroup -DeployGroup $DeployGroup}

        # more than 2
        default {
            foreach ($DeployGroup in $DeployGroups)
            {
                # Parse DeplotGroup from [string[]] to [String]
                [string]$DeployGroup = $DeployGroup

                # Resolve DeployGroup is filename or IPAddress/Hostname and return $DeployMemebers
                $Deploymembers += Resolve-ValentiaGroup -DeployGroup $DeployGroup
            }
        }
    }

    return $DeployMembers
}



#-- Running prerequisite Initialize OS Setting Module Functions --#


function Test-ValentiaPowerShellElevated{

<#
.SYNOPSIS
    Retrieve elavated status of PowerShell Console.

.DESCRIPTION
    Test-ValentiaPowerShellElevated will check shell was elevated is required for some operations access to system folder, files and objects.
      
.NOTES
    Author: guitarrapc
    Date:   June 17, 2013

.OUTPUTS
    bool

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated

        true

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated

        false
        
#>


    [CmdletBinding()]
    param(
    )

	$user = [Security.Principal.WindowsIdentity]::GetCurrent()
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

}


# Initial
function Initialize-valentiaEnvironment{

<#

.SYNOPSIS 
Initializing valentia PSRemoting environment for Deploy Server and client.

.DESCRIPTION
Run as Admin Priviledge. 

Set-ExecutionPolicy (Default : RemoteSigned)
Enable-PSRemoting
Add hosts to trustedHosts  (Default : *)
Set MaxShellsPerUser from 25 to 100
Add PowerShell Remoting Inbound rule to Firewall (Default : TCP 5985)
Disable Enhanced Security for Internet Explorer (Default : True)
Create OS user for Deploy connection. (Default : ec2-user)
Create Windows PowerShell Module Folder for DeployUser (Default : $home\Documents\WindowsPowerShell\Modules)
Create/Revise Deploy user credential secure file. (Server Only / Default : True)
Create Deploy Folders (Server Only / Default : True)
Set HostName as format (white-$HostUsage-IP)
Get Status for Reboot Status


.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Initialize-valentiaEnvironment -Server
--------------------------------------------
Setup Server Environment

.EXAMPLE
Setup Client Environment
--------------------------------------------
Initialize-valentiaEnvironment -Client

.EXAMPLE
Initialize-valentiaEnvironment -Client -NoOSUser
--------------------------------------------
Setup Client Environment and Skip Deploy OSUser creattion

.EXAMPLE
Setup Server Environment withour OSUser and Credential file revise
--------------------------------------------
read production-hoge.ps1 from c:\test.

#>

    [CmdletBinding(DefaultParameterSetName = "Server")]
    param(
        [parameter(
            HelpMessage = "Select this switch If you don't want to initialize Deploy User.")]
        [switch]
        $NoOSUser = $false,

        [parameter(
            ParameterSetName = "Server",
            HelpMessage = "Select this switch If you don't want to Save/Revise password.")]
        [switch]
        $NoPassSave = $false,

        [parameter(
            ParameterSetName = "Server",
            HelpMessage = "Select this switch to Initialize setup for Deploy Server.")]
        [switch]
        $Server,

        [parameter(
            ParameterSetName = "Client",
            HelpMessage = "Select this switch to Initialize setup for Deploy Client.")]
        [switch]
        $Client,

        [Parameter(
            HelpMessage = "Select this switch If you don't want to Set HostName.")]
        [switch]
        $NoSetHostName = $false,

        [Parameter(
            HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [parameter(
            HelpMessage = "Select this switch If you don't want to REboot.")]
        [switch]
        $NoReboot = $false,

        [parameter(
        HelpMessage = "Select this switch If you want to Forece Restart without prompt.")]
        [switch]
        $ForceReboot = $false,

        [parameter(
            HelpMessage = "Input Trusted Hosts you want to enable. Default : ""*"" ")]
        [string]
        $TrustedHosts = "*",

        [parameter(
        HelpMessage = "Select this switch If you want to skip setup PSRemoting.")]
        [switch]
        $SkipEnablePSRemoting = $false

        )

    begin
    {
        # Check -HostUsage parameter is null or emptry
        if ($NoSetHostName -eq $false)
        {
            if ([string]::IsNullOrEmpty($HostUsage))
            {
                throw "HostUsage parameter was null or empty. Set HostUsage is required to Set HostName."
            }
        }

        # Check Elevated or not
        Write-Verbose "checking is this user elevated or not."
        Write-Verbose "Command : Test-ValentiaPowerShellElevated"
        if(-not(Test-ValentiaPowerShellElevated))
        {
	        throw "To run this Cmdlet on UAC 'Windows Vista, 7, 8, Windows Server 2008, 2008 R2, 2012 and later versions of Windows' must start an elevated PowerShell console."
        }
        else
        {
            Write-Verbose "Current session is already elevated, continue setup environment."
        }

    }

    process
    {
        # setup ScriptFile Reading
        Write-Verbose "Command : Set-ExecutionPolicy RemoteSigned -Force"
        Set-ExecutionPolicy RemoteSigned -Force -ErrorAction Stop

        if (-not($SkipEnablePSRemoting))
        {
            # setup PSRemoting
            Write-Verbose "Command : Enable-PSRemoting -Force"
            Enable-PSRemoting -Force -ErrorAction Stop
        }

        # Add $TrustedHosts hosts to trustedhosts
        Write-Verbose "Command : Enable-WsManTrustedHosts -TrustedHosts $TrustedHosts"
        Enable-WsManTrustedHosts -TrustedHosts $TrustedHosts -ErrorAction Stop

        # Configure WSMan MaxShellsPerUser to prevent error "The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded."
        # default 25 change to 100
        Write-Verbose "Command : Set-WsManMaxShellsPerUser -ShellsPerUser 100"
        Set-WsManMaxShellsPerUser -ShellsPerUser 100 -ErrorAction Stop

        # Enble WindowsPowerShell Remoting Firewall Rule
        Write-Verbose "Command : New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985"
        New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985

        # Set FireWall Status from Public to Private (not use for a while with EC2 on AWS)
        Write-Verbose "Command : Set-NetConnectionProfile -NetworkCategory Private"
        Set-NetConnectionProfile -NetworkCategory Private

        # Disable Enhanced Security for Internet Explorer
        Write-Verbose "Command : Disable-ValentiaEnhancedIESecutiry"
        Disable-ValentiaEnhancedIESecutiry

        # Add ec2-user 
        if ($NoOSUser)
        {
            Write-Verbose "NoOSUser switch was enabled, skipping create OSUser."
        }
        else
        {
            Write-Verbose "Command : New-ValentiaOSUser"
            New-ValentiaOSUser
        }



        # Create PowerShell ModulePath
        Write-Verbose "Create PowerShell ModulePath for deploy user."

        $users = $valentia.users
        if ($users -is [System.Management.Automation.PSCustomObject])
        {
            Write-Verbose ("Get properties for Parameter '{0}'." -f $users)
            $pname = $users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            Write-Verbose ("Loop each Users in {0}" -f $Users)
            foreach ($p in $pname)
            {

                Write-Verbose "Get Path for WindowsPowerShell modules"
                $PSModulePath = "C:\Users\$($Users.$p)\Documents\WindowsPowerShell\Modules"

                if (-not(Test-Path $PSModulePath))
                {
                    Write-Verbose "Create Module path"
                    New-Item -Path $PSModulePath -ItemType Directory -Force
                }
                else
                {
                    Write-Verbose ("{0} already exist. Nothing had changed. `n" -f $PSModulePath)
                }

            }
        }




        # Only if $Server swtich was passed. (Default $true, Only disabled when $client switch was passed.)
        if ($Server)
        {
            # Create Deploy Folder
            Write-Verbose "Command : New-ValentiaFolder"
            New-ValentiaFolder


            # Create Deploy user credential $user.pass
            Write-Verbose "Checking for Deploy User Credential secure credentail creation."
            if ($NoPassSave)
            {
                Write-Verbose "NoPassSave switch was enabled, skipping Create/Revise secure password file."
            }
            else
            {
                Write-Verbose "Create Deploy user credential .pass"
                Write-Verbose "Command : New-ValentiaCredential"
                New-ValentiaCredential
            }
        }



        # Set Host Computer Name (Checking if server name is same as current or not)
        Write-Verbose "Checking for HostName Status is follow rule and set if not correct."
        if ($NoSetHostName)
        {
            Write-Verbose "NoSetHostName switch was enabled, skipping Set HostName."
        }
        else
        {
            Write-Verbose "Command : Set-ValentiaHostName -HostUsage $HostUsage"
            Set-ValentiaHostName -HostUsage $HostUsage
        }


        # Checking for Reboot Status, if pending then prompt for reboot confirmation.
        Write-Verbose "Command : if ($NoReboot){Write-Verbose 'NoReboot switch was enabled, skipping reboot.'}elseif ($ForceReboot){Restart-Computer -Force}else{Restart-Computer -Force -Confirm}"
        if(Get-ValentiaRebootRequiredStatus)
        {
            if ($NoReboot)
            {
                Write-Verbose 'NoReboot switch was enabled, skipping reboot.'
            }
            elseif ($ForceReboot)
            {
                Restart-Computer -Force
            }
            else
            {
                Restart-Computer -Force -Confirm
            }
        }

    }
    
    end
    {
        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}



#-- Prerequisite Deploy Setting Module Functions --#

function New-ValentiaFolder{

<#

.SYNOPSIS 
Configure Deployment Path

.DESCRIPTION
This cmdlet will create valentis deploy folders for each Branch path.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaFolder
--------------------------------------------
create as default

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Root Folder path.")]
        [string]
        $RootPath = $valentia.RootPath,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Branch Folder path.")]
        [string]
        $BranchFolder = $valentia.BranchFolder,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Log Folder path.")]
        $LogFolder = $valentia.Log.path
    )

    begin
    {
        # Create Fullpath String
        $pname = $BranchFolder | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }
        $DeployFolders = $pname | %{Join-Path $RootPath $_}
    }

    process
    {
        # Check each Fupllpath and create if not exist.
        foreach ($Deployfolder in $DeployFolders)
        {
            if(!(Test-Path $DeployFolder))
            {
                Write-Verbose ("{0} not exist, creating {1}." -f $DeployFolder, $DeployFolder)
                New-Item -Path $DeployFolder -ItemType directory -Force > $null
            }
            else
            {
                Write-Verbose ("{0} already exist, skip create {1}." -f $DeployFolder, $DeployFolder)
            }
        }

        # Check Log Folder and create if not exist 
        if(!(Test-Path $LogFolder))
        {
            Write-Verbose ("{0} not exist, creating {1}." -f $LogFolder, $LogFolder)
            New-Item -Path $LogFolder -ItemType directory -Force > $null
        }
        else
        {
            Write-Verbose ("{0} already exist, skip create {1}." -f $LogFolder, $LogFolder)
        }

    }

    end
    {
        Write-Warning ("`nDisplay all deployFolders existing at [ {0} ]" -f $RootPath)
        (Get-ChildItem -Path $RootPath).FullName

        Write-Warning ("`nDisplay Logfolders existing at [ {0} ]" -f $LogFolder)
        (Get-ChildItem -Path $LogFolder).FullName

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}



#-- Prerequisite OS Setting Module Functions --#

function Enable-WsManTrustedHosts{

<#

.SYNOPSIS 
Enable WsMan Trusted hosts

.DESCRIPTION
Specify Trustedhosts to allow

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-WsManTrustedHosts
--------------------------------------------
allow all hosts as * 

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Specify TrustedHosts to allow.")]
        [string]
        $TrustedHosts,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Specify path to WSMan TrustedHosts.")]
        [string]
        $TrustedHostsPath = "WSman:localhost\client\TrustedHosts"
    )


    if (-not((Get-ChildItem $TrustedHostsPath).Value -eq $TrustedHosts))
    {
        Set-Item -Path $TrustedHostsPath -Value $TrustedHosts -Force
    }
    else
    {
        Write-Verbose ("WinRM Trustedhosts was alredy enabled for {0}." -f $TrustedHosts)
        Get-ChildItem $TrustedHostsPath
    }
}



function Set-WsManMaxShellsPerUser{

<#

.SYNOPSIS 
Set WsMan Max Shells Per user to prevent "The WS-Management service cannot process the request. 

.DESCRIPTION
This user is allowed a maximum number of xx concurrent shells, which has been exceeded."
Default value : 25 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-WsManMaxShellsPerUser -ShellsPerUser 100
--------------------------------------------
set as 100

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input ShellsPerUser count.")]
        [int]
        $ShellsPerUser,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Set path to WSMan MaxShellsPerUser.")]
        [string]
        $MaxShellsPerUserPath = "WSMan:\localhost\Shell\MaxShellsPerUser"
    )
    
    if (-not((Get-ChildItem $MaxShellsPerUserPath).Value -eq $ShellsPerUser))
    {
        Set-Item -Path $MaxShellsPerUserPath -Value $ShellsPerUser -Force
    }
    else
    {
        Write-Verbose ("WinRM Trustedhosts was alredy enabled for {0}." -f $ShellsPerUser)
        Get-ChildItem $MaxShellsPerUserPath
    }
}



function New-ValentiaPSRemotingFirewallRule{

<#

.SYNOPSIS 
Create New Firewall Rule for PowerShell Remoting

.DESCRIPTION
Will allow PowerShell Remoting port for firewall

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-PSRemotingFirewallRule
--------------------------------------------
Add PowerShellRemoting-In accessible rule to Firewall.

#>


    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Input PowerShellRemoting-In port. default is 5985")]
        [int]
        $PSRemotePort = 5985,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input Name of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Name = "PowerShellRemoting-In",

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input Decription of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Description = "Windows PowerShell Remoting required to open for public connection. not for private network.",

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Input Group of Firewall rule for PowerShellRemoting-In.")]
        [string]
        $Group = "Windows Remote Management"
    )

    if (-not((Get-NetFirewallRule | where Name -eq $Name) -and (Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq $PSRemotePort)))
    {
        Write-Verbose ("Windows PowerShell Remoting port TCP $PSRemotePort was not opend. Set new rule [ {1} ]" -f $PSRemotePort, $Name)
        New-NetFirewallRule `
            -Name $Name `
            -DisplayName $Name `
            -Description $Description `
            -Group $Group `
            -Enabled True `
            -Profile Any `
            -Direction Inbound `
            -Action Allow `
            -EdgeTraversalPolicy Block `
            -LooseSourceMapping $False `
            -LocalOnlyMapping $False `
            -OverrideBlockRules $False `
            -Program Any `
            -LocalAddress Any `
            -RemoteAddress Any `
            -Protocol TCP `
            -LocalPort $PSRemotePort `
            -RemotePort Any `
            -LocalUser Any `
            -RemoteUser Any 
    }
    else
    {
        Write-Verbose "Windows PowerShell Remoting port TCP 5985 was alredy opened. Get Firewall Rule."
        Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq 5985
    }
}




function Disable-ValentiaEnhancedIESecutiry{

<#

.SYNOPSIS 
Disable EnhancedIESecutiry for Internet Explorer

.DESCRIPTION
Change registry to disable EnhancedIESecutiry.
It will only work for [Windows Server] not for Workstation, and [Windows Server 2008 R2] and higer.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Disable-ValentiaEnhancedIESecutiry
--------------------------------------------
Disable IEEnhanced security.

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Registry key for Admin.")]
        [string]
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}",
    
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Registry key for User.")]
        [string]
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    )

    # get os name like "Microsoft Windows Server 2012 Standard"
    $osname = (Get-WmiObject -class Win32_OperatingSystem).Caption

    # get os version, Windows 7 will be "6 1 0 0"
    $osversion = [Environment]::OSVersion.Version

    # Higher than $valentia.supportWindows
    $minimumversion = (New-Object 'Version' $valentia.supportWindows)

    # check osname include server and higher than valentia support version
    if (($osname -like "*Server*") -and ($osversion -ge $minimumversion))
    {
        if (Test-Path $AdminKey)
        {
            if ((Get-ItemProperty -Path $AdminKey -Name “IsInstalled”).IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }

        if (Test-Path $UserKey)
        {
            if ((Get-ItemProperty -Path $UserKey -Name “IsInstalled”).IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }

        if ($IsstatusChanged)
        {
            Write-Verbose "IE Enhanced Security Configuration (ESC) has been disabled. Checking IE to stop process."

            # Stop Internet Exploer if launch
            Write-Verbose "Checking iexplore process status and trying to kill if exist"
            Get-Process | where Name -eq "iexplore" | Stop-Process
        }
        else
        {
            Write-Verbose "IE Enhanced Security Configuration (ESC) had already been disabled. Nothing will do."
        }
    }
    else
    {
        Write-Warning -Message ("OS Name:{0}, Version:{1}, invalid as 'server' not found or '{2}'" -f $osname, [Environment]::OSVersion.Version, $minimumversion)
    }
}



function New-ValentiaOSUser{

<#

.SYNOPSIS 
Create New Local User for Deployment

.DESCRIPTION
Deployment will use deploy user account credential to avoid any change for administartor.
You must add all this user credential for each clients.

# User Flag Property Samples. You should combinate these 0x00zz if required.
#
#  &H0001    Run LogOn Script　
#  0X0001    ADS_UF_SCRIPT 
#
#  &H0002    Account Disable
#  0X0002    ADS_UF_ACCOUNTDISABLE
#
#  &H0008    Account requires Home Directory
#  0X0008    ADS_UF_HOMEDIR_REQUIRED
#
#  &H0010    Account Lockout
#  0X0010    ADS_UF_LOCKOUT
#
#  &H0020    No Password reqyured for account
#  0X0020    ADS_UF_PASSWD_NOTREQD
#
#  &H0040    No change Password
#  0X0040    ADS_UF_PASSWD_CANT_CHANGE
#
#  &H0080    Allow Encypted Text Password
#  0X0080    ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED
#
#  0X0100    ADS_UF_TEMP_DUPLICATE_ACCOUNT
#  0X0200    ADS_UF_NORMAL_ACCOUNT
#  0X0800    ADS_UF_INTERDOMAIN_TRUST_ACCOUNT
#  0X1000    ADS_UF_WORKSTATION_TRUST_ACCOUNT
#  0X2000    ADS_UF_SERVER_TRUST_ACCOUNT
#
#  &H10000   Password infinit
#  0X10000   ADS_UF_DONT_EXPIRE_PASSWD
#
#  0X20000   ADS_UF_MNS_LOGON_ACCOUNT
#
#  &H40000   Smart Card Required
#  0X40000   ADS_UF_SMARTCARD_REQUIRED
#
#  0X80000   ADS_UF_TRUSTED_FOR_DELEGATION
#  0X100000  ADS_UF_NOT_DELEGATED
#  0x200000  ADS_UF_USE_DES_KEY_ONLY
#
#  0x400000  ADS_UF_DONT_REQUIRE_PREAUTH
#
#  &H800000  Password expired
#  0x800000  ADS_UF_PASSWORD_EXPIRED
#
#  0x1000000 ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaOSUser
--------------------------------------------
Recommend - Secure Input.
secure prompt will up and mask your PASSWORD input as *****.

.EXAMPLE
New-valentiaOSUser -Password "1231231qawerqwe87$%"
--------------------------------------------
NOT-Recommend - Unsecure Input
Visible prompt will up and non-mask your PASSWORD input as *****.

#>

    [CmdletBinding(
        DefaultParameterSetName = 'Secret')]
    param(
        [parameter(
            mandatory　= 0,
            HelpMessage = "User account Name.")]
        $Users = $valentia.users.deployuser,

        [parameter(
            mandatory,
            ParameterSetName = 'Secret',
            HelpMessage = "User account Password.")]
        [Security.SecureString]
        ${Type your OS User password},

        [parameter(
            mandatory,
            ParameterSetName = 'Plain',
            HelpMessage = "User account Password.")]
        [String]
        $Password = "",

        [parameter(
            mandatory = 0,
            HelpMessage = "User account belonging UserGroup.")]
        [string]
        $Group = $valentia.group
    )

    begin
    {
        $HostPC = [System.Environment]::MachineName
        $DirectoryComputer = New-Object System.DirectoryServices.DirectoryEntry("WinNT://" + $HostPC + ",computer")
        $ExistingUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount='true'"

        if ($Password)
        {
            $SecretPassword = $Password | ConvertTo-SecureString -AsPlainText -Force
        }
        else
        {
            $SecretPassword = ${Type your OS User password}
        }
    }

    process
    {
        
        Write-Verbose "Checking type of users variables to retrieve property"
        if ($Users -is [System.Management.Automation.PSCustomObject])
        {
            Write-Verbose ("Get properties for Parameter '{0}'." -f $Users)
            $pname = $Users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            Write-Verbose ("Loop each Users in {0}" -f $Users)
            foreach ($p in $pname){
                if ($users.$p -notin $ExistingUsers.Name)
                {
                    # Create User
                    Write-Verbose ("{0} not exist, start creating user." -f $Users.$p)
                    $newuser = $DirectoryComputer.Create("user", $Users.$p)
                    $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                    $newuser.SetInfo()

                    # Get Account UserFlag to set
                    $userFlags = $newuser.Get("UserFlags")

                    #UserFlag for password (ex. infinity & No change Password)
                    Write-Verbose "Define user flag to define account"
                    $userFlags = $userFlags -bor 0X10040

                    Write-Verbose "Put user flag to define account"
                    $newuser.Put("UserFlags", $userFlags)

                    Write-Verbose "Set user flag to define account"
                    $newuser.SetInfo()

                    #Assign Group for this user
                    Write-Verbose ("Assign User to UserGroup {0}" -f $UserGroup)
                    $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                    $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users.$p)
                }
                else
                {
                    Write-Verbose ("UserName {0} already exist. Nothing had changed." -f $Users.$p)
                }
            }
        }
        elseif($Users -is [System.String])
        {
            Write-Verbose ("Execute with only a user defined in {0}" -f $users)
            if ($users -notin $ExistingUsers.Name)
            {
                # Create User
                Write-Verbose ("{0} not exist, start creating user." -f $users)
                $newuser = $DirectoryComputer.Create("user", $Users)
                $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                $newuser.SetInfo()

                # Get Account UserFlag to set
                $userFlags = $newuser.Get("UserFlags")

                #UserFlag for password (ex. infinity & No change Password)
                Write-Verbose "Define user flag to define account"
                $userFlags = $userFlags -bor 0X10040

                Write-Verbose "Put user flag to define account"
                $newuser.Put("UserFlags", $userFlags)

                Write-Verbose "Set user flag to define account"
                $newuser.SetInfo()

                #Assign Group for this user
                Write-Verbose ("Assign User to UserGroup {0}" -f $UserGroup)
                $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users)
            }
        }
        else
        {
            throw ("Users must passed as string or custom define in {0}" -f $valentia.defaultconfigurationfile)
        }
    }

    end
    {
    }
}


# rename
function Set-ValentiaHostName{

<#

.SYNOPSIS 
Change Computer name as specified usage.

.DESCRIPTION
To control hosts, set prefix for each client with IPAddress octets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-valentiaHostName -HostUsage web
--------------------------------------------
Change Hostname as web-$PrefixHostName-$PrefixIpString-Ip1-Ip2-Ip3-Ip4

#>

    [CmdletBinding()]  
    param(
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [string]
        $PrefixHostName = $valentia.prefix.hostname,

        $PrefixIpString = $valentia.prefic.ipstring
    )

    begin
    {
        
        # Get IpAddress
        $ipAddress = ([Net.Dns]::GetHostAddresses('').IPAddressToString | Select-String -Pattern "^\d*.\.\d*.\.\d*.\.\d*.").line

        # Replace . of IpAddress to -
        $ipAddressString = $ipAddress -replace "\.","-"

        # Create New Host Name
        $newHostName = $PrefixHostName + "-" + $HostUsage + "-" + $PrefixIpString + $ipAddressString

        $currentHostName = [Net.Dns]::GetHostName()
    }
    
    process
    {
        if ( $currentHostName -eq $newHostName)
        {
            Write-Verbose ("Current HostName [ {0} ] was same as new HostName [ {1} ]. Nothing Changed." -f $currentHostName, $newHostName)
        }
        else
        {
            Write-Warning -Message ("Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
            Rename-Computer -NewName $newHostName -Force
        }
    }

    end
    {
    }

}



function Get-ValentiaRebootRequiredStatus{

<#

.SYNOPSIS 
Get reboot require status for client

.DESCRIPTION
When Windows Update or Change Hostname event is done, it will requires reboot to take change effect.
You can obtain reboot required status with this cmdlet.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Get-ValentiaRebootRequiredStatus
--------------------------------------------
Obtain reboot required status.

#>

    [CmdletBinding()]
    param(
    )

    begin
    {
        $WindowsUpdateRebootStatus = $false
        $FileRenameRebootStatus = $false
        $WindowsUpdateRebootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        $FileRenameRebootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    }

    process
    {
        if (Test-Path $WindowsUpdateRebootPath)
        {
            $WindowsUpdateRebootStatus = $true
        }


        if ((Get-ItemProperty -Path $FileRenameRebootPath).PendingFileRenameOperations)
        {
            $FileRenameRebootStatus = $True
        }

        $Result = [PSCustomObject]@{
            ComputerName = [Net.DNS]::GetHostName()
            PendingWindowsUpdateReboot= $WindowsUpdateRebootStatus
            PendingFileRenameReboot = $FileRenameRebootStatus
        }

    }

    end
    {
        return $Result
    }

}




#-- Public Loading Module Functions --#

# reload
function Get-ValentiaModuleReload{

    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [ValidateScript({Get-Module -Name $ModuleName})]
        $ModuleName = "valentia",

        [Parameter(
            Position = 1,
            Mandatory = 0)]
        [string]
        $scriptPath = $(Split-Path -parent $Script:MyInvocation.MyCommand.Path)
    )

    
    # '[v]alentia' is the same as 'valentia' but $Error is not polluted
    Remove-Module [v]alentia
    Import-Module (Join-Path $scriptPath valentia.psm1)

}



function Import-ValentiaModules{
 
    [CmdletBinding()]
    param(
    )

    $currentConfig = $valentia.context.Peek().config
    if ($currentConfig.modules)
    {
        $currentConfig.modules | ForEach-Object { 
            Resolve-Path $_ | ForEach-Object { 
                "Loading module: $_"
                $module = Import-Module $_ -passthru -DisableNameChecking -global:$global
                if (!$module) 
                {
                    throw ($msgs.error_loading_module -f $_.Name)
                }
            }
        }
        ""
    }

}



#-- Public Loading Module Custom Configuration Functions --#


function Import-ValentiaConfigration{

    [CmdletBinding()]
    param(
        [string]
        $configdir = $PSScriptRoot
    )

    $valentiaConfigFilePath = (Join-Path $configdir $valentia.defaultconfigurationfile)

    if (Test-Path $valentiaConfigFilePath -pathType Leaf) 
    {
        try 
        {
            
            Write-Verbose $valeWarningMessages.warn_load_currentConfigurationOrDefault
            $config = Get-CurrentConfigurationOrDefault
            . $valentiaConfigFilePath
        } 
        catch 
        {
            throw ("Error Loading Configuration from {0}: " -f $valentia.defaultconfigurationfile) + $_
        }
    }
}


function Get-CurrentConfigurationOrDefault{

    [CmdletBinding()]
    param(
    )

    if ($valentia.context.count -gt 0) 
    {
        return $valentia.context.peek().config
    } 
    else 
    {
        return $valentia.config_default
    }
}



function New-ValentiaConfigurationForNewContext{

    [CmdletBinding()]
    param(
        [string]
        $buildFileName
    )

    $previousConfig = Get-CurrentConfigurationOrDefault

    $config = New-Object psobject -property @{
        buildFileName = $previousConfig.buildFileName;
        framework = $previousConfig.framework;
        taskNameFormat = $previousConfig.taskNameFormat;
        verboseError = $previousConfig.verboseError;
        modules = $previousConfig.modules;
    }

    if ($buildFileName)
    {
        $config.buildFileName
    }

    return $config

}


#-- Private Loading Module Parameters --#

# Setup Messages to be loaded
DATA valeParamHelpMessages{
ConvertFrom-StringData @'
    param_Get_ValentiaTask_Name = Input TaskName you want to set and not dupricated.
    param_Action = Write ScriptBlock Action to execute with this task.
    param_DeployGroups = Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].
    param_DeployFolder = Input DeployGroup Folder path if changed from default.
    param_TaskFileName = Move to Brach folder you sat taskfile, then input TaskFileName. exclusive with ScriptBlock.
    param_ScriptBlock = Input Script Block {hogehoge} you want to execute with this commandlet. exclusive with TaskFileName.
    param_quiet = Hide execution progress.
    param_ScriptToRun = Input ScriptBlock. ex) Get-ChildItem; Get-NetAdaptor | where MTUSize -gt 1400
    param_wsmanSessionlimit = Input wsmanSession Threshold number to restart wsman
    param_Sessions = Input Session.
    param_RunspacePool = Runspace Poll required to set one or more, easy to create by New-ValentiaRunSpacePool.
    param_ScriptToRunHash = The scriptblock hashtable to be executed to the Remote host.
    param_DeployMember = Target Computers to execute scriptblock.
    param_credentialHash = Remote Login PSCredentail HashTable for PSRemoting. 
    param_PoolSize = Defines the maximum number of pipelines that can be concurrently (asynchronously) executed on the pool.
    param_Pipelines = An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.
    param_ShowProgress = An optional switch to display a progress indicator.
    param_Invoke_ValentiaUpload_SourcePath = Input Deploy Server SourcePath to be uploaded.
    param_Invoke_ValentiaUpload_DestinationPath = Input Clinet DestinationPath to save upload items.
    param_File = Set this switch to execute command for File. exclusive with Directory Switch.
    param_Directory = Set this switch to execute command for Directory. exclusive with File Switch.
    param_Async = Set this switch to execute command as Async (Job).
    param_ListFile = Input path defines source/destination of upload.
    param_Invoke_ValentiaSync_SourceFolder = Input Deploy Server Source Folder Sync to Client PC.
    param_Invoke_ValentiaSync_DestinationFolder = Input Client Destination Folder Sync with Desploy Server.
    param_FastCopyFolder = Input fastCopy.exe location folder if changed from default.
    param_FastcopyExe = Input fastCopy.exe name if changed from default.
    param_Invoke-ValentiaDownload_SourcePath = Input Client SourcePath to be downloaded.
    param_Invoke-ValentiaDownload_DestinationFolder = Input Server Destination Folder to save download items.
    param_Invoke-ValentiaDownload_force = Set this switch if you want to Force download. This will smbmap with source folder and Copy-Item -Force. (default is BitTransfer)

'@
}


# will be replace warning messages to StringData
DATA valeWarningMessages{
ConvertFrom-StringData @'
    warn_WinRM_session_exceed_nearly = WinRM session exceeded {0} and neerly limit of 25. Restarted WinRM on Remote Server to reset WinRM session.
    warn_WinRM_session_exceed_restarted = Restart Complete, trying remote session again.
    warn_WinRM_session_exceed_already = WinRM session is now {0}. It exceed {1} and neerly limit of 25. Restarting WinRM on Remote Server to reset WinRM session.
    warn_Stopwatch_showduration = ("`t`t{0}"
    warn_import_configuration = Importing Valentia Configuration.
    warn_import_modules = Importing Valentia modules.
    warn_import_task_begin = Importing Valentia task.
    warn_import_task_end = Task Load Complete. set task to lower case for keyname.
    warn_get_current_context = Get Current Context from valentia.context.peek().
    warn_set_taskkey = Task key was new, set taskkey into current.context.taskkey.
    warn_load_currentConfigurationOrDefault = Load Current Configuration or Default.
'@
}


# will be replace error messages to StringData
DATA valeErrorMessages{
ConvertFrom-StringData @'
    error_invalid_task_name = Task name should not be null or empty string.
    error_task_name_does_not_exist = Task {0} does not exist.
    error_unknown_pointersize = Unknown pointer size ({0}) returned from System.IntPtr.
    error_bad_command = Error executing command {0}.
    error_default_task_cannot_have_action = 'default' task cannot specify an action.
    error_duplicate_task_name = Task {0} has already been defined.
    error_duplicate_alias_name = Alias {0} has already been defined.
    error_invalid_include_path = Unable to include {0}. File not found.
    error_build_file_not_found = Could not find the build file {0}.
    error_no_default_task = 'default' task required.
'@
}

# not yet ready but to resolve UI Culture for each country localization message.
# Import-LocalizedData -BindingVariable messages -ErrorAction silentlycontinue

# contains default base configuration, may not be override without version update.
$Script:valentia = @{}
$valentia.name = "valentia" # contains the Name of Module
$valentia.defaultconfigurationfile = "valentia-config.ps1" # default configuration file name within valentia.psm1
$valentia.version = "0.3.0" # contains the current version of valentia
$valentia.supportWindows = @(6,1) # higher than windows 7 or windows 2008 R2
$valentia.context = New-Object System.Collections.Stack # holds onto the current state of all variables



#-- Public Loading Module Parameters (Recommend to use ($valentia.defaultconfigurationfile) for customization)--#

# contains default configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.config_default = New-Object PSObject -property @{
    TaskFileName = "default.ps1";
    TaskFileDir = $valentia.BranchFolder.Application;
    taskNameFormat = "Executing {0}";
    verboseError = $false;
    modules = $null;
}


# contains default OS user configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.users = New-Object psobject -property @{
    deployUser = "deployment"
}
$valentia.group = "Administrators"

# contains valentia configuration Information
$valentia.PSDrive = "V:" # Set Valentia Mapping Drive with SMBMapping
$valentia.deployextension = ".ps1" # contains default DeployGroup file extension
$valentia.wsmanSessionlimit = 22 # Set PSRemoting WSman limit prvention threshold


# Define Prefix for Deploy Client NetBIOS name
$valentia.prefix = New-Object psobject -property @{
    hostName = "web"
    ipstring = "ip"
}


# Define External program path
$valentia.fastcopy = New-Object psobject -property @{
    folder = "C:\Program Files\FastCopy"
    exe = "FastCopy.exe"
}


# contains default Path configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.RootPath = "C:\Deployment"
$valentia.BranchFolder = New-Object psobject -property @{
    Application = "Application"
    Bin = "Bin"
    Deploygroup = "DeployGroup"
    Download = "Download"
    Maintenance = "Maintenance"
    Upload = "Upload"
    Utils = "Utils"
}


# Set Valentia Log
$valentia.log = New-Object psobject -property @{
    path = "C:\Logs\Deployment"
    name = "deploy"
    extension = ".log"
}


# contains context for default.
$valentia.context.push(
    @{
        executedTasks = New-Object System.Collections.Stack;
        callStack = New-Object System.Collections.Stack;
        originalEnvPath = $env:Path;
        originalDirectory = Get-Location;
        originalErrorActionPreference = $global:ErrorActionPreference;
        name = $valentia.name
        version = $valentia.version
        supportWindows = $valentia.supportWindows
        tasks = @{}
        includes = New-Object System.Collections.Queue;
    }
)



#-- Set Alias for public valentia commands --#

Write-Verbose "Set Alias for valentia Cmdlets."

New-Alias -Name Task -Value Get-ValentiaTask
New-Alias -Name Valep -Value Invoke-ValentiaParallel
New-Alias -Name CommandP -Value Invoke-ValentiaCommandParallel
New-Alias -Name Vale -Value Invoke-Valentia
New-Alias -Name Command -Value Invoke-ValentiaCommand
New-Alias -Name Valea -Value Invoke-ValentiaAsync
New-Alias -Name Upload -Value Invoke-ValentiaUpload
New-Alias -Name UploadL -Value Invoke-ValentiaUploadList
New-Alias -Name Sync -Value Invoke-ValentiaSync
New-Alias -Name Download -Value Invoke-ValentiaDownload
New-Alias -Name Go -Value Set-ValentiaLocation
New-Alias -Name Clean -Value Invoke-ValentiaClean
New-Alias -Name Reload -Value Get-ValentiaModuleReload
New-Alias -Name Target -Value Get-ValentiaGroup
New-Alias -Name Cred -Value Get-ValentiaCredential
New-Alias -Name Rename -Value Set-ValentiaHostName
New-Alias -Name Initial -Value Initialize-valentiaEnvironment

#-- Loading Internal Function when loaded --#

Import-ValentiaModules
Import-ValentiaConfigration

#-- Loading external module files --#

Write-Verbose "Loading external modules for valentia."
# . $PSScriptRoot\*.ps1

#-- Export Modules when loading this module --#

Export-ModuleMember `
    -Function Get-ValentiaTask, 
        Invoke-ValentiaParallel, 
        Invoke-ValentiaCommandParallel, 
        Invoke-Valentia,
        Invoke-ValentiaCommand,
        Invoke-ValentiaAsync,
        Invoke-ValentiaUpload, 
        Invoke-ValentiaUploadList, 
        Invoke-ValentiaSync,
        Invoke-ValentiaDownload,
        Get-ValentiaGroup, 
        Get-ValentiaCredential,
        Set-ValentiaLocation, 
        Invoke-ValentiaClean,
        New-ValentiaCredential, 
        New-ValentiaFolder,
        New-ValentiaGroup,
        Get-ValentiaModuleReload, 
        Initialize-valentiaEnvironment,
        Set-ValentiaHostName,
        Get-ValentiaRebootRequiredStatus `
    -Variable valentia `
    -Alias *