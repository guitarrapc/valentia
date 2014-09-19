#Requires -Version 3.0

#-- Helper for certificate --#

function Get-ValentiaCertificateFromCert
{
    [CmdletBinding()]
    param
    (       
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocation = $valentia.certificate.export.CertStoreLocation,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreName = $valentia.certificate.export.CertStoreName
    )
    
    "Obtain Cert from CertStoreLocation." | Write-ValentiaVerboseDebug
    $certStoreLocationPath = Join-Path "cert:" $certStoreLocation -Resolve
    $certStoreFullPath = Join-Path $certStoreLocationPath $certStoreName -Resolve
    $cert = (Get-ChildItem $certStoreFullPath | where Subject -eq "CN=$cn") | select -First 1
    if ($null -eq $cert)
    {
        throw "Certificate for CN '{0}' not found." -f $CN
    }

    return [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
}