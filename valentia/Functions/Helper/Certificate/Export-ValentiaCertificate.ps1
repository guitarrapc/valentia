#Requires -Version 3.0

#-- Helper for certificate --#

function Export-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert,

        [parameter(mandatory = $false, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = $false, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$exportFilePath = $valentia.certificate.FilePath.Cert,

        [parameter(mandatory = $false, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509ContentType]$certType = $valentia.certificate.export.CertType
    )
    
    process
    {
        "Export cert '{0}' to '{1}'." -f $cert.ThumbPrint ,$FilePath | Write-ValentiaVerboseDebug
        $certToExportInBytes = $cert.Export($certType)
        [System.IO.File]::WriteAllBytes($FilePath, $certToExportInBytes)
    }

    begin
    {
        "Export Path setup." | Write-ValentiaVerboseDebug
        $FilePath = $exportFilePath -f $CN
        $dir      = Split-Path $FilePath -Parent
        if (-not (Test-Path $dir))
        {
            New-Item -Path $dir -ItemType Directory -Force 
        }
        elseif (Test-Path $FilePath)
        {
            Remove-Item -Path $FilePath -Confirm -Force
        }

        if (Test-Path $FilePath)
        {
            throw "Certificate already exist in '{0}'. Make sure you have delete exist cert before export." -f $FilePath
        }
    }

    end
    {
        Get-Item $FilePath
    }
}