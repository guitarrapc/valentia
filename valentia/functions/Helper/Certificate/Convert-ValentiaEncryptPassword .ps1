#Requires -Version 3.0

#-- Helper for certificate --#

function Convert-ValentiaEncryptPassword 
{
    param
    (
        [parameter(
            mandatory = 1,
            position  = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [pscredential[]]
        $Credential, 

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
            $passwordByte = [Text.Encoding]::UTF8.GetBytes($Cred.GetNetworkCredential().Password) 
            $contentInfo  = New-Object Security.Cryptography.Pkcs.ContentInfo @(,$passwordByte) 
            $EnvelopedCms = New-Object Security.Cryptography.Pkcs.EnvelopedCms $contentInfo
            $EnvelopedCms.Encrypt((New-Object System.Security.Cryptography.Pkcs.CmsRecipient($Cert))) 
            [Convert]::ToBase64String($EnvelopedCms.Encode())
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