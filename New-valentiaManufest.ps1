$script:module = "valentia"
$script:moduleVersion = "0.3.2"
$script:description = "PowerShell Remote deployment library for Windows Servers";
$script:copyright = "28/June/2013 -"
$script:RequiredModules = @()

$script:functionToExport = @("Get-ValentiaTask", 
        "Invoke-ValentiaParallel", 
        "Invoke-ValentiaCommandParallel", 
        "Invoke-Valentia",
        "Invoke-ValentiaCommand",
        "Invoke-ValentiaAsync",
        "Invoke-ValentiaUpload", 
        "Invoke-ValentiaUploadList", 
        "Invoke-ValentiaSync",
        "Invoke-ValentiaDownload",
        "New-ValentiaGroup",
        "Get-ValentiaGroup", 
        "Show-ValentiaGroup", 
        "Invoke-valentiaDeployGroupRemark",
        "Invoke-valentiaDeployGroupUnremark",
        "New-ValentiaCredential", 
        "Get-ValentiaCredential",
        "Set-ValentiaLocation", 
        "Invoke-ValentiaClean",
        "New-ValentiaFolder",
        "Initialize-valentiaEnvironment",
        "Get-ValentiaModuleReload", 
        "Set-ValentiaHostName",
        "Get-ValentiaRebootRequiredStatus"
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
    ClrVersion = "4.0.30319.17929";
    RequiredModules = $RequiredModules;
    RootModule = "$module.psm1";
    CmdletsToExport = "*";
    FunctionsToExport = $functionToExport
    VariablesToExport = $variableToExport;
    AliasesToExport = $AliasesToExport;
}

New-ModuleManifest @moduleManufest