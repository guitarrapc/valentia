function Edit-ValentiaConfig
{
<#
.Synopsis
   Edit Valentia Config in Console
.DESCRIPTION
   Read config and edit in the console
.EXAMPLE
   Edit-ValentiaConfig
#>

    param
    (
        [parameter(
            mandatory = 0,
            position = 0)]
        [string]
        $configName = (Join-Path $valentia.modulePath $valentia.defaultconfigurationfile),

        [parameter(
            mandatory = 0,
            position = 1)]
        [switch]
        $NoProfile
    )

    if (Test-Path $configName)
    {
        if ($NoProfile)
        {
            PowerShell_ise.exe -File $configName
        }
        else
        {
            PowerShell_ise.exe $configName
        }
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'.")
    }

}
