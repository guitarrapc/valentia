function CombineMultipleFileToSingle ([string]$InputRootPath, [string]$OutputPath, $Encoding)
{
    try
    {
        $sb = New-Object System.Text.StringBuilder
        $sw = New-Object System.IO.StreamWriter ($OutputPath, $false, [System.Text.Encoding]::$Encoding)

        # Read All functions
        Get-ChildItem $InputRootPath -Recurse -File `
        | Where-Object { -not ($_.FullName.Contains('.Tests.')) } `
        | Where-Object Extension -eq '.ps1' `
        | ForEach-Object {
            $sb.Append((Get-Content -Path $_.FullName -Raw -Encoding utf8)) > $null
            $sb.AppendLine() > $null
            $footer = '# file loaded from path : {0}' -f $_.FullName
            $sb.Append($footer) > $null
            $sb.AppendLine() > $null
            $sb.AppendLine() > $null
        }
    
        # Output into single file
        $sw.Write($sb.ToString());
    }
    finally
    {
        # Dispose and release file handler
        $sb = $null
        $sw.Dispose()
    }
}

$Script:valentia = [ordered]@{}
$valentia.name = 'valentia'
$valentia.ExportPath = Split-Path $PSCommandPath -Parent
$valentia.modulePath = Split-Path -parent $valentia.ExportPath
$valentia.helpersPath = '\functions\'
$valentia.typePath = '\type'
$valentia.combineTempfunction = '{0}.ps1' -f $valentia.name
$valentia.combineTemptype = 'Type.ps1'
$valentia.fileEncode = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]'utf8'

$valentia.moduleVersion = "0.4.7"
$valentia.description = "PowerShell Remote deployment library for Windows Servers";
$valentia.copyright = "28/June/2013 -"
$valentia.RequiredModules = @()
$valentia.clrVersion = "4.0.0.0" # .NET 4.0 with StandAlone Installer "4.0.30319.1008" or "4.0.30319.1" , "4.0.30319.17929" (Win8/2012)

$valentia.functionToExport = @(

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

        # ACL
        "Get-ValentiaACL",
        "Set-ValentiaACL",
        "Test-ValentiaACL",

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
        "Backup-ValentiaConfig",
        "Edit-ValentiaConfig",
        'Reset-ValentiaConfig',
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

        # ScheduledTask
        'Disable-ValentiaScheduledTaskLogSetting',
        'Enable-ValentiaScheduledTaskLogSetting',
        'Remove-ValentiaScheduledTask',
        'Remove-ValentiaScheduledTaskEmptyDirectoryPath',
        'Set-ValentiaScheduledTask',

        # Sed
        "Invoke-ValentiaSed",

        # SymbolicLink
        'Get-ValentiaSymbolicLink',
        'Remove-ValentiaSymbolicLink',
        'Set-ValentiaSymbolicLink',

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
    Path = "{0}.psd1" -f $valentia.name
    Author = "guitarrapc";
    CompanyName = "guitarrapc"
    Copyright = ""; 
    ModuleVersion = $valentia.moduleVersion
    Description = $valentia.description
    PowerShellVersion = "3.0";
    DotNetFrameworkVersion = "4.0";
    ClrVersion = $valentia.clrVersion;
    RequiredModules = $valentia.RequiredModules;
    NestedModules = "{0}.psm1" -f $valentia.name;
    CmdletsToExport = "*";
    FunctionsToExport = $valentia.functionToExport
    VariablesToExport = $valentia.variableToExport;
    AliasesToExport = $valentia.AliasesToExport;
}

New-ModuleManifest @moduleManufest

# As Installer place on ModuleName\Tools.
$psd1 = Join-Path $valentia.ExportPath ("{0}.psd1" -f $valentia.name);
$newpsd1 = Join-Path $valentia.ModulePath ("{0}.psd1" -f $valentia.name);
if (Test-Path -Path $psd1)
{
    Get-Content -Path $psd1 -Encoding UTF8 -Raw -Force | Out-File -FilePath $newpsd1 -Encoding default -Force
    Remove-Item -Path $psd1 -Force
}

# Combine all types into single .ps1
$outputPath = Join-Path $valentia.modulePath $valentia.combineTemptype
$InputRootPath = (Join-Path $valentia.modulePath $valentia.typePath)
if(Test-Path $outputPath){ Remove-Item -Path $outputPath -Force }
CombineMultipleFileToSingle -InputRootPath $InputRootPath -OutputPath $outputPath -Encoding UTF8

# Combine all functions into single .ps1
$outputPath = Join-Path $valentia.modulePath $valentia.combineTempfunction
$InputRootPath = (Join-Path $valentia.modulePath $valentia.helpersPath)
if(Test-Path $outputPath){ Remove-Item -Path $outputPath -Force }
CombineMultipleFileToSingle -InputRootPath $InputRootPath -OutputPath $outputPath -Encoding UTF8