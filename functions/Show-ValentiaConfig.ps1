function Show-ValentiaConfig
{
<#
.Synopsis
   Show Valentia Config in Console
.DESCRIPTION
   Read config and show in the console
.EXAMPLE
   Show-ValentiaConfig
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
        [ValidateSet("Ascii", "BigEndianUnicode", "Byte", "Default","Oem", "String", "Unicode", "Unknown", "UTF32", "UTF7", "UTF8")]
        [string]
        $encoding = "default"
    )

    if (Test-Path $configName)
    {
        Get-Content -Path $configName -Encoding $encoding
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'.")
    }

}
