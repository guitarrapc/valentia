$script:module = "valentia"
$script:moduleVersion = "0.3.3"
$script:description = "PowerShell Remote deployment library for Windows Servers";
$script:copyright = "28/June/2013 -"
$script:RequiredModules = @()
$script:clrVersion = "4.0.0.0" # .NET 4.0 with StandAlone Installer "4.0.30319.1008" or "4.0.30319.1" , "4.0.30319.17929" (Win8/2012)

$script:functionToExport = @(
        "ConvertTo-ValentiaTask",
        "Edit-ValentiaConfig",
        "Get-ValentiaCredential",
        "Get-ValentiaFileEncoding",
        "Get-ValentiaGroup", 
        "Get-ValentiaRebootRequiredStatus",
        "Get-ValentiaTask", 
        "Initialize-ValentiaEnvironment",
        "Invoke-Valentia",
        "Invoke-ValentiaAsync",
        "Invoke-ValentiaClean",
        "Invoke-ValentiaCommand",
        "Invoke-ValentiaCommandParallel", 
        "Invoke-ValentiaDeployGroupRemark",
        "Invoke-ValentiaDeployGroupUnremark",
        "Invoke-ValentiaDownload",
        "Invoke-ValentiaParallel", 
        "Invoke-ValentiaSync",
        "Invoke-ValentiaUpload", 
        "Invoke-ValentiaUploadList", 
        "New-ValentiaCredential", 
        "New-ValentiaGroup",
        "New-ValentiaFolder",
        "Set-ValentiaHostName",
        "Set-ValentiaLocation", 
        "Show-ValentiaConfig",
        "Show-ValentiaGroup",
        "Show-ValentiaPromptForChoice"
)

$script:variableToExport = "valentia"
$script:AliasesToExport = @("Task",
    "Valep","CommandP",
    "Vale","Command",
    "Valea",
    "Upload","UploadL",
    "Sync",
    "Download",
    "Go",
    "Clean","Reload",
    "Target",
    "ipremark","ipunremark",
    "Cred",
    "Rename",
    "Initial"
)

$script:moduleManufest = @{
    Path = "$module.psd1";
    Author = "guitarrapc";
    CompanyName = "guitarrapc"
    Copyright = ""; 
    ModuleVersion = $moduleVersion
    Description = $description
    PowerShellVersion = "3.0";
    DotNetFrameworkVersion = "4.0";
    ClrVersion = $clrVersion;
    RequiredModules = $RequiredModules;
    RootModule = "$module.psm1";
    CmdletsToExport = "*";
    FunctionsToExport = $functionToExport
    VariablesToExport = $variableToExport;
    AliasesToExport = $AliasesToExport;
}

New-ModuleManifest @moduleManufest