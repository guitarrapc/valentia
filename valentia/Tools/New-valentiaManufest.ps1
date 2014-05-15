$script:module = "valentia"
$script:moduleVersion = "0.3.7"
$script:description = "PowerShell Remote deployment library for Windows Servers";
$script:copyright = "28/June/2013 -"
$script:RequiredModules = @()
$script:clrVersion = "4.0.0.0" # .NET 4.0 with StandAlone Installer "4.0.30319.1008" or "4.0.30319.1" , "4.0.30319.17929" (Win8/2012)
$script:ExportPath = Split-Path $PSCommandPath -Parent

$script:functionToExport = @(
    "ConvertTo-ValentiaTask",
    "Edit-ValentiaConfig",
    "Export-ValentiaCertificate",
    "Export-ValentiaCertificatePFX",
    "Get-ValentiaCertificateFromCert",
    "Get-ValentiaCredential",
    "Get-ValentiaFileEncoding",
    "Get-ValentiaGroup", 
    "Get-ValentiaRebootRequiredStatus",
    "Get-ValentiaTask", 
    "Import-ValentiaCertificate",
    "Import-ValentiaCertificatePFX",
    "Initialize-ValentiaEnvironment",
    "Invoke-Valentia",
    "Invoke-ValentiaAsync",
    "Invoke-ValentiaClean",
    "Invoke-ValentiaCommand",
    "Invoke-ValentiaDeployGroupRemark",
    "Invoke-ValentiaDeployGroupUnremark",
    "Invoke-ValentiaDownload",
    "Invoke-ValentiaSed",
    "Invoke-ValentiaSync",
    "Invoke-ValentiaUpload", 
    "Invoke-ValentiaUploadList", 
    "New-ValentiaGroup",
    "New-ValentiaFolder",
    "New-ValentiaDynamicParamMulti",
    "New-ValentiaOSUser",
    "Ping-ValentiaGroupAsync",
    "Remove-ValentiaCertificate",
    "Remove-ValentiaCertificatePFX",
    "Set-ValentiaCredential", 
    "Set-ValentiaHostName",
    "Set-ValentiaLocation", 
    "Set-ValetntiaWSManConfiguration",
    "Show-ValentiaCertificate",
    "Show-ValentiaConfig",
    "Show-ValentiaGroup",
    "Show-ValentiaPromptForChoice",
    "Write-ValentiaVerboseDebug"
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