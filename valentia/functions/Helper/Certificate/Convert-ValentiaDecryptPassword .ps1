#Requires -Version 3.0

#-- Helper for certificate --#

function Convert-ValentiaDecryptPassword 
{
    param
    (
        [parameter(
            mandatory = 1,
            position  = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $EncryptedKey, 

        [parameter(
            mandatory = 0,
            position  = 1,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $thumprint = $valentia.certificate.Encrypt.ThumPrint,

        [parameter(
            mandatory = 0,
            position  = 1,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $certPath = $valentia.certificate.Encrypt.CertPath
    )

    process
    {
        foreach ($cred in $Credential)
        {
            $EnvelopedCms = New-Object Security.Cryptography.Pkcs.EnvelopedCms
            $EnvelopedCms.Decode([convert]::FromBase64String($EncryptedKey))
            $EnvelopedCms.Decrypt($Cert)
            [Text.Encoding]::UTF8.GetString($EnvelopedCms.ContentInfo.Content)
        }
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

        $Path = Join-Path $certPath $thumprint
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