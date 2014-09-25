#requires -Version 3.0

function Backup-ValentiaConfig
{
<#
.Synopsis
   Backup CurrentConfiguration with timestamp.
.DESCRIPTION
   Backup configuration in $Valentia.appdataconfig.root
.EXAMPLE
   Backup-ValentiaConfig
#>

    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 0,
            position = 0)]
        [System.String]
        $configPath = (Join-Path $Valentia.appdataconfig.root $Valentia.appdataconfig.file),

        [parameter(
            mandatory = 0,
            position = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $encoding = $Valentia.fileEncode
    )

    if (Test-Path $configPath)
    {
        $private:datePrefix = ([System.DateTime]::Now).ToString($valentia.log.dateformat)
        $private:backupConfigName = $datePrefix + "_" + $Valentia.appdataconfig.file
        $private:backupConfigPath = Join-Path $Valentia.appdataconfig.root $backupConfigName

        Write-Verbose ("Backing up config file '{0}' => '{1}'." -f $configPath, $backupConfigPath)
        Get-Content -Path $configPath -Encoding $encoding -Raw | Out-File -FilePath $backupConfigPath -Encoding $encoding -Force 
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'." -f $configPath)
    }
}
