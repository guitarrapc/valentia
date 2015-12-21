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
        [parameter(mandatory = $false, position = 0)]
        [string]$configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file),

        [parameter(mandatory = $false, position = 1)]
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
