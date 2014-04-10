#Requires -Version 3.0

#-- Helper for certificate --#

function Export-ValentiaCertificate
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
        $certStoreLocation = $valentia.certificate.export.CertStoreLocation,

        [parameter(
            mandatory = 0,
            position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]
        $certStoreName = $valentia.certificate.export.CertStoreName,

        [parameter(
            mandatory = 0,
            position  = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        $exportFilePath = $valentia.certificate.FilePath,

        [parameter(
            mandatory = 0,
            position  = 4)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509ContentType]
        $type = $valentia.certificate.export.Type
    )
    
    begin
    {
        "Obtain CERT from CertStoreLocation." | Write-ValentiaVerboseDebug
        $certStoreLocationPath = Join-Path "cert:" $certStoreLocation -Resolve
        $certStoreFullPath = Join-Path $certStoreLocationPath $certStoreName -Resolve
        $cert = (Get-ChildItem $certStoreFullPath | where Subject -eq "CN=$cn") | select -First 1
        if ($null -eq $cert)
        {
            throw "Certificate for CN '{0}' not found." -f $CN
        }

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
    }

    process
    {
        if (Test-Path $FilePath)
        {
            throw "Certificate already exist in '{0}'. Make sure you have delete exist cert before export." -f $FilePath
        }
        else
        {
            "Export cert '{0}' to '{1}'." -f $cert.ThumbPrint ,$FilePath | Write-ValentiaVerboseDebug
            $certToExportInBytes = $cert.Export($type)
            [System.IO.File]::WriteAllBytes($FilePath, $certToExportInBytes)
        }
    }
}