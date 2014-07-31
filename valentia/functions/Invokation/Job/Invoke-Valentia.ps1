#Requires -Version 3.0

#-- Public Module Job / Functions for Remote Execution --#

# vale

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
function Invoke-Valentia
{
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
        $quiet,

        [Parameter(
            Position = 5, 
            Mandatory = 0,
            HelpMessage = "Select Authenticateion for Credential.")]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]
        $Authentication = $valentia.Authentication,

        [Parameter(
            Position = 6,
            Mandatory = 0,
            HelpMessage = "Return success result even if there are error.")]
        [bool]
        $SkipException = $false
    )

    process
    {
        try
        {
        #region Begin
        
            # Initialize Stopwatch
            $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

            # clear previous result
            Invoke-ValentiaCleanResult

            # Initialize Error status
            $valentia.Result.SuccessStatus = $valentia.Result.ErrorMessageDetail = @()

            # Get Start Time
            $valentia.Result.TimeStart = (Get-Date).DateTime

            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules

            # Log Setting
            New-ValentiaLog

            # Set Task and push CurrentContext
            $task = Push-ValentiaCurrentContextToTask -ScriptBlock $scriptBlock -TaskFileName $TaskFileName
  
            # Set Task as CurrentContext with task key
            $valentia.Result.ScriptTorun = $task.Action

            # Obtain Remote Login Credential (No need if clients are same user/pass)
            try
            {
                $Credential = Get-ValentiaCredential -Verbose:$VerbosePreference
                $valentia.Result.SuccessStatus += $true
            }
            catch
            {
                $valentia.Result.SuccessStatus += $false
                $valentia.Result.ErrorMessageDetail += $_
                Write-Error $_
            }

            # Obtain DeployMember IP or Hosts for deploy
            try
            {
                "Get host addresses to connect." | Write-ValentiaVerboseDebug
                $valentia.Result.DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
            }
            catch
            {
                $valentia.Result.SuccessStatus += $false
                $valentia.Result.ErrorMessageDetail += $_
                Write-Error $_
            }

            # Show Stopwatch for Begin section
            Write-Verbose ("{0}Duration Second for Begin Section: {1}" -f "`t`t", $TotalstopwatchSession.Elapsed.TotalSeconds)

        #endregion

        #region Process

            # Job execution
            $param = @{
                Credential      = $Credential
                TaskParameter   = $TaskParameter
                Authentication  = $Authentication
                SkipException   = $SkipException
                ErrorAction     = $originalErrorAction
            }
            Invoke-ValentiaJobProcess @param

        #endregion

        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            if ($ErrorActionPreference -eq 'Stop')
            {
                throw $_
            }
        }
        finally
        {
            # obtain Result
            $resultParam = @{
                StopWatch     = $TotalstopwatchSession
                Cmdlet        = $($MyInvocation.MyCommand.Name)
                TaskFileName  = $TaskFileName
                DeployGroups  = $DeployGroups
                SkipException = $SkipException
                Quiet         = $PSBoundParameters.ContainsKey("quiet")
            }
            Out-ValentiaResult @resultParam

            # Cleanup valentia Environment
            Invoke-ValentiaClean
        }
    }

    begin
    {
        # Reset ErrorActionPreference
        if ($PSBoundParameters.ContainsKey('ErrorAction'))
        {
            $originalErrorAction = $ErrorActionPreference
        }
        else
        {
            $originalErrorAction = $ErrorActionPreference = $valentia.preference.ErrorActionPreference.original
        }
    }
}
