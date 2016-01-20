#Requires -Version 3.0

<#
.Synopsis
   Edit Valentia Config in Console
.DESCRIPTION
   Read config and edit in the console
.EXAMPLE
   Edit-ValentiaConfig
#>
function Reset-ValentiaConfig
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $false, position = 0)]
        [string]$configPath = "",

        [parameter(mandatory = $false, position = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $Valentia.fileEncode
    )

    if (($configPath -eq "") -or (-not (Test-Path $configPath)))
    {
        if (Test-Path (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file))
        {
            $configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file)
        }
        elseif (Test-Path (Join-Path $valentia.originalconfig.root $valentia.originalconfig.file))
        {
            $configPath = (Join-Path $valentia.originalconfig.root $valentia.originalconfig.file)
        }
    }

    if (Test-Path $configPath)
    {
        . $configPath
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }

}
