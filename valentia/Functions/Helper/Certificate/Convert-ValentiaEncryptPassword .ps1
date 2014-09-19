#Requires -Version 3.0

#-- Helper for certificate --#

function Convert-ValentiaEncryptPassword 
{
    param
    (
        [parameter(mandatory = 1, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [pscredential[]]$Credential, 

        [parameter(mandatory = 0, position  = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$thumbprint = $valentia.certificate.Encrypt.ThumbPrint, 

        [parameter(mandatory = 0, position  = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$certPath = $valentia.certificate.Encrypt.CertPath
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