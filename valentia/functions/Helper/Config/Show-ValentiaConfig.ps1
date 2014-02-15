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
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 0,
            position = 0)]
        [string]
        $configPath = (Join-Path $valentia.modulePath $valentia.defaultconfigurationfile),

        [parameter(
            mandatory = 0,
            position = 1)]
        [ValidateSet("Ascii", "BigEndianUnicode", "Byte", "Default","Oem", "String", "Unicode", "Unknown", "UTF32", "UTF7", "UTF8")]
        [string]
        $encoding = "default"
    )

    if (Test-Path $configPath)
    {
        Get-Content -Path $configPath -Encoding $encoding
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'." -f $configPath)
    }

}
