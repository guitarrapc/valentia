#Requires -Version 3.0

#-- Helper for certificate --#

function Show-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 0,
            position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CN = $valentia.certificate.CN,

        [parameter(
            mandatory = 0,
            position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]
        $certStoreLocationExport = $valentia.certificate.export.CertStoreLocation,

        [parameter(
            mandatory = 0,
            position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]
        $certStoreNameExport = $valentia.certificate.export.CertStoreName,

        [parameter(
            mandatory = 0,
            position  = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]
        $certStoreLocationImport = $valentia.certificate.import.CertStoreLocation,

        [parameter(
            mandatory = 0,
            position  = 4)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]
        $certStoreNameImport = $valentia.certificate.import.CertStoreName,

        [parameter(
            mandatory = 0,
            position  = 5)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath = $valentia.certificate.FilePath
    )
    
    "Obtain CERT from export CertStoreLocation." | Write-ValentiaVerboseDebug
    $certStoreLocationPathExport = Join-Path "cert:" $certStoreLocationExport -Resolve
    $certStoreFullPathExport = Join-Path $certStoreLocationPathExport $certStoreNameExport -Resolve
    $certExport = (Get-ChildItem $certStoreFullPathExport | where Subject -eq "CN=$cn") | select -First 1
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

    "Export Path setup." | Write-ValentiaVerboseDebug
    $certPath = $FilePath -f $CN
    if (Test-Path $certPath)
    {
        $certFile = Get-Item $certPath
    }
    else
    {
        Write-Warning ("Certificate file not found '{0}'." -f $certPath)
    }

    return [PSCustomObject]@{
        ExportCert = $certExport
        ImportCert = $certImport
        CertFile   = $certFile
    }
}