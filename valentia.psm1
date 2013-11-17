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


#-- Public Loading Module Custom Configuration Functions --#

function Import-ValentiaConfigration
{

    [CmdletBinding()]
    param
    (
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


function Get-CurrentConfigurationOrDefault
{

    [CmdletBinding()]
    param
    (
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



function New-ValentiaConfigurationForNewContext
{

    [CmdletBinding()]
    param
    (
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


function Import-ValentiaModules
{
 
    [CmdletBinding()]
    param
    (
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
        "" # blank line for next entry
    }
}


#-- Private Loading Module Parameters --#

# Setup Messages to be loaded
DATA valeParamHelpMessages
{
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
DATA valeWarningMessages
{
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
DATA valeErrorMessages
{
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

#-- Private Loading Module Parameters --#

# contains default base configuration, may not be override without version update.
$Script:valentia                        = @{}
$valentia.name                          = "valentia"                          # contains the Name of Module
$valentia.modulePath                    = Split-Path -parent $MyInvocation.MyCommand.Definition
$valentia.helpersPath                   = "\functions\*.ps1"
$valentia.defaultconfigurationfile      = "valentia-config.ps1"               # default configuration file name within valentia.psm1
$valentia.supportWindows                = @(6,1,0,0)                          # higher than windows 7 or windows 2008 R2
$valentia.fileEncode                    = "utf8"
$valentia.context                       = New-Object System.Collections.Stack # holds onto the current state of all variables

$valentia.originalErrorActionPreference = $ErrorActionPreference
$valentia.errorPreference               = "Stop"
$valentia.originalDebugPreference       = $DebugPreference
$valentia.debugPreference               = "SilentlyContinue"

#-- Public Loading Module Parameters (Recommend to use ($valentia.defaultconfigurationfile) for customization) --#

# contains context for default.
$valentia.context.push(
    @{
        executedTasks                   = New-Object System.Collections.Stack;
        callStack                       = New-Object System.Collections.Stack;
        originalEnvPath                 = $env:Path;
        originalDirectory               = Get-Location;
        originalErrorActionPreference   = $valentia.originalErrorActionPreference;
        ErrorActionPreference           = $valentia.errorPreference;
        originalDebugPreference         = $valentia.originalDebugPreference;
        debugPreference                 = $valentia.debugPreference;
        name                            = $valentia.name;
        modulePath                      = $valentia.modulePath;
        helpersPath                     = Join-Path $valentia.modulePath $valentia.helpersPath;
        supportWindows                  = $valentia.supportWindows;
        fileEncode                      = $valentia.fileEncode
        tasks                           = @{};
        includes                        = New-Object System.Collections.Queue;
    }
)


#-- Public Loading Module Parameters (Recommend to use ($valentia.defaultconfigurationfile) for customization) --#

# contains default configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.config_default = New-Object PSObject -property @{
    TaskFileName                        = "default.ps1";
    TaskFileDir                         = $valentia.BranchFolder.Application;
    taskNameFormat                      = "Executing {0}";
    verboseError                        = $false;
    modules                             = $null;
}

# contains RunSpace Pool Size for Asynchronous cmdlet (Invoke-ValentiaAsync)
$valentia.poolSize = New-Object psobject -property @{
    minPoolSize                         = 50;
    maxPoolSize                         = 50;
}

# contains default OS user configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.users = New-Object psobject -property @{
    deployUser                          = "deployment";
}
$valentia.group                         = "Administrators"

# contains valentia configuration Information
$valentia.PSDrive                       = "V:";             # Set Valentia Mapping Drive with SMBMapping
$valentia.deployextension               = ".ps1";           # contains default DeployGroup file extension
$valentia.wsmanSessionlimit             = 22 ;              # Set PSRemoting WSman limit prvention threshold

# Define Prefix for Deploy Client NetBIOS name
$valentia.prefix = New-Object psobject -property @{
    hostName                            = "web";
    ipstring                            = "ip";
}

# Define External program path
$valentia.fastcopy = New-Object psobject -property @{
    folder                              = "C:\Program Files\FastCopy";
    exe                                 = "FastCopy.exe";
}

# contains default Path configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.RootPath                      = "C:\Deployment"
$valentia.BranchFolder = New-Object psobject -property @{
    Application                         = "Application";
    Bin                                 = "Bin";
    Deploygroup                         = "DeployGroup";
    Download                            = "Download";
    Maintenance                         = "Maintenance";
    Upload                              = "Upload";
    Utils                               = "Utils";
}

# Set Valentia Log
$valentia.log = New-Object psobject -property @{
    path                                = "C:\Logs\Deployment";
    name                                = "deploy";
    extension                           = ".log";
}

# Set Valentia prompt for choice messages
$valentia.promptForChoice = New-Object psobject -property @{
    title                               = "Select from prompt choice";
    questionHelps                       = @("Yes", "No");
    message                             = "Type index you want to choose.";
    additionalMessage                   = $null;
    defaultIndex                        = 0;
}

# contains default configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.config_default                = New-Object PSObject -property @{
    TaskFileName                        = "default.ps1";
    TaskFileDir                         = $valentia.BranchFolder.Application;
    taskNameFormat                      = "Executing {0}";
    verboseError                        = $false;
    modules                             = $null;
    PSDrive                             = $valentia.PSDrive;
    deployextension                     = $valentia.deployextension;
    wsmanSessionlimit                   = $valentia.wsmanSessionlimit;
    prefix                              = $valentia.prefix;
    fastcopy                            = $valentia.fastcopy;
    RootPath                            = $valentia.RootPath;
    BranchFolder                        = $valentia.BranchFolder;
    log                                 = $valentia.log;
}

#-- Set Alias for public valentia commands --#

Write-Verbose "Set Alias for valentia Cmdlets."

New-Alias -Name Task       -Value Get-ValentiaTask
New-Alias -Name Valep      -Value Invoke-ValentiaParallel
New-Alias -Name Vale       -Value Invoke-Valentia
New-Alias -Name Valea      -Value Invoke-ValentiaAsync
New-Alias -Name Upload     -Value Invoke-ValentiaUpload
New-Alias -Name UploadL    -Value Invoke-ValentiaUploadList
New-Alias -Name Sync       -Value Invoke-ValentiaSync
New-Alias -Name Download   -Value Invoke-ValentiaDownload
New-Alias -Name Go         -Value Set-ValentiaLocation
New-Alias -Name Clean      -Value Invoke-ValentiaClean
New-Alias -Name Reload     -Value Get-ValentiaModuleReload
New-Alias -Name Target     -Value Get-ValentiaGroup
New-Alias -Name ipremark   -Value Invoke-valentiaDeployGroupRemark
New-Alias -Name ipunremark -Value Invoke-valentiaDeployGroupUnremark
New-Alias -Name Cred       -Value Get-ValentiaCredential
New-Alias -Name Rename     -Value Set-ValentiaHostName
New-Alias -Name Initial    -Value Initialize-valentiaEnvironment


# -- Export Modules when loading this module -- #
# grab functions from files

Resolve-Path (Join-Path $valentia.modulePath $valentia.helpersPath) | 
    where { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

#-- Loading Internal Function when loaded --#

Import-ValentiaModules
Import-ValentiaConfigration

#-- Export Modules when loading this module --#

Export-ModuleMember `
    -Cmdlet * `
    -Function * `
    -Variable * `
    -Alias *