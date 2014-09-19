#-- Public Loading Module Parameters (Recommend to use ($valentia.defaultconfigurationfile) for customization) --#

# contains context for default.
$valentia.context.push(
    @{
        executedTasks                 = New-Object System.Collections.Stack;
        callStack                     = New-Object System.Collections.Stack;
        originalEnvPath               = $env:Path;
        originalDirectory             = Get-Location;
        originalErrorActionPreference = $valentia.preference.ErrorActionPreference.original;
        errorActionPreference         = $valentia.preference.ErrorActionPreference.custom;
        originalDebugPreference       = $valentia.preference.DebugPreference.original;
        debugPreference               = $valentia.preference.DebugPreference.custom;
        originalProgressPreference    = $valentia.preference.ProgressPreference.original;
        progressPreference            = $valentia.preference.ProgressPreference.custom;
        name                          = $valentia.name;
        modulePath                    = $valentia.modulePath;
        helpersPath                   = Join-Path $valentia.modulePath $valentia.helpersPath;
        supportWindows                = $valentia.supportWindows;
        fileEncode                    = $valentia.fileEncode;
        tasks                         = @{};
        includes                      = New-Object System.Collections.Queue;
        Result                        = $valentia.Result;
    }
)

# contains default OS user configuration
$valentia.users = [PSCustomObject]@{
    CurrentUser = $env:USERNAME;
    deployUser = "deployment";
}
$valentia.group = [PSCustomObject]@{
    name = "Administrators";
    userFlag = "0X10040";         # #UserFlag for password (ex. infinity & No change Password)
}

# contains valentia execution policy for initial setup
$valentia.ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]::Bypass

# contains valentia remote invokation authentication mechanism
$valentia.Authentication = [System.Management.Automation.Runspaces.AuthenticationMechanism]::Negotiate

# contains valentia configuration Information
$valentia.PSDrive = "V:";             # Set Valentia Mapping Drive with SMBMapping
$valentia.deployextension = ".ps1";           # contains default DeployGroup file extension

# Define Prefix for Deploy Client NetBIOS name
$valentia.prefix = New-Object psobject -property @{
    hostName = "web";
    ipstring = "ip";
}

# contains default deployment Path configuration.
$valentia.RootPath = "{0}\Deployment" -f $env:SystemDrive;

# Set Valentia Log
$valentia.log = [PSCustomObject]@{
    path      = "{0}\Logs\Deployment" -f $env:SystemDrive;
    name      = "deploy";
    extension = ".log";
    fullPath  = "";
}

# contains certificate configuration
$valentia.certificate = [PSCustomObject]@{
    ThumbPrint = "INPUT THUMBPRINT YOU WANT TO USE"
    CN         = "dsc"                                                                            # cer subject name you want to export from and import to
    FilePath   = @{
        Cert = Join-Path $valentia.appdataconfig.root "\cert\{0}.cer"                  # cer save location
        PFX  = Join-Path $valentia.appdataconfig.root "\cert\{0}.pfx"                  # pfx save location
    }
    export = @{
        CertStoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine  # cer Store Location export from
        CertStoreName     = [System.Security.Cryptography.X509Certificates.StoreName]::My                # cer Store Name export from
        CertType          = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert        # export Type should be cert
        PFXType           = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx         # export Type should be pfx
    }
    import = @{
        CertStoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine  # cer Store Location import to
        CertStoreName     = [System.Security.Cryptography.X509Certificates.StoreName]::My                # cer Store Name import to
    }
    Encrypt = @{
        CertPath   = "Cert:\LocalMachine\My"
        ThumbPrint = "INPUT THUMBPRINT YOU WANT TO USE"
    }
}

# Define External program path
$valentia.fastcopy = [PSCustomObject]@{
    folder = '{0}\lib\FastCopy.2.0.11.0\bin' -f $env:ChocolateyInstall;
    exe    = 'FastCopy.exe';
}

# contains default configuration, can be overriden in ($valentia.defaultconfigurationfile) in directory with valentia.psm1 or in directory with current task script
$valentia.config_default = [PSCustomObject]([ordered]@{
    TaskFileName   = 'default.ps1';
    Result         = $valentia.Result
    TaskFileDir    = [ValentiaBranchPath]::Application;
    taskNameFormat = 'Executing {0}';
    verboseError   = $false;
    modules        = $null;
    PSDrive        = $valentia.PSDrive;
    deployextension= $valentia.deployextension;
    prefix         = $valentia.prefix;
    fastcopy       = $valentia.fastcopy;
    RootPath       = $valentia.RootPath;
    BranchFolder   = [Enum]::GetNames([ValentiaBranchPath]);
    log            = $valentia.log;
})