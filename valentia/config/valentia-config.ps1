#-- Public Loading Module Parameters (Recommend to use ($valentia.defaultconfigurationfile) for customization)--#

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
    title                               = "Select item from prompt choices.";
    questions                           = @("Yes", "No");
    helpMessage                         = "Enter '{0}' to select this choice."
    message                             = "Type alphabet you want to choose.";
    additionalMessage                   = $null;
    defaultIndex                        = 0;
}
