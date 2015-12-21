#Requires -Version 3.0

#-- Helper for certificate --#

function Convert-ValentiaDecryptPassword 
{
    param
    (
        [parameter(mandatory = $true, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptedKey, 

        [parameter(mandatory = $false, position  = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$thumbprint = $valentia.certificate.Encrypt.ThumbPrint,

        [parameter(mandatory = $false, position  = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$certPath = $valentia.certificate.Encrypt.CertPath
    )

    process
    {
        $EnvelopedCms = New-Object Security.Cryptography.Pkcs.EnvelopedCms
        $EnvelopedCms.Decode([convert]::FromBase64String($EncryptedKey))
        $EnvelopedCms.Decrypt($Cert)
        [Text.Encoding]::UTF8.GetString($EnvelopedCms.ContentInfo.Content)
    }

    begin
    {
        try
        {
            Add-type –AssemblyName System.Security
        }
        catch
        {
        }

        $Path = Join-Path $certPath $thumbprint
        if (Test-Path $Path)
        {
            $Cert = Get-Item $Path
        }
        else
        {
            Write-Warning ("Certification not found exception!! Cert: '{0}'" -f $Path)
        }
    }
}