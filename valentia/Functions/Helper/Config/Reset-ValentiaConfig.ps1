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
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position = 0)]
        [string]$configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file),

        [parameter(mandatory = 0, position = 1)]
        [switch]$NoProfile
    )

    if (Test-Path $configPath)
    {
        . $configPath
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }

}
