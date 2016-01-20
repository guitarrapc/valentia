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
            $rootPath = $valentia.appdataconfig.root
            $fileName = $valentia.appdataconfig.file
        }
        elseif (Test-Path (Join-Path $valentia.originalconfig.root $valentia.originalconfig.file))
        {
            $configPath = (Join-Path $valentia.originalconfig.root $valentia.originalconfig.file)
            $rootPath = $valentia.originalconfig.root
            $fileName = $valentia.originalconfig.file
        }
    }

    if (Test-Path $configPath)
    {
        $private:datePrefix = ([System.DateTime]::Now).ToString($valentia.log.dateformat)
        $private:backupConfigName = $datePrefix + "_" + $fileName
        $private:backupConfigPath = Join-Path $rootPath $backupConfigName

        Write-Verbose ("Backing up config file '{0}' => '{1}'." -f $configPath, $backupConfigPath)
        Get-Content -Path $configPath -Encoding $encoding -Raw | Out-File -FilePath $backupConfigPath -Encoding $encoding -Force 
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'." -f $configPath)
    }
}
