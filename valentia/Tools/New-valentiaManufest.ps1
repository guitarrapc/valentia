$script:module = "valentia"
$script:moduleVersion = "0.4.5"
$script:description = "PowerShell Remote deployment library for Windows Servers";
$script:copyright = "28/June/2013 -"
$script:RequiredModules = @()
$script:clrVersion = "4.0.0.0" # .NET 4.0 with StandAlone Installer "4.0.30319.1008" or "4.0.30319.1" , "4.0.30319.17929" (Win8/2012)
$script:ExportPath = Split-Path $PSCommandPath -Parent

$script:functionToExport = @(

    # Invokation
        # Invoke job
        "Invoke-Valentia",

        # Invoke RunSpacePool
        "Invoke-ValentiaAsync",

        # Download
        "Invoke-ValentiaDownload",

        # Ping
        "Ping-ValentiaGroupAsync",
        'Watch-ValentiaPingAsyncReplyStatus',

        # Sync
        "Invoke-ValentiaSync",

        # Upload
        "Invoke-ValentiaUpload", 
        "Invoke-ValentiaUploadList", 

    # Helper
        # Certificate
        "Convert-ValentiaDecryptPassword",
        "Convert-ValentiaEncryptPassword",
        "Export-ValentiaCertificate",
        "Export-ValentiaCertificatePFX",
        "Get-ValentiaCertificateFromCert",
        "Import-ValentiaCertificate",
        "Import-ValentiaCertificatePFX",
        "Remove-ValentiaCertificate",
        "Remove-ValentiaCertificatePFX",
        "Show-ValentiaCertificate",

        # CleanupVariables
        "Invoke-ValentiaClean",

        # ComputerName
        'Get-ValentiaComputerName',
        'Rename-ValentiaComputerName',

        # Config
        "Edit-ValentiaConfig",
        "Show-ValentiaConfig",

        # Credential
        "Get-ValentiaCredential",
        "Set-ValentiaCredential", 

        # DNS
        'Get-ValentiaHostEntryAsync',

        # DynamicParam
        "New-ValentiaDynamicParamMulti",

        # Encoding
        "Get-ValentiaFileEncoding",

        # Folder
        "New-ValentiaFolder",

        # Group
        "Get-ValentiaGroup", 
        "Invoke-ValentiaDeployGroupRemark",
        "Invoke-ValentiaDeployGroupUnremark",
        "New-ValentiaGroup",
        "Show-ValentiaGroup",

        # Initialize
        "Initialize-ValentiaEnvironment",

        # Location
        "Set-ValentiaLocation", 

        # Log
        'New-ValentiaLog',

        # PromptForChoice
        "Show-ValentiaPromptForChoice",

        # Sed
        "Invoke-ValentiaSed",

        # Task
        "ConvertTo-ValentiaTask",
        "Get-ValentiaTask", 

        # User
        "New-ValentiaOSUser",

        # Windows
        "Get-ValentiaRebootRequiredStatus",
        "Set-ValetntiaWSManConfiguration"
)

$script:variableToExport = "valentia"
$script:AliasesToExport = @(
    "Task",
    "Vale",
    "Valea",
    "Upload","UploadL",
    "Sync",
    "Download",
    "Go",
    "Clean","Reload",
    "Target","PingAsync","Sed",
    "ipremark","ipunremark",
    "Cred",
    "Rename",
    "DynamicParameter",
    "Initial"
)

$script:moduleManufest = @{
    Path = "{0}\{1}.psd1" -f $ExportPath, $module
    Author = "guitarrapc";
    CompanyName = "guitarrapc"
    Copyright = ""; 
    ModuleVersion = $moduleVersion
    Description = $description
    PowerShellVersion = "3.0";
    DotNetFrameworkVersion = "4.0";
    ClrVersion = $clrVersion;
    RequiredModules = $RequiredModules;
    NestedModules = "$module.psm1";
    CmdletsToExport = "*";
    FunctionsToExport = $functionToExport
    VariablesToExport = $variableToExport;
    AliasesToExport = $AliasesToExport;
}

New-ModuleManifest @moduleManufest

# As Installer place on ModuleName\Tools.
$psd1 = "$module.psd1"
if (Test-Path -Path $psd1)
{
    Get-Content -Path ".\$psd1" -Encoding UTF8 -Raw -Force | Out-File -FilePath "..\$psd1" -Encoding default -Force
    Remove-Item -Path ".\$psd1" -Force
}