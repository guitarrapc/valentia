#Requires -Version 3.0

#-- Helper for certificate --#

function Show-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $false, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = $false,position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocationExport = $valentia.certificate.export.CertStoreLocation,

        [parameter(mandatory = $false, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreNameExport = $valentia.certificate.export.CertStoreName,

        [parameter(mandatory = $false, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocationImport = $valentia.certificate.import.CertStoreLocation,

        [parameter(mandatory = $false, position  = 4)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreNameImport = $valentia.certificate.import.CertStoreName,

        [parameter(mandatory = $false, position  = 5)]
        [ValidateNotNullOrEmpty()]
        [string]$CertFilePath = $valentia.certificate.FilePath.Cert,

        [parameter(mandatory = $false, position  = 6)]
        [ValidateNotNullOrEmpty()]
        [string]$PFXFilePath = $valentia.certificate.FilePath.PFX
    )
    
    "Obtain CERT from export CertStoreLocation." | Write-ValentiaVerboseDebug
    $certExport = Get-ValentiaCertificateFromCert
    if ($null -eq $certExport)
    {
        Write-Warning ("Certificate for CN '{0}' not found." -f $CN)
    }

    "Obtain CERT from Import CertStoreLocation." | Write-ValentiaVerboseDebug
    $certStoreLocationPathImport= Join-Path "cert:" $certStoreLocationImport -Resolve
    $certStoreFullPathImport = Join-Path $certStoreLocationPathImport $certStoreNameImport -Resolve
    $certImport = (Get-ChildItem $certStoreFullPathImport | where Subject -eq "CN=$cn") | select -First 1
    if ($null -eq $certImport)
    {
        Write-Warning ("Certificate for CN '{0}' not found." -f $CN)
    }

    "Obtain Cer file." | Write-ValentiaVerboseDebug
    $certPath = $CertFilePath -f $CN
    if (Test-Path $certPath)
    {
        $certFile = Get-Item $certPath
    }
    else
    {
        Write-Warning ("Certificate file not found '{0}'." -f $certPath)
    }

    "Obtain PFX file." | Write-ValentiaVerboseDebug
    $pfxPath = $PFXFilePath -f $CN
    if (Test-Path $pfxPath)
    {
        $pfxFile = Get-Item $pfxPath
    }
    else
    {
        Write-Warning ("PFX file not found '{0}'." -f $pfxPath)
    }

    return [PSCustomObject]@{
        ExportCert = $certExport
        ImportCert = $certImport
        CertFile   = $certFile
        PFXFile    = $pfxFile
    }
}