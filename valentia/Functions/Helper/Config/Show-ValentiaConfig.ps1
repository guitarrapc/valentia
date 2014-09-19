#Requires -Version 3.0

<#
.Synopsis
   Show Valentia Config in Console
.DESCRIPTION
   Read config and show in the console
.EXAMPLE
   Show-ValentiaConfig
#>
function Show-ValentiaConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position = 0)]
        [string]$configPath = (Join-Path $valentia.defaultconfiguration.dir $valentia.defaultconfiguration.file),

        [parameter(mandatory = 0, position = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = "default"
    )

    if (Test-Path $configPath)
    {
        Get-Content -Path $configPath -Encoding $encoding
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }
}
