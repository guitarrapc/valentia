#Requires -Version 3.0

<#
.SYNOPSIS 
Get ACL from selected source path.

.DESCRIPTION
You can get ACL information from selected source path.
This is same logic as gACLResource. 

.NOTES
Author: guitarrapc
Created: 3/Sep/2014

.EXAMPLE
Get-ValentiaACL -Path c:\Deployment -Account Users
--------------------------------------------
Get ACL Information from c:\Deployment for user "Users", means no Computer/Domain user name checking.

.EXAMPLE
Get-ValentiaACL -Path c:\Deployment -Account contoso\John
--------------------------------------------
Get ACL Information from c:\Deployment for user "contoso\John", means strict user name checking.

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Get-ValentiaACL
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = 1, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory = 1, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(Mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure = "Present",
        
        [Parameter(Mandatory = 0, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(Mandatory = 0, position = 5)]
        [Bool]$Inherit = $false,

        [Parameter(Mandatory = 0, position = 6)]
        [Bool]$Recurse = $false,

        [Parameter(Mandatory = 0, position = 7)]
        [Bool]$Strict = $false
    )

    $desiredRule = GetDesiredRule -Path $Path -Account $Account -Rights $Rights -Access $Access -Inherit $Inherit -Recurse $Recurse
    $currentACL = (Get-Item $Path).GetAccessControl("Access")
    $currentRules = $currentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $match = IsDesiredRuleAndCurrentRuleSame -DesiredRule $desiredRule -CurrentRules $currentRules -Strict $Strict
    
    $presence = if ($true -eq $match)
    {
        "Present"
    }
    else
    {
        "Absent"
    }

    return @{
        Ensure    = $presence
        Path      = $Path
        Account   = $Account
        Rights    = $Rights
        Access    = $Access
        Inherit   = $Inherit
        Recurse   = $Recurse
    }
}
# file loaded from path : \functions\Helper\ACL\Get-ValentiaACL.ps1

#Requires -Version 3.0

<#
.SYNOPSIS 
Set ACL from selected source path.

.DESCRIPTION
You can Set ACL information to selected source path.
This is same logic as gACLResource. 

.NOTES
Author: guitarrapc
Created: 3/Sep/2014

.EXAMPLE
Set-ValentiaACL -Path c:\Deployment -Account Users -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
Add FullControl to the c:\Deployment for user "Users", means no Computer/Domain user name checking.

.EXAMPLE
Set-ValentiaACL -Path c:\Deployment -Account contoso\John -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
Add FullControl to the c:\Deployment for user "BuiltIn\Users", means strict user name checking.

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Set-ValentiaACL
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = 1, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory = 1, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(Mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure = "Present",
        
        [Parameter(Mandatory = 0, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(Mandatory = 0, position = 5)]
        [Bool]$Inherit = $false,

        [Parameter(Mandatory = 0, position = 6)]
        [Bool]$Recurse = $false,

        [Parameter(Mandatory = 0, position = 7)]
        [Bool]$Strict = $false
    )

    $desiredRule = GetDesiredRule -Path $Path -Account $Account -Rights $Rights -Access $Access -Inherit $Inherit -Recurse $Recurse
    $currentACL = (Get-Item $Path).GetAccessControl("Access")
    $currentRules = $currentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $match = IsDesiredRuleAndCurrentRuleSame -DesiredRule $desiredRule -CurrentRules $currentRules -Strict $Strict

    if ($Ensure -eq "Present")
    {
        $CurrentACL.AddAccessRule($DesiredRule)
        $CurrentACL | Set-Acl -Path $Path 
    }
    elseif ($Ensure -eq "Absent")
    {
        $CurrentACL.RemoveAccessRule($DesiredRule) > $null
        $CurrentACL | Set-Acl -Path $Path 
    }
}
# file loaded from path : \functions\Helper\ACL\Set-ValentiaACL.ps1

#Requires -Version 3.0

<#
.SYNOPSIS 
Test ACL from selected source path.

.DESCRIPTION
You can Test ACL information to selected source path.
This is same logic as gACLResource. 

.NOTES
Author: guitarrapc
Created: 3/Sep/2014

.EXAMPLE
Test-ValentiaACL -Path c:\Deployment -Account Users -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
TestACL to the c:\Deployment for user "Users", means no Computer/Domain user name checking.

.EXAMPLE
Test-ValentiaACL -Path c:\Deployment -Account contoso\John -Rights Modify -Ensure Present -Access Allow -Inherit $false -Recurse $false
--------------------------------------------
TestACL to the c:\Deployment for user "contoso\John", means strict user name checking.

.ExternalHelp "https://github.com/guitarrapc/DSCResources/tree/master/Custom/gACLResource"
#>
function Test-ValentiaACL
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = 1, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory = 1, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(Mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0, position = 3)]
        [ValidateSet("Present", "Absent")]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure = "Present",
        
        [Parameter(Mandatory = 0, position = 4)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Allow", "Deny")]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(Mandatory = 0, position = 5)]
        [Bool]$Inherit = $false,

        [Parameter(Mandatory = 0, position = 6)]
        [Bool]$Recurse = $false,

        [Parameter(Mandatory = 0, position = 7)]
        [Bool]$Strict = $false
    )

    $desiredRule = GetDesiredRule -Path $Path -Account $Account -Rights $Rights -Access $Access -Inherit $Inherit -Recurse $Recurse
    $currentACL = (Get-Item $Path).GetAccessControl("Access")
    $currentRules = $currentACL.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
    $match = IsDesiredRuleAndCurrentRuleSame -DesiredRule $desiredRule -CurrentRules $currentRules -Strict $Strict
    
    $presence = if ($true -eq $match)
    {
        "Present"
    }
    else
    {
        "Absent"
    }
    return $presence -eq $Ensure
}
# file loaded from path : \functions\Helper\ACL\Test-ValentiaACL.ps1

#Requires -Version 3.0

function GetDesiredRule
{
    [OutputType([System.Security.AccessControl.FileSystemAccessRule])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Account,

        [Parameter(Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.FileSystemRights]$Rights = "ReadAndExecute",

        [Parameter(Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]$Access = "Allow",

        [Parameter(Mandatory = 0)]
        [Bool]$Inherit = $false,

        [Parameter(Mandatory = 0)]
        [Bool]$Recurse = $false
    )

    $InheritFlag = if ($Inherit)
    {
        "{0}, {1}" -f [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    elseif ($Recurse)
    {
        "{0}, {1}" -f [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    else
    {
        [System.Security.AccessControl.InheritanceFlags]::None
    }

    $desiredRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Account, $Rights, $InheritFlag, "None", $Access)
    return $desiredRule
}

# file loaded from path : \functions\Helper\ACL\Private\GetDesiredRule.ps1

#Requires -Version 3.0

function IsDesiredRuleAndCurrentRuleSame
{
    [OutputType([Bool])]
    [CmdletBinding()]
    param
    (
        [System.Security.AccessControl.FileSystemAccessRule]$DesiredRule,
        [System.Security.AccessControl.AuthorizationRuleCollection]$CurrentRules,
        [bool]$Strict
    )

    $match = if ($Strict)
    {
        Write-Verbose "Using strict name checking. It does not split AccountName with \''."
        $currentRules `
        | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} `
        | where FileSystemRights -eq $DesiredRule.FileSystemRights `
        | where AccessControlType -eq $DesiredRule.AccessControlType `
        | where Inherit -eq $_.InheritanceFlags `
        | measure
    }
    else
    {
        Write-Verbose "Using non-strict name checking. It split AccountName with \''."
        $currentRules `
        | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} `
        | where FileSystemRights -eq $DesiredRule.FileSystemRights `
        | where AccessControlType -eq $DesiredRule.AccessControlType `
        | where Inherit -eq $_.InheritanceFlags `
        | measure
    }

    if ($match.Count -eq 0)
    {
        Write-Verbose "Current ACL result."
        Write-Verbose ($CurrentRules | Format-List | Out-String)


        Write-Verbose "Desired ACL result."
        Write-Verbose ($DesiredRule | Format-List | Out-String)

        Write-Verbose "Result does not match as desired. Showing Desired v.s. Current Status."
        [PSCustomObject]@{
            DesiredRuleIdentity = $DesiredRule.IdentityReference.Value
            CurrentRuleIdentity = $currentRules.IdentityReference.Value
            StrictCurrentRuleIdentity = $currentRules.IdentityReference.Value.Split("\")[1]
            StrictResult = ($currentRules | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} | measure).Count -ne 0
            NoneStrictResult = ($currentRules | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} | measure).Count -ne 0
        } | Format-List | Out-String -Stream | Write-Verbose

        [PSCustomObject]@{
            DesiredFileSystemRights = $DesiredRule.FileSystemRights
            CurrentFileSystemRights = $currentRules.FileSystemRights
            StrictResult = ($currentRules | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | measure).Count -ne 0
            NoneStrictResult = ($currentRules | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | measure).Count -ne 0
        } | Format-List | Out-String -Stream | Write-Verbose

        [PSCustomObject]@{
            DesiredAccessControlType = $DesiredRule.AccessControlType
            CurrentAccessControlType = $currentRules.AccessControlType
            StrictResult = ($currentRules | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | where AccessControlType -eq $DesiredRule.AccessControlType | measure).Count -ne 0
            NoneStrictResult = ($currentRules | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | where AccessControlType -eq $DesiredRule.AccessControlType | measure).Count -ne 0
        } | Format-List | Out-String -Stream | Write-Verbose

        [PSCustomObject]@{
            DesiredInherit = $DesiredRule.Inherit
            CurrentInherit = $currentRules.Inherit
            StrictResult = ($currentRules | where {$_.IdentityReference.Value -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | where AccessControlType -eq $DesiredRule.AccessControlType | where Inherit -eq $DesiredRule.Inherit | measure).Count -ne 0
            NoneStrictResult = ($currentRules | where {$_.IdentityReference.Value.Split("\")[1] -eq $DesiredRule.IdentityReference.Value} | where FileSystemRights -eq $DesiredRule.FileSystemRights | where AccessControlType -eq $DesiredRule.AccessControlType | where Inherit -eq $DesiredRule.Inherit | measure).Count -ne 0
        } | Format-List | Out-String -Stream | Write-Verbose
    }

    return $match.Count -ge 1
}

# file loaded from path : \functions\Helper\ACL\Private\IsDesiredRuleAndCurrentRuleSame.ps1

#Requires -Version 3.0

function Add-ValentiaTypeMemberDefinition
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = 1, position = 0)]
        [string]$MemberDefinition,

        [Parameter(mandatory = 1, position = 1)]
        [string]$NameSpace,

        [Parameter(mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(mandatory = 0, position = 3)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UsingNameSpace,

        [Parameter(mandatory = 0, position = 4)]
        [switch]$PassThru
    )

    $private:guid = [Guid]::NewGuid().ToString().Replace("-", "_")
    $private:addType = @{
        MemberDefinition = $MemberDefinition
        Namespace        = $NameSpace 
        Name             = $Name + $guid
    }

    if (($UsingNameSpace | measure).Count -ne 0)
    {
        $addType.UsingNameSpace = $UsingNameSpace
    }

    $private:result = Add-Type @addType -PassThru
    if ($PassThru)
    {
        return $result
    }
}
# file loaded from path : \functions\Helper\Add-Memeber\Private\Add-ValentiaTypeMemberDefinition.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Convert-ValentiaDecryptPassword 
{
    param
    (
        [parameter(mandatory = 1, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptedKey, 

        [parameter(mandatory = 0, position  = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$thumbprint = $valentia.certificate.Encrypt.ThumbPrint,

        [parameter(mandatory = 0, position  = 1, ValueFromPipelineByPropertyName = 1)]
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
# file loaded from path : \functions\Helper\Certificate\Convert-ValentiaDecryptPassword .ps1

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
# file loaded from path : \functions\Helper\Certificate\Convert-ValentiaEncryptPassword .ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Export-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert,

        [parameter(mandatory = 0, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$exportFilePath = $valentia.certificate.FilePath.Cert,

        [parameter(mandatory = 0, position  = 3)]
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
# file loaded from path : \functions\Helper\Certificate\Export-ValentiaCertificate.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Export-ValentiaCertificatePFX
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$pfx,

        [parameter(mandatory = 0, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$exportFilePath = $valentia.certificate.FilePath.PFX,
        
        [parameter(mandatory = 0, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509ContentType]$PFXType = $valentia.certificate.export.PFXType,

        [parameter(mandatory = 0, position  = 4)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential = $null
    )
    
    process
    {
        "Export pfx '{0}' as object." -f $cert.ThumbPrint | Write-ValentiaVerboseDebug
        $pfxToExportInBytes = $pfx.Export($PFXType, $credential.GetNetworkCredential().Password)
        [System.IO.File]::WriteAllBytes($FilePath, $pfxToExportInBytes)
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

        "Get pfx password to export." | Write-ValentiaVerboseDebug
        if ($null -eq $Credential)
        {
            $credential = Get-Credential -Credential "INPUT Password FOR PFX export."
        }

        if (Test-Path $FilePath)
        {
            throw "Certificate already exist in '{0}'. Make sure you have delete exist cert before export." -f $FilePath
        }
    }
}
# file loaded from path : \functions\Helper\Certificate\Export-ValentiaCertificatePFX.ps1

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
# file loaded from path : \functions\Helper\Certificate\Get-ValentiaCertificateFromCert.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Import-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,
        
        [parameter(mandatory = 0, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocation = $valentia.certificate.import.CertStoreLocation,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreName = $valentia.certificate.import.CertStoreName,

        [parameter(mandatory = 0, position  = 3, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$importFilePath = $valentia.certificate.FilePath.Cert
    )
    
    process
    {
        try
        {
            "Import certificate '{0}' to CertStore '{1}'" -f $FilePath, (Get-Item ("cert:{0}\{1}" -f $certStore.Location, $certStore.Name)).PSPath | Write-ValentiaVerboseDebug
            $CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed)
            $CertStore.Add($CertToImport)
        }
        finally
        {
            $CertStore.Close()
        }
    }

    begin
    {
        "obtain cert." | Write-ValentiaVerboseDebug
        $FilePath = ($importFilePath -f $CN)
        if (-not (Test-Path $FilePath))
        {
            throw "Certificate not found in '{0}'. Make sure you have been already exported." -f $FilePath
        }

        if ($certStoreLocation -eq [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        {
            if(-not(Test-ValentiaPowerShellElevated))
            {
                throw "Your PowerShell Console is not elevated! Must start PowerShell as an elevated to run this function because of UAC."
            }
            else
            {
                "Current session is already elevated, continue setup environment." | Write-ValentiaVerboseDebug
            }
        }

        "Cert identification." | Write-ValentiaVerboseDebug
        $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
        $CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $FilePath, "", $flags
        $CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $CertStoreLocation
    }
}
# file loaded from path : \functions\Helper\Certificate\Import-ValentiaCertificate.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Import-ValentiaCertificatePFX
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocation = $valentia.certificate.import.CertStoreLocation,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreName = $valentia.certificate.import.CertStoreName,

        [parameter(mandatory = 0, position  = 3, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$importFilePath = $valentia.certificate.FilePath.PFX,

        [parameter(mandatory = 0, position  = 4)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential = $null
    )
    
    process
    {
        try
        {
            "Import certificate PFX '{0}' to CertStore '{1}'" -f $FilePath, (Get-Item ("cert:{0}\{1}" -f $certStore.Location, $certStore.Name)).PSPath | Write-ValentiaVerboseDebug
            $PFXStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed)
            $PFXStore.Add($PFXToImport)
        }
        finally
        {
            $PFXStore.Close()
        }
    }

    begin
    {
        "obtain pfx." | Write-ValentiaVerboseDebug
        $FilePath = ($importFilePath -f $CN)
        if (-not (Test-Path $FilePath))
        {
            throw "Certificate not found in '{0}'. Make sure you have been already exported." -f $FilePath
        }

        if ($certStoreLocation -eq [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        {
            if(-not(Test-ValentiaPowerShellElevated))
            {
                throw "Your PowerShell Console is not elevated! Must start PowerShell as an elevated to run this function because of UAC."
            }
            else
            {
                "Current session is already elevated, continue setup environment." | Write-ValentiaVerboseDebug
            }
        }

        "Get pfx password to export." | Write-ValentiaVerboseDebug
        if ($null -eq $Credential)
        {
            $credential = Get-Credential -Credential "INPUT Password FOR PFX export."
        }

        "PFX identification." | Write-ValentiaVerboseDebug
        $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
        $PFXToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $FilePath, $credential.GetNetworkCredential().Password, $flags
        $PFXStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $CertStoreLocation
    }
}
# file loaded from path : \functions\Helper\Certificate\Import-ValentiaCertificatePFX.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Remove-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$CertFilePath = $valentia.certificate.FilePath.Cert,

        [parameter(mandatory = 0, position  = 2)]
        [switch]$force = $false
    )
    
    $param = @{
        Path    = $CertFilePath -f $CN
        Confirm = (-not $force)
        Force   = $force
    }
    if (Test-Path $param.Path)
    {
        Remove-Item @param
    }
}
# file loaded from path : \functions\Helper\Certificate\Remove-ValentiaCertificate.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Remove-ValentiaCertificatePFX
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0, position  = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$PFXFilePath = $valentia.certificate.FilePath.PFX,

        [parameter(mandatory = 0, position  = 2)]
        [switch]$force = $false
    )
    
    $param = @{
        Path    = $PFXFilePath -f $CN
        Confirm = (-not $force)
        Force   = $force
    }
    if (Test-Path $param.Path)
    {
        Remove-Item @param
    }
}
# file loaded from path : \functions\Helper\Certificate\Remove-ValentiaCertificatePFX.ps1

#Requires -Version 3.0

#-- Helper for certificate --#

function Show-ValentiaCertificate
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CN = $valentia.certificate.CN,

        [parameter(mandatory = 0,position  = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocationExport = $valentia.certificate.export.CertStoreLocation,

        [parameter(mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreNameExport = $valentia.certificate.export.CertStoreName,

        [parameter(mandatory = 0, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreLocation]$certStoreLocationImport = $valentia.certificate.import.CertStoreLocation,

        [parameter(mandatory = 0, position  = 4)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.StoreName]$certStoreNameImport = $valentia.certificate.import.CertStoreName,

        [parameter(mandatory = 0, position  = 5)]
        [ValidateNotNullOrEmpty()]
        [string]$CertFilePath = $valentia.certificate.FilePath.Cert,

        [parameter(mandatory = 0, position  = 6)]
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
# file loaded from path : \functions\Helper\Certificate\Show-ValentiaCertificate.ps1

#Requires -Version 3.0

#-- Helper for valentia --#

# clean
<#
.SYNOPSIS 
Clean up valentia task variables.

.DESCRIPTION
Clear valentia variables for each task, and remove then.
valentia only keep default variables after this cmdlet has been run.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
Invoke-ValentiaClean
--------------------------------------------
Clean up valentia variables stacked in the $valentia variables.
#>
function Invoke-ValentiaClean
{
    [CmdletBinding()]
    param
    (
    )

    if ($valentia.context.Count -gt 0) 
    {
        $currentContext = $valentia.context.Peek()
        $env:path = $currentContext.originalEnvPath
        Set-Location $currentContext.originalDirectory
        $global:ErrorActionPreference = $currentContext.originalErrorActionPreference

        # Erase Context
        [void] $valentia.context.Clear()
    }
}

# file loaded from path : \functions\Helper\CleanupVariables\Invoke-ValentiaClean.ps1

#Requires -Version 3.0

#-- Helper for valentia --#

# cleanResult
<#
.SYNOPSIS 
Clean up valentia task previous result.

.DESCRIPTION
Clear valentia last result.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
Invoke-ValentiaCleanResult
#>
function Invoke-ValentiaCleanResult
{
    [CmdletBinding()]
    param
    (
    )

    $valentia.Result = [ordered]@{
        SuccessStatus         = @()
        TimeStart             = [datetime]::Now.DateTime
        ScriptToRun           = ""
        DeployMembers         = @()
        Result                = New-Object 'System.Collections.Generic.List[PSCustomObject]'
        ErrorMessageDetail    = @()
    }
}

# file loaded from path : \functions\Helper\CleanupVariables\Invoke-ValentiaCleanResult.ps1

#Requires -Version 3.0

function Get-ValentiaComputerName
{
    [CmdletBinding(DefaultParameterSetName = 'Registry')]
    param
    (
        [parameter(Mandatory = 0, Position  = 0, ParameterSetName = "Registry")]
        [switch]$Registry,

        [parameter(Mandatory = 0, Position  = 0, ParameterSetName = "DotNet")]
        [switch]$DotNet
    )
   
    end
    {
        if ($DotNet)
        {
            Write-Verbose "Objain Host Names from Syste.Net.DSC."
            $hostByName = [System.Net.DNS]::GetHostByName('')
            [PSCustomObject]@{
                HostaName = $hostByName.HostName
                IPAddress = $hostByName.AddressList
            }
        }
        else
        {
            $RegistryParam.GetEnumerator() | %{CheckItemProperty -BasePath $_.BasePath -name $_.Name}
        }
    }

    begin
    {
        Set-StrictMode -Version Latest

        # HostName from Refistry
        Write-Verbose "Obtain Host Names from Registry Keys."
        $HKLMComputerName = "registry::HKLM\SYSTEM\CurrentControlSet\Control\Computername"
        $HKLMTcpip = "registry::HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $HKLMWinLogon = "registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $HKUWMSDK = "registry::HKU\.Default\Software\Microsoft\Windows Media\WMSDK\General"

        $RegistryParam = (
            @{
                BasePath = "$HKLMComputerName\Computername"
                name     ="Computername"
            },
            @{
                BasePath = "$HKLMComputerName\ActiveComputername"
                name ="Computername"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "Hostname"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "NV Hostname"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "AltDefaultDomainName"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "DefaultDomainName"
            },
            @{
                BasePath = $HKUWMSDK
                name     = "Computername"
            }
        )

        function CheckItemProperty ([string]$BasePath, [string]$Name)
        {
            $result = $null
            if (Test-Path $BasePath)
            {
                $base = Get-ItemProperty $BasePath
                $keyExist = ($base | Get-Member -MemberType NoteProperty).Name -contains $Name
                if (($null -ne $base) -and $keyExist)
                {
                    Write-Verbose ("Found. Path '{0}' and Name '{1}' found. Show result." -f $BasePath, $Name)
                    $result = [ordered]@{
                        path      = $BasePath
                        Property  = $name
                        value     = ($base | where $Name | %{Get-ItemProperty -path $BasePath -name $Name}).$Name
                    }
                }
                else
                {
                    Write-Verbose ("Skip. Path '{0}' found but Name '{1}' not found." -f $BasePath, $Name)
                }
            }
            else
            {
                Write-Verbose ("Skip. Path '{0}' not found." -f $BasePath)
            }

            if ($null -eq $result)
            {
                Write-Verbose ("Skip. Item Property '{0}' not found from path '{1}'." -f $name, $BasePath)
            }
            else
            {
                return [PSCustomObject]$result
            }
        }
    }
}
# file loaded from path : \functions\Helper\ComputerName\Get-ValentiaComputerName.ps1

#Requires -Version 3.0

#-- Helper for valentia --#

function Rename-ValentiaComputerName
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [validateLength(1,15)]
        [string]$NewComputerName,

        [parameter(Mandatory = 0, Position  = 1)]
        [switch]$Force,

        [parameter(Mandatory = 0, Position  = 2)]
        [switch]$PassThru = $false
    )
   
    end
    {
        # InvalidCharactorCheck
        if ($detect = GetContainsInvalidCharactor -ComputerName $NewComputerName)
        {
            throw ("NewComputerName '{0}' conrains invalid charactor : {1} . Make sure not to include following fault charactors. : {2}" -f $NewComputerName, (($detect | sort -Unique) -join ""), '`~!@#$%^&*()=+_[]{}\|;:.''",<>/?')
        }

        # Execute Change
        $RegistryParam.GetEnumerator() `
        | %{CheckItemProperty -BasePath $_.BasePath -name $_.Name} `
        | where {$force -or $PSCmdlet.ShouldProcess($_.path, ("Change ComputerName on Registry PropertyName : '{1}', CurrentValue : '{2}', NewName : '{3}'" -f $_.path, $_.Property, $_.Value, $NewComputerName))} `
        | %{
            if ($_.Path -eq $HKLMTcpip)
            {
                Write-Verbose ("Removing existing Registry before set new ComputerName. Registry : '{0}'" -f $_.path)
                Remove-ItemProperty -Path $_.path -Name $_.Property
            }

            Write-Verbose ("Setting New ComputerName on Registry : '{0}'" -f $_.path)
            Set-ItemProperty -Path $_.path -Name $_.Property -Value $NewComputerName -PassThru:$passThru
        }
    }

    begin
    {
        Set-StrictMode -Version Latest
        $PSBoundParameters.Remove('Force') > $null
        $list = New-Object 'System.Collections.Generic.List[PSCustomObject]'

        # HostName from Refistry
        Write-Verbose "Obtain Host Names from Registry Keys."
        $HKLMComputerName = "registry::HKLM\SYSTEM\CurrentControlSet\Control\Computername"
        $HKLMTcpip = "registry::HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        $HKLMWinLogon = "registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $HKUWMSDK = "registry::HKU\.Default\Software\Microsoft\Windows Media\WMSDK\General"

        $RegistryParam = (
            @{
                BasePath = "$HKLMComputerName\Computername"
                name     ="Computername"
            },
            @{
                BasePath = "$HKLMComputerName\ActiveComputername"
                name ="Computername"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "Hostname"
            },
            @{
                BasePath = $HKLMTcpip
                name     = "NV Hostname"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "AltDefaultDomainName"
            },
            @{
                BasePath = $HKLMWinLogon
                name     = "DefaultDomainName"
            },
            @{
                BasePath = $HKUWMSDK
                name     = "Computername"
            }
        )

        function GetContainsInvalidCharactor ([string]$ComputerName)
        {
            $detectedChar = ""
            # Invalid Charactor list described by MS : http://support.microsoft.com/kb/228275
            $invalidCharactor = [System.Linq.Enumerable]::ToArray('`~!@#$%^&*()=+_[]{}\|;:.''",<>/?')
            $detectedChar = [System.Linq.Enumerable]::ToArray($ComputerName) | where {$_ -in $invalidCharactor}
            return $detectedChar
        }

        function CheckItemProperty ([string]$BasePath, [string]$Name)
        {
            $result = $null
            if (Test-Path $BasePath)
            {
                $base = Get-ItemProperty $BasePath
                $keyExist = ($base | Get-Member -MemberType NoteProperty).Name -contains $Name
                if (($null -ne $base) -and $keyExist)
                {
                    Write-Verbose ("Found. Path '{0}' and Name '{1}' found. Show result." -f $BasePath, $Name)
                    $result = [ordered]@{
                        path      = $BasePath
                        Property  = $name
                        value     = ($base | where $Name | %{Get-ItemProperty -path $BasePath -name $Name}).$Name
                    }
                }
                else
                {
                    Write-Verbose ("Skip. Path '{0}' found but Name '{1}' not found." -f $BasePath, $Name)
                }
            }
            else
            {
                Write-Verbose ("Skip. Path '{0}' not found." -f $BasePath)
            }

            if ($null -eq $result)
            {
                Write-Verbose ("Skip. Item Property '{0}' not found from path '{1}'." -f $name, $BasePath)
            }
            else
            {
                return [PSCustomObject]$result
            }
        }
    }
}
# file loaded from path : \functions\Helper\ComputerName\Rename-ValentiaComputerName.ps1

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

    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 0,
            position = 0)]
        [System.String]
        $configPath = (Join-Path $Valentia.appdataconfig.root $Valentia.appdataconfig.file),

        [parameter(
            mandatory = 0,
            position = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $encoding = $Valentia.fileEncode
    )

    if (Test-Path $configPath)
    {
        $private:datePrefix = ([System.DateTime]::Now).ToString($valentia.log.dateformat)
        $private:backupConfigName = $datePrefix + "_" + $Valentia.appdataconfig.file
        $private:backupConfigPath = Join-Path $Valentia.appdataconfig.root $backupConfigName

        Write-Verbose ("Backing up config file '{0}' => '{1}'." -f $configPath, $backupConfigPath)
        Get-Content -Path $configPath -Encoding $encoding -Raw | Out-File -FilePath $backupConfigPath -Encoding $encoding -Force 
    }
    else
    {
        Write-Verbose ("Could not found configuration file '{0}'." -f $configPath)
    }
}

# file loaded from path : \functions\Helper\Config\Backup-valentiaConfig.ps1

#Requires -Version 3.0

<#
.Synopsis
   Edit Valentia Config in Console
.DESCRIPTION
   Read config and edit in the console
.EXAMPLE
   Edit-ValentiaConfig
#>
function Edit-ValentiaConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position = 0)]
        [string]$configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file),

        [parameter(mandatory = 0, position = 1)]
        [switch]$NoProfile
    )

    if (Test-Path $configPath)
    {
        if ($NoProfile)
        {
            PowerShell_ise.exe -File $configPath -NoProfile
        }
        else
        {
            PowerShell_ise.exe -File $configPath
        }
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }

}

# file loaded from path : \functions\Helper\Config\Edit-ValentiaConfig.ps1

#Requires -Version 3.0

<#
.Synopsis
   Edit Valentia Config in Console
.DESCRIPTION
   Read config and edit in the console
.EXAMPLE
   Edit-ValentiaConfig
#>
function Reset-ValentiaConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position = 0)]
        [string]$configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file),

        [parameter(mandatory = 0, position = 1)]
        [switch]$NoProfile
    )

    if (Test-Path $configPath)
    {
        . $configPath
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }

}

# file loaded from path : \functions\Helper\Config\Reset-ValentiaConfig.ps1

#Requires -Version 3.0

<#
.Synopsis
   Show Valentia Config in Console
.DESCRIPTION
   Read config and show in the console
.EXAMPLE
   Show-ValentiaConfig
#>
function Show-ValentiaConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 0, position = 0)]
        [string]$configPath = (Join-Path $valentia.appdataconfig.root $valentia.appdataconfig.file),

        [parameter(mandatory = 0, position = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = "default"
    )

    if (Test-Path $configPath)
    {
        Get-Content -Path $configPath -Encoding $encoding
    }
    else
    {
        ("Could not found configuration file '{0}'." -f $configPath) | Write-ValentiaVerboseDebug
    }
}

# file loaded from path : \functions\Helper\Config\Show-ValentiaConfig.ps1

#Requires -Version 3.0

function Get-ValentiaCredential
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = 0, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = 0, position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValentiaWindowsCredentialManagerType]$Type = [ValentiaWindowsCredentialManagerType]::Generic
    )
 
    try
    {
        $private:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
        $private:CredReadCS = Join-Path $CSPath CredRead.cs -Resolve
        $private:sig = Get-Content -Path $CredReadCS -Raw

        $private:addType = @{
            MemberDefinition = $sig
            Namespace        = "Advapi32"
            Name             = "Util"
        }
        Add-ValentiaTypeMemberDefinition @addType -PassThru `
        | select -First 1 `
        | %{
            $CredentialType = $_.AssemblyQualifiedName -as [type]
            $private:typeFullName = $_.FullName
        }

        $private:nCredPtr= New-Object IntPtr
        if ($CredentialType::CredRead($TargetName, $Type.value__, 0, [ref]$nCredPtr))
        {
            $private:critCred = New-Object $typeFullName+CriticalCredentialHandle $nCredPtr
            $private:cred = $critCred.GetCredential()
            $private:username = $cred.UserName
            $private:securePassword = $cred.CredentialBlob | ConvertTo-SecureString -AsPlainText -Force
            $cred = $null
            $credentialObject = New-Object System.Management.Automation.PSCredential $username, $securePassword
            if ($null -eq $credentialObject)
            {
                throw "Null Credential found from Credential Manager exception!! Make sure your credential is set with TArgetName : '{0}'" -f $TargetName
            }
            return $credentialObject
        }
        else
        {
            throw "No credentials found in Windows Credential Manager for TargetName: '{0}' with Type '{1}'" -f $TargetName, $Type
        }
    }
    catch
    {
        throw $_
    }
}
# file loaded from path : \functions\Helper\Credential\Get-ValentiaCredential.ps1

#Requires -Version 3.0

function Set-ValentiaCredential
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = 0, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = 0, position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(mandatory = 0, position = 2)]
        [ValidateNotNullOrEmpty()]
        [ValentiaWindowsCredentialManagerType]$Type = [ValentiaWindowsCredentialManagerType]::Generic
    )

    Set-StrictMode -Version latest

    $private:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
    $private:CredWriteCS = Join-Path $CSPath CredWrite.cs -Resolve
    $private:sig = Get-Content -Path $CredWriteCS -Raw

    if ($null -eq $Credential)
    {
        $Credential  = (Get-Credential -user $valentia.users.DeployUser -Message ("Input {0} Password to be save." -f $valentia.users.DeployUser))
    }

    $private:domain = $Credential.GetNetworkCredential().Domain
    $private:user = $Credential.GetNetworkCredential().UserName
    $private:password = $Credential.GetNetworkCredential().Password
    switch ([String]::IsNullOrWhiteSpace($domain))
    {
        $true   {$userName = $user}
        $false  {$userName = $domain, $user -join "\"}
    }

    $private:addType = @{
        MemberDefinition = $sig
        Namespace        = "Advapi32"
        Name             = "Util"
    }
    $private:typeName = Add-ValentiaTypeMemberDefinition @addType -PassThru
    $private:typeFullName = $typeName.FullName | select -Last  1
    $CredentialType = ($typeName.AssemblyQualifiedName | select -First 1) -as [type]
    
    $private:cred = New-Object $typeFullName
    $cred.flags = 0
    $cred.type = $Type.value__
    $cred.targetName = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($TargetName)
    $cred.userName = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($userName)
    $cred.attributeCount = 0
    $cred.persist = 2
    $cred.credentialBlobSize = [System.Text.Encoding]::Unicode.GetBytes($password).length
    $cred.credentialBlob = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($password)
    $private:result = $CredentialType::CredWrite([ref]$cred,0)

    if ($true -eq $result)
    {
        return $true
    }
    else
    {
        return $false
    }
}
# file loaded from path : \functions\Helper\Credential\Set-ValentiaCredential.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Add-ValentiaCredSSPDelegateReg
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $param = @{
        Path  = (Split-Path $keys -Parent)
        Name  = (Split-Path $keys -Leaf)
        Value = 1
        Force = $true
    }

    $result = Get-ValentiaCredSSPDelegateReg -Keys $Keys
    if ($result.Value -ne 1)
    {
        Set-ItemProperty @param -PassThru
    }
    elseif ($null -eq $result)
    {
        New-ItemProperty @param
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Add-ValentiaCredSSPDelegateReg.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Add-ValentiaCredSSPDelegateRegKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $param = @{
        Path  = (Split-Path $keys -Parent)
        Name  = (Split-Path $keys -Leaf)
        Force = $true
    }
    $result = Get-ValentiaCredSSPDelegateRegKey -Keys $Keys
    if ($result -eq $false)
    {
        New-Item @param
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Add-ValentiaCredSSPDelegateRegKey.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Add-ValentiaCredSSPDelegateRegKeyProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key,

        [Parameter(Position = 1, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$regValue = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Value
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $param = @{
        Path  = $keys
        Value = $regValue
        Force = $true
    }

    $result = Get-ValentiaCredSSPDelegateRegKeyProperty -Keys $Keys
    if ($result.Value -notcontains $regValue)
    {
        $max = ($result.Key | measure -Maximum).Maximum
        $max++
        New-ItemProperty @param -Name $max
    }
    elseif ($null -eq $result.Key)
    {
        New-ItemProperty @param -Name 1
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Add-ValentiaCredSSPDelegateRegKeyProperty.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Enable-ValentiaCredSSP
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TrustedHosts = $valentia.wsman.TrustedHosts
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    try
    {
        Enable-WSManCredSSP -Role Server -Force
        Enable-WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    catch
    {
        # Unfortunately you need to repeat cpmmand again to enable Client Role.
        Enable-WSManCredSSP -Role Client -DelegateComputer $TrustedHosts -Force
    }
    finally
    {
        Get-WSManCredSSP
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Enable-ValentiaCredSSP.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateReg
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $path = (Split-Path $keys -Parent)
    $name = (Split-Path $keys -Leaf)
    Get-ItemProperty -Path $path `
    | %{
        $hashtable = @{
            Name    = $name
            Path    = $path
        }

        if ($_ | Get-Member | where MemberType -eq NoteProperty | where Name -eq $name)
        {
            $hashtable.Add("Value", $_.$name)
        }
        else
        {
            $hashtable.Add("Value", $null)
        }
        
        [PSCustomObject]$hashtable
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Get-ValentiaCredSSPDelegateReg.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateRegKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $path = (Split-Path $keys -Parent)
    $name = (Split-Path $keys -Leaf)
    Get-ChildItem -Path $path `
    | %{
        $hashtable = @{
            Name    = $name
            PSPath  = $path
        }

        if ($_ | where name -eq $name)
        {
            $true
        }
        else
        {
            $false
        }
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Get-ValentiaCredSSPDelegateRegKey.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Get-ValentiaCredSSPDelegateRegKeyProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $regProperty = Get-ItemProperty -Path $keys
    if ($regProperty)
    {
        $regProperty `
        | Get-Member -MemberType NoteProperty `
        | where Name -Match "\d+" `
        | %{
            $name = $_.Name
            [PSCustomObject]@{
                Key   = $name
                Value = $regProperty.$name
                path  = $keys
            }
        }
    }
    else
    {
        [PSCustomObject]@{
            Key   = ""
            Value = ""
            path  = $Keys
        }
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Get-ValentiaCredSSPDelegateRegKeyProperty.ps1

#Requires -Version 3.0

#-- Public Functions for CredSSP Configuration --#

function Remove-ValentiaCredSSPDelegateRegKey
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TrustedHosts = $valentia.wsman.TrustedHosts,

        [Parameter(Position = 1, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Keys = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Key,

        [Parameter(Position = 2, Mandatory = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$regValue = $valentia.credssp.AllowFreshCredentialsWhenNTLMOnly.Value
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    $result = Get-ValentiaCredSSPDelegateRegKey -TrustedHosts $TrustedHosts -Keys $Keys
    if ($result.Value -contains $regValue)
    {
        $result | %{Remove-ItemProperty -Path $_.pspath -Name $_.Key -Force}
    }
}
# file loaded from path : \functions\Helper\CredSSP\Private\Remove-ValentiaCredSSPDelegateRegKey.ps1

#Requires -Version 3.0

#-- helper for DNS Entry --#

<#
.Synopsis
   Get HostName to IPAddress Entry / IPAddress to HostName Entry

.DESCRIPTION
   using Dns.GetHostEntryAsync Method. 
   You can skip Exception for none exist HostNameOrAddress result by adding -SkipException $true

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "neue.cc"
# Test Success

.EXAMPLE
"google.com", "173.194.38.100", "neue.cc" | Get-HostEntryAsync
# Pipeline Input

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "hogemopge.fugapiyo"
# Error will stop execution

.EXAMPLE
Get-HostEntryAsync -HostNameOrAddress "google.com", "173.194.38.100", "hogemopge.fugapiyo" -SkipException $true
# Skip Error result

.LINK
    http://msdn.microsoft.com/en-US/library/system.net.dns.gethostentryasync(v=vs.110).aspx
#>
function Get-ValentiaHostEntryAsync
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [string[]]$HostNameOrAddress,

        [parameter(Mandatory = 0, Position  = 1, ValueFromPipelineByPropertyName = 1)]
        [bool]$SkipException = $false
    )

    process
    {
        foreach ($name in $HostNameOrAddress)
        {
            $x = [System.Net.DNS]::GetHostEntryAsync($name)
            $x.ConfigureAwait($false) > $null
            $task = [PSCustomObject]@{
                HostNameOrAddress = $name
                Task              = $x
            }
            $tasks.Add($task)
        }
    }

    end
    {
        try
        {
            [System.Threading.Tasks.Task]::WaitAll($tasks.Task)
        }
        catch
        {
            $stackStrace = $_ 
            $throw = $Tasks `
            | where {$_.Task.Exception} `
            | %{
                $stackStrace
                [System.Environment]::NewLine
                "Error HostNameOrAddress : {0}" -f $_.HostNameOrAddress                    
                [System.Environment]::NewLine
                $_.Task.Exception
            }

            if (-not $SkipException)
            {
                throw $throw
            }
            else
            {
                Write-Verbose ("-SkipException was {0}. Skipping Error : '{1}'." -f $SkipException, "$(($Tasks | where {$_.Task.Exception}).HostNameOrAddress -join ', ')")
            }
        }
        finally
        {
            foreach ($task in $tasks.Task)
            {
                [System.Net.IPHostEntry]$IPHostEntry = $task.Result
                $IPHostEntry
            }
        }
    }
    
    begin
    {
        $tasks = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    }
}
# file loaded from path : \functions\Helper\DNS\Get-ValentiaHostEntryAsync.ps1

#Requires -Version 3.0

#-- function helper for Dynamic Param --#

<#
.SYNOPSIS 
This cmdlet will return Dynamic param dictionary

.DESCRIPTION
You can use this cmdlet to define Dynamic Param

.NOTES
Author: guitrrapc
Created: 02/03/2014

.EXAMPLE
function Show-ValentiaDynamicParamMulti
{
    [CmdletBinding()]
    param(
        [parameter(position = 6)]
        $nyao
    )
    
    dynamicParam
    {
        $dynamicParams = (
            @{Mandatory    = $true
              name         = "hoge"
              Options      = "hoge","piyo"
              position     = 0
              Type         = "System.String[]"
              validateSet  = $true
              valueFromPipelineByPropertyName = $true},
              
              @{Mandatory    = $true
              name         = "foo"
              Options      = 1,2,3,4,5
              position     = 1
              Type         = "System.Int32[]"
              validateSet  = $true},

              @{DefaultValue = (4,2,5)
              Mandatory    = $false
              name         = "bar"
              Options      = 1,2,3,4,5
              position     = 2
              Type         = "System.Int32[]"
              validateSet  = $false}
        )

        $dynamic = New-ValentiaDynamicParamMulti -dynamicParams $dynamicParams
        return $dynamic
    }

    begin
    {
    }
    process
    {
        $PSBoundParameters.hoge
        $PSBoundParameters.foo
        if ($PSBoundParameters.ContainsKey('bar'))
        {
            $PSBoundParameters.bar
            $PSBoundParameters.bar.GetType().FullName
        }
        else
        {
            $bar = $dynamic.bar.Value
            $bar
            $bar.GetType().FullName
        }
    }
}

"Test 1 ---------------------"
Show-ValentiaDynamicParamMulti -hoge hoge -foo 1,2,3,4
"Test 2 ---------------------"
Show-ValentiaDynamicParamMulti -hoge piyo -foo 2 -bar 2
#>

function New-ValentiaDynamicParamMulti
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position = 0, valueFromPipeline = 1, valueFromPipelineByPropertyName = 1)]
        [hashtable[]]$dynamicParams
    )

    begin
    {
        $dynamicParamLists = New-ValentiaDynamicParamList -dynamicParams $dynamicParams
        $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }

    process
    {
        foreach ($dynamicParamList in $dynamicParamLists)
        {
            # create attributes
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.ParameterSetName = "__AllParameterSets"
            (
                "helpMessage",
                "mandatory",
                "parameterSetName",
                "position",
                "valueFromPipeline",
                "valueFromPipelineByPropertyName",
                "valueFromRemainingArguments"
            ) `
            | %{
                if($dynamicParamList.$_)
                {
                    $attributes.$_ = $dynamicParamList.$_
                }
            }

            # create attributes Collection
            $attributesCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
            $attributesCollection.Add($attributes)
        
            # create validation set
            if ($dynamicParamList.validateSet)
            {
                $validateSetAttributes = New-Object System.Management.Automation.ValidateSetAttribute $dynamicParamList.options
                $attributesCollection.Add($validateSetAttributes)
            }

            # Set default type or get from dynamicparam
            # Priority
            # 1. Type KV
            # 2. Type of DefaultValue
            # 3. System.Object[]
            if ($dynamicParamList.type)
            {
                $type = [Type]::GetType($dynamicParamList.Type)
            }
            else
            {
                if ($dynamicParamList.defaultValue)
                {
                    $DefaultValueType = $dynamicParamList.defaultValue.GetType().FullName
                    $type = [Type]::GetType($DefaultValueType)
                }
                else
                {
                    $type = [Type]::GetType("System.Object[]")
                }
            }

            if ($null -eq $type)
            {
                throw "type not defined or Null exception! Make sure you have set fullname for the type : '{0}'" -f $dynamicParamList.type
            }

            # create RuntimeDefinedParameter
            $runtimeDefinedParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter @($dynamicParamList.name, $type, $attributesCollection)

            # Set Default Value if passed
            if ($dynamicParamList.defaultValue)
            {
                if ($dynamicParamList.defaultValue -is $type)
                {
                    $runtimeDefinedParameter.Value = $dynamicParamList.defaultValue
                }
                elseif ($dynamicParamList.defaultValue -as $type)
                {
                    Write-Verbose ("Convert Type for ParameterName '{0}'. DefaultValue '{1}' convert from '{2}' to '{3}'" `
                        -f 
                            $dynamicParamList.name,
                            $dynamicParamLists.defaultValue,
                            $dynamicParamList.defaultValue.GetType().FullName,
                            $type)
                    $runtimeDefinedParameter.Value = $dynamicParamList.defaultValue -as $type
                }
                else
                {
                    throw "Cannot convert Type for ParameterName '{0}'. DefaultValue '{1}' could not convert from '{2}' to '{3}'" `
                        -f 
                            $dynamicParamList.name,
                            $dynamicParamLists.defaultValue,
                            $dynamicParamList.defaultValue.GetType().FullName,
                            $type
                }
            }

            # create Dictionary
            $dictionary.Add($dynamicParamList.name, $runtimeDefinedParameter)
        }
    }

    end
    {
        # return result
        return $dictionary
    }
}


<#
.SYNOPSIS 
This cmdlet will return Dynamic param list item for dictionary

.DESCRIPTION
You can pass this list to DynamicPramMulti to create Dynamic Param
#>
function New-ValentiaDynamicParamList
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0,
            valueFromPipeline = 1,
            valueFromPipelineByPropertyName = 1)]
        [hashtable[]]
        $dynamicParams
    )

    begin
    {
        # create generic list
        $list = New-Object System.Collections.Generic.List[HashTable]

        # create key check array
        [string[]]$keyCheckInputItems = "helpMessage", "mandatory", "name", "parameterSetName", "options", "position", "valueFromPipeline", "valueFromPipelineByPropertyName", "valueFromRemainingArguments", "validateSet", "Type", "DefaultValue"

        $keyCheckList = New-Object System.Collections.Generic.List[String]
        $keyCheckList.AddRange($keyCheckInputItems)

        # sort dynamicParams hashtable by position
        $newDynamicParams = Sort-ValentiaDynamicParamHashTable -dynamicParams $dynamicParams
    }

    process
    {
        foreach ($dynamicParam in $newDynamicParams)
        {
            $invalidParamter = $dynamicParam.Keys | where {$_ -notin $keyCheckList}
            if ($($invalidParamter).count -ne 0)
            {
                throw ("Invalid parameter '{0}' found. Please use parameter from '{1}'" -f $invalidParamter, ("$keyCheckInputItems" -replace " "," ,"))
            }
            else
            {
                if (-not $dynamicParam.Keys.contains("name"))
                {
                    throw ("You must specify mandatory parameter '{0}' to hashtable key." -f "name")
                }
                elseif (-not $dynamicParam.Keys.contains("options"))
                {
                    throw ("You must specify mandatory parameter '{0}' to hashtable key." -f "options")
                }
                else
                {
                    $list.Add($dynamicParam)
                }
            }
        }
    }

    end
    {
        return $list
    }
}


function Sort-ValentiaDynamicParamHashTable
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory = 1,
            position = 0,
            valueFromPipeline = 1,
            valueFromPipelineByPropertyName = 1)]
        [hashtable[]]
        $dynamicParams
    )

    begin
    {
        # get max number of position for null position item
        $max = ($dynamicParams.position | measure -Maximum).Maximum
    }

    process
    {
        # output PSCustomObject[Name<SortedPosition>,Value<DynamicParamHashTable>]. posision is now sorted.
        $h = $dynamicParams `
        | %{
            $history = New-Object System.Collections.Generic.List[int]
            $hash = @{}
            
            # temp posision for null item. This set as (max + number of collection items)
            $num = $max + $parameters.Length
        }{
            Write-Verbose ("position is '{0}'." -f $position)
            $position = $_.position
            
            #region null check
            if ($null -eq $position)
            {
                Write-Verbose ("position is '{0}'. set current max index '{1}'" -f $position, $num)
                $position = $num
                $num++
            }
            #endregion

            #region dupricate check
            if ($position -notin $history)
            {
                Write-Verbose ("position '{0}' not found in '{1}'. Add to history." -f $position, ($history -join ", "))
                $history.Add($position)
            }
            else
            {
                $changed = $false
                while ($position -in $history)
                {
                    Write-Verbose ("position '{0}' found in '{1}'. Start increment." -f $position, ($history -join ", "))
                    $position++
                    $changed = $true
                }
                Write-Verbose (" incremented position '{0}' not found in '{1}'. Add to history." -f $position, ($history -join ", "))
                if ($changed){$history.Add($position)}
            }
            #endregion

            #region set temp hash
            Write-Verbose ("Set position '{0}' as name of temp hash." -f $position)
            $hash."$position" = $_
            #endregion
        }{[PSCustomObject]$hash}
    }

    end
    {
        # get index for each object
        $index = [int[]](($h | Get-Member -MemberType NoteProperty).Name) | sort
        
        # return sorted hash order by index
        return $index | %{$h.$_}
    }
}
# file loaded from path : \functions\Helper\DynamicParam\New-ValentiaDynamicParamMulti.ps1

#Requires -Version 3.0

#-- Helper Functions --#

<#
.SYNOPSIS 
Get encoding from the file your tried to read.

.DESCRIPTION
You can specify what is the encoding used in the file you want to check.
Will return encoding name used in PowerShell, it means you can pass returned value to Get-Content or other.

.NOTES
Author: guitarrapc
Created: 19/Nov/2013

.EXAMPLE
Get-ValentiaFileEncoding -Path hogehoge.ps1
--------------------------------------------
Get encoding of hogehoge.ps1
#>
function Get-ValentiaFileEncoding
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position = 0)]
        [string]$path
    )

    if (Test-Path $path)
    {
        $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

        if(-not $bytes)
        {
            return 'utf8'
        }

        switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3])
        {
            '^efbbbf'   {return 'utf8'}
            '^2b2f76'   {return 'utf7'}
            '^fffe'     {return 'unicode'}
            '^feff'     {return 'bigendianunicode'}
            '^0000feff' {return 'utf32'}
            default     {return 'ascii'}
        }
    }
    else
    {
        throw ("path '{0}' not exist excemption." -f $path)
    }
}
# file loaded from path : \functions\Helper\Encoding\Get-ValentiaFileEncoding.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Create New Firewall Rule for PowerShell Remoting

.DESCRIPTION
Will allow PowerShell Remoting port for firewall

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-PSRemotingFirewallRule
--------------------------------------------
Add PowerShellRemoting-In accessible rule to Firewall.
#>
function New-ValentiaPSRemotingFirewallRule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Input PowerShellRemoting-In port. default is 5985")]
        [int]$PSRemotePort = 5985,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Input Name of Firewall rule for PowerShellRemoting-In.")]
        [string]$Name = "Windows Remote Management (HTTP-In)",

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Input Decription of Firewall rule for PowerShellRemoting-In.")]
        [string]$Description = "Windows PowerShell Remoting required to open for public connection. not for private network.",

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Input Group of Firewall rule for PowerShellRemoting-In.")]
        [string]$Group = "Windows Remote Management"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-NetFirewallRule | where Name -eq $Name) -and (Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq $PSRemotePort)))
    {
        Write-Verbose ("Windows PowerShell Remoting port TCP $PSRemotePort was not opend. Set new rule '{1}'" -f $PSRemotePort, $Name)
        New-NetFirewallRule `
            -Name $Name `
            -DisplayName $Name `
            -Description $Description `
            -Group $Group `
            -Enabled True `
            -Profile Any `
            -Direction Inbound `
            -Action Allow `
            -EdgeTraversalPolicy Block `
            -LooseSourceMapping $False `
            -LocalOnlyMapping $False `
            -OverrideBlockRules $False `
            -Program Any `
            -LocalAddress Any `
            -RemoteAddress Any `
            -Protocol TCP `
            -LocalPort $PSRemotePort `
            -RemotePort Any `
            -LocalUser Any `
            -RemoteUser Any 
    }
    else
    {
        "Windows PowerShell Remoting port TCP 5985 was alredy opened. Get Firewall Rule." | Write-ValentiaVerboseDebug
        Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq 5985
    }

    if ((Get-WinSystemLocale).Name -eq "ja-JP")
    {
        $japanesePSRemoteingEnableRule = "Windows リモート管理 (HTTP 受信)"
        if (-not((Get-NetFirewallRule | where DisplayName -eq $japanesePSRemoteingEnableRule | where Profile -eq "Any") -and (Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq $PSRemotePort)))
        {
            ("日本語OSと検知しました。'{0}' という名称で TCP '{1}' をファイアウォールに許可します。" -f $japanesePSRemoteingEnableRule, 5985) | Write-ValentiaVerboseDebug
            New-NetFirewallRule `
                -Name $japanesePSRemoteingEnableRule `
                -DisplayName $japanesePSRemoteingEnableRule `
                -Description $Description `
                -Group $Group `
                -Enabled True `
                -Profile Any `
                -Direction Inbound `
                -Action Allow `
                -EdgeTraversalPolicy Block `
                -LooseSourceMapping $False `
                -LocalOnlyMapping $False `
                -OverrideBlockRules $False `
                -Program Any `
                -LocalAddress Any `
                -RemoteAddress Any `
                -Protocol TCP `
                -LocalPort $PSRemotePort `
                -RemotePort Any `
                -LocalUser Any `
                -RemoteUser Any 
        }
    }
}

# file loaded from path : \functions\Helper\FireWall\Firewall\New-ValentiaPSRemotingFirewallRule.ps1

#Requires -Version 3.0

#-- Prerequisite Deploy Setting Module Functions --#

<#
.SYNOPSIS 
Configure Deployment Path

.DESCRIPTION
This cmdlet will create valentis deploy folders for each Branch path.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaFolder
--------------------------------------------
create as default
#>
function New-ValentiaFolder
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Root Folder path.")]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath = $valentia.RootPath,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Branch Path path.")]
        [ValidateNotNullOrEmpty()]
        [ValentiaBranchPath[]]$BranchPath = [Enum]::GetNames([ValentiaBranchPath]),

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Log Folder path.")]
        [ValidateNotNullOrEmpty()]$LogFolder = $valentia.Log.path,

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Suppress output directory create info.")]
        [switch]$Quiet
    )

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        # Create Fullpath String
        if (($BranchPath).count -ne 0)
        {
            $DeployFolders = $BranchPath | %{Join-Path $RootPath $_}
        }

        $directories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    }

    process
    {
        # Check each Fupllpath and create if not exist.
        foreach ($Deployfolder in $DeployFolders)
        {
            if(-not (Test-Path $DeployFolder))
            {
                ("'{0}' not exist, creating." -f $DeployFolder) | Write-ValentiaVerboseDebug
                $output = New-Item -Path $DeployFolder -ItemType directory -Force
                $directories.Add($output)
            }
            else
            {
                ("'{0}' already exist, skip." -f $DeployFolder) | Write-ValentiaVerboseDebug
                $output = Get-Item -Path $DeployFolder
                $directories.Add($output)
            }
        }

        # Check Log Folder and create if not exist 
        if(-not (Test-Path $LogFolder))
        {
            ("'{0}' not exist, creating." -f $LogFolder) | Write-ValentiaVerboseDebug
            $output = New-Item -Path $LogFolder -ItemType directory -Force
            $directories.Add($output)
        }
        else
        {
            ("'{0}' already exist, skip." -f $LogFolder) | Write-ValentiaVerboseDebug
            $output = Get-Item -Path $LogFolder
            $directories.Add($output)
        }
    }

    end
    {
        if (-not $Quiet)
        {
            ($directories).FullName
        }

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}

# file loaded from path : \functions\Helper\Folder\New-ValentiaFolder.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# target

<#
.SYNOPSIS 
Get ipaddress or NetBIOS from DeployGroup File specified

.DESCRIPTION
This cmdlet will read Deploy Group path and set them into array of Deploygroups.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
target production-hoge.ps1
--------------------------------------------
read production-hoge.ps1 from deploy group branch path.

.EXAMPLE
target production-hoge.ps1 c:\test
--------------------------------------------
read production-hoge.ps1 from c:\test.
#>
function Get-ValentiaGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]$DeployGroups,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [ValidateNotNullOrEmpty()]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup))
    )

    process
    {
        foreach ($DeployGroup in $DeployGroups)
        {
            # Get valentia.deployextension information
            ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension) | Write-ValentiaVerboseDebug
            $DeployExtension = $valentia.deployextension

            'Read DeployGroup and return $DeployMemebers' | Write-ValentiaVerboseDebug
            Read-ValentiaGroup -DeployGroup $DeployGroup
        }
    }

    begin
    {
        # Get valentiaGroup
        function Read-ValentiaGroup
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Position = 0, Mandatory)]
                [string]
                $DeployGroup
            )

            if ($DeployGroup.EndsWith($DeployExtension)) # if DeployGroup last letter = Extension is same as $DeployExtension
            {
                $DeployGroupPath = Join-Path $DeployFolder $DeployGroup -Resolve

                ("Read DeployGroupPath {0} where letter not contain # inline." -f $DeployGroupPath) | Write-ValentiaVerboseDebug
                return (Select-String -path $DeployGroupPath -Pattern ".*#.*" -notmatch -Encoding $valentia.fileEncode | Select-String -Pattern "\w" -Encoding $valentia.fileEncode).line
            }
            else
            {
                return $DeployGroup
            }
        }
    }
}
# file loaded from path : \functions\Helper\Group\Get-ValentiaGroup.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# ipremark

<#
.SYNOPSIS 
Remark Deploy ip from deploygroup file

.DESCRIPTION
This cmdlet remark deploygroup ipaddresses from $valentia.root\$valentia.branch.deploygroup not to refer the ipaddress

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.10,10.0.0.11 -overWrite -Verbose
--------------------------------------------
replace 10.0.0.10 and 10.0.0.11 with #10.0.0.10 and #10.0.0.11 then replace file. (like sed -f "s/^10.0.0.10$/#10.0.0.10" -i)

Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose
--------------------------------------------
replace 10.0.0.10 and 10.0.0.11 with #10.0.0.10 and #10.0.0.11 (like sed -f "s/^10.0.0.10$/#10.0.0.10")

Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose -Recurse $false -Path d:\hoge
--------------------------------------------
Check d:\hoge folder without recursive. This means it only check path you desired.
#>
function Invoke-ValentiaDeployGroupRemark
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 0, mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [Alias("IPAddress", "HostName")]
        [string[]]$remarkIPAddresses,

        [parameter(position = 1, mandatory = 0,ValueFromPipelineByPropertyName = 1)]
        [string]$Path = (Join-Path $valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [parameter(position = 2, mandatory = 0, ValueFromPipelineByPropertyName = 1)]
        [bool]$Recurse = $true,

        [parameter(position = 3, mandatory = 0, ValueFromPipelineByPropertyName = 1)]
        [switch]$overWrite,

        [parameter(position = 4, mandatory = 0, ValueFromPipelineByPropertyName = 1)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $valentia.fileEncode
    )

    begin
    {
        if (-not (Test-Path $Path)){ throw New-Object System.IO.FileNotFoundException ("Path $Path not found Exception!!", "$Path")}
    }
   
    end
    {
        Get-ChildItem -Path $Path -Recurse:$Recurse -File `
        | %{
            foreach ($remarkIPAddress in $remarkIPAddresses)
            {
                if ($overWrite)
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^$remarkIPAddress$" -replaceWith "#$remarkIPAddress" -encoding $encoding -overWrite
                }
                else
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^$remarkIPAddress$" -replaceWith "#$remarkIPAddress" -encoding $encoding
                }
            }
        }
    }
}

# file loaded from path : \functions\Helper\Group\Invoke-ValentiaDeployGroupRemark.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# ipunremark

<#
.SYNOPSIS 
Unremark Deploy ip from deploygroup file

.DESCRIPTION
This cmdlet unremark deploygroup ipaddresses from $valentia.root\$valentia.branch.deploygroup to refer the ipaddress.

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -overWrite -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 then replace file (like sed -f "s/^#10.0.0.10$/10.0.0.10" -i)

Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 (like sed -f "s/^#10.0.0.10$/10.0.0.10")

Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose -Recurse $false -Path d:\hoge
--------------------------------------------
Check d:\hoge folder without recursive. This means it only check path you desired.
#>
function Invoke-ValentiaDeployGroupUnremark
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 0, mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [Alias("IPAddress", "HostName")]
        [string[]]$unremarkIPAddresses,

        [parameter(position = 1, mandatory = 0, ValueFromPipelineByPropertyName = 1)]
        [string]$Path = (Join-Path $valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [parameter(position = 2, mandatory = 0, ValueFromPipelineByPropertyName = 1)]
        [bool]$Recurse = $true,

        [parameter(position = 3, mandatory = 0)]
        [switch]$overWrite,

        [parameter(position = 4, mandatory = 0)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $encoding = $valentia.fileEncode
    )

    begin
    {
        if (-not (Test-Path $Path)){ throw New-Object System.IO.FileNotFoundException ("Path $Path not found Exception!!", "$Path")}
    }

    end
    {
        Get-ChildItem -Path $Path -Recurse:$Recurse -File `
        | %{
            foreach ($unremarkIPAddress in $unremarkIPAddresses)
            {
                if ($overWrite)
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -encoding $encoding -overWrite
                }
                else
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -encoding $encoding
                }
            }
        }
    }
}

# file loaded from path : \functions\Helper\Group\Invoke-ValentiaDeployGroupUnremark.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

<#
.SYNOPSIS 
Create new DeployGroup File written "target PC IP/hostname" for PS-RemoteSession

.DESCRIPTION
This cmdlet will create valentis deploy group file to specify deploy targets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaGroup -DeployClients "10.0.4.100","10.0.4.101" -FileName new.ps1
--------------------------------------------
write 10.0.4.100 and 10.0.4.101 to create deploy group file as "new.ps1".
#>
function New-ValentiaGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position  = 0, Mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Specify IpAddress or NetBIOS name for deploy target clients.")]
        [string[]]$DeployClients,

        [Parameter(Position = 1, Mandatory = 1, HelpMessage = "Input filename to output DeployClients")]
        [string]$FileName,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Specify folder path to deploy group. defailt is Deploygroup branchpath")]
        [string]$DeployGroupsFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "If you want to add item to exist file.")]
        [switch]$Add,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "If you want to popup confirm message when file created.")]
        [switch]$Confirm,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "If you want to Show file information when operation executed.")]
        [switch]$PassThru
    )

    process
    {
        if($PSBoundParameters.ContainsKey('Add'))
        {
            $DeployClients | Add-Content @param
        }
        else
        {
            $DeployClients | Set-Content @param
        }
    }

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        # check FileName is null or empty
        try
        {
            if ([string]::IsNullOrEmpty($FileName))
            {
                throw '"$FileName" was Null or Enpty, input DeployGroup FileName.'
            }
            else
            {
                $DeployPath = Join-Path $DeployGroupsFolder $FileName
            }
        }
        catch
        {
            throw $_
        }

        # set splatting
        $param = @{
            path     = $DeployPath
            Encoding = $valentia.fileEncode
            Force    = $true
            Confirm  = $PSBoundParameters.ContainsKey('Confirm')
            PassThru = $PSBoundParameters.ContainsKey('PassThru')
        }
    }

    end
    {
        if (Test-Path $DeployPath)
        {
            Get-ChildItem -Path $DeployPath
        }
        else
        {
            Write-Error ("{0} not existing." -f $DeployPath)
        }

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}


# file loaded from path : \functions\Helper\Group\New-ValentiaGroup.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

<#
.SYNOPSIS 
Show valentia deploygroup file (.ps1) list

.DESCRIPTION
This cmdlet will show files (extension = $valentia.deployextension = default is '.ps1') in [ValentiaBranchPath]::Deploygroup folder.

.NOTES
Author: guitarrapc
Created: 29/Oct/2013

.EXAMPLE
Show-ValentiaGroup
--------------------------------------------
show files in $valentia.Root\([ValentiaBranchPath]::Deploygroup) folder.
#>
function Show-ValentiaGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Input branch folder to show.")]
        [ValentiaBranchPath[]]$Branches = ([ValentiaBranchPath]::Deploygroup),

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Use if you want to search directory recursibly.")]
        [switch]$recurse
     )
 
    $DeployExtension = $valentia.deployextension
    
    foreach ($branch in $Branches)
    {
        if ($branch.Length -eq 0)
        {
            throw '"$Branch" was Null or Empty, input BranchName.'
        }
        else
        {
            ("Creating full path and resolving with '{0}' and '{1}'" -f $valentia.RootPath, ([ValentiaBranchPath]::$branch)) | Write-ValentiaVerboseDebug
            $BranchFolder = Join-Path $valentia.RootPath $branch -Resolve

            # show items
            $param = @{
                Path    = $BranchFolder
                Recurse = if($PSBoundParameters.recurse.IsPresent){$true}else{$false}
            }
            Get-ChildItem @param | where extension -eq $DeployExtension
        }
    }
}
# file loaded from path : \functions\Helper\Group\Show-ValentiaGroup.ps1

#Requires -Version 3.0

#-- helper for write verbose and debug --#

<#
.SYNOPSIS 
Pass to write-verbose / debug for input.

.DESCRIPTION
You can show same message for verbose and debug.

.NOTES
Author: guitarrapc
Created: 16/Feb/2014

.EXAMPLE
"hoge" | Write-ValentiaVerboseDebug
--------------------------------------------
Will show both Verbose message and Debug.
#>
filter Write-ValentiaVerboseDebug
{
    Write-Verbose -Message $_
    Write-Debug -Message $_
}
# file loaded from path : \functions\Helper\HostOutput\Write-ValentiaVerboseDebug.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Disable EnhancedIESecutiry for Internet Explorer

.DESCRIPTION
Change registry to disable EnhancedIESecutiry.
It will only work for [Windows Server] not for Workstation, and [Windows Server 2008 R2] and higer.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Disable-ValentiaEnhancedIESecutiry
--------------------------------------------
Disable IEEnhanced security.
#>
function Disable-ValentiaEnhancedIESecutiry
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Registry key for Admin.")]
        [string]$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}",
    
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Registry key for User.")]
        [string]$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    # get os version, Windows 7 will be "6 1 0 0"
    $osversion = [Environment]::OSVersion.Version

    # Higher than $valentia.supportWindows
    $minimumversion = New-Object 'Version' $valentia.supportWindows

    # check osversion higher than valentia support version
    if ($osversion -ge $minimumversion)
    {
        if (Test-Path $AdminKey)
        {
            if ((Get-ItemProperty -Path $AdminKey -Name "IsInstalled").IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }
        else
        {
            $IsstatusChanged = $false
        }

        if (Test-Path $UserKey)
        {
            if ((Get-ItemProperty -Path $UserKey -Name "IsInstalled").IsInstalled -eq "1")
            {
                Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
                $IsstatusChanged = $true
            }
            else
            {
                $IsstatusChanged = $false
            }
        }
        else
        {
            $IsstatusChanged = $false
        }

        if ($IsstatusChanged)
        {
            # Stop Internet Exploer if launch
            "IE Enhanced Security Configuration (ESC) has been disabled. Checking IE to stop process." | Write-ValentiaVerboseDebug
            Get-Process | where Name -eq "iexplore" | Stop-Process -Confirm
        }
        else
        {
            "IE Enhanced Security Configuration (ESC) had already been disabled. Nothing will do." | Write-ValentiaVerboseDebug
        }
    }
    else
    {
        Write-Warning -Message ("Your Operating System '{0}', Version:'{1}' was lower than valentia supported version '{2}'." -f `
            (Get-CimInstance -class Win32_OperatingSystem).Caption,
            $osversion,
            $minimumversion)
    }
}

# file loaded from path : \functions\Helper\IE\Private\Disable-ValentiaEnhancedIESecutiry.ps1

#Requires -Version 3.0

#-- Running prerequisite Initialize OS Setting Module Functions --#

# Initial

<#
.SYNOPSIS 
Initializing valentia PSRemoting environment for Deploy Server and client.

.DESCRIPTION
Make sure to Run as Admin Priviledge. 
This function will execute followings.

1. Set-ExecutionPolicy (Default : RemoteSigned)
2. Add PowerShell Remoting Inbound rule to Firewall
3. Network Connection Profile Setup
4. Disable PSRemoting and CredSSP for reset
5. Enable-PSRemoting
6. Add hosts to trustedHosts
7. Set WSMan MaxShellsPerUser from 25 to 100
8. Set WSMan MaxMBPerUser unlimited.
9. Set WSMan MaxProccessesPerShell unlimited.
10. Enable CredSSP for trustedHosts.
11. Restart Service WinRM
12. Disable Enhanced Security for Internet Explorer
13. Create OS user for Deploy connection.
14. Server Only : Create Deploy Folders
15. Server Only : Create/Revise Deploy user credential secure file.
16. Set HostName for the windows.
17. Get Status for Reboot Status and decide.

.PARAMETER Server
   Select this switch to Initialize setup for Deploy Server. (Ristricted with Client)

.PARAMETER Client
   Select this switch to Initialize setup for Deploy Client. (Ristricted with Server)

.PARAMETER NoOSUser
   Select this switch If you don't want to initialize Deploy User. (Ristricted with Server)

.PARAMETER NoPassSave
   Select this switch If you don't want to Save/Revise password. (Ristricted with Server)

.PARAMETER HostUsage
   set usage for the host. (Ristricted with Server)

.PARAMETER NoReboot
   Select this switch If you don't want to Reboot.

.PARAMETER Force
   Select this switch If you want to Forece Restart without prompt.

.PARAMETER TrustedHosts
   Input Trusted Hosts you want to enable. Default : "*"

.PARAMETER SkipEnablePSRemoting
   Select this switch If you want to skip setup PSRemoting.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Initialize-valentiaEnvironment -Server
--------------------------------------------
Setup Server Environment

.EXAMPLE
Setup Client Environment
--------------------------------------------
Initialize-valentiaEnvironment -Client

.EXAMPLE
Initialize-valentiaEnvironment -Client -NoOSUser
--------------------------------------------
Setup Client Environment and Skip Deploy OSUser creattion

.EXAMPLE
Setup Server Environment withour OSUser and Credential file revise
--------------------------------------------
read production-hoge.ps1 from c:\test.
#>
function Initialize-ValentiaEnvironment
{
    [CmdletBinding(DefaultParameterSetName = "Server")]
    param
    (
        [parameter(ParameterSetName = "Server")]
        [switch]$Server = $true,

        [parameter(ParameterSetName = "Client")]
        [switch]$Client = $false,

        [string]$HostUsage = "",

        [PSCredential]$Credential = $null,

        [string]$TrustedHosts = $valentia.wsman.TrustedHosts,

        [switch]$Force = $false,

        [switch]$NoOSUser = $false,

        [switch]$NoPassSave = $false,

        [switch]$NoReboot = $true,

        [switch]$SkipEnablePSRemoting = $false,

        [switch]$CredSSP = $false
    )

    process
    {
        if ($PSBoundParameters.ContainsKey("Verbose"))
        {
            [ordered]@{
                Server               = $Server
                Client               = $Client
                NoOSUser             = $NoOSUser
                NoPassSave           = $NoPassSave
                HostUsage            = $HostUsage
                NoReboot             = $NoReboot
                Force                = $Force
                TrustedHosts         = $TrustedHosts
                SkipEnablePSRemoting = $SkipEnablePSRemoting
                CredSSP              = $CredSSP
                Credential           = $Credential
            }
        }

        ExecutionPolicy
        FirewallNetWorkProfile
        if (-not($SkipEnablePSRemoting))
        {
            if ($CredSSP)
            {
                DisablePSRemotingCredSSP
            }

            EnablePSRemoting -SkipEnablePSRemoting $SkipEnablePSRemoting -TrustedHosts $TrustedHosts
            WSManConfiguration

            if ($CredSSP)
            {
                EnableCredSSP -TrustedHosts $TrustedHosts
            }
        }
        IESettings
        $cred = CredentialCheck -NoOSUser $NoOSUser -NoPassSave $NoPassSave -credential $credential
        OSUserSetup -NoOSUser $NoOSUser -credential $cred
        ServerSetup -server $Server -credential $cred
        HostnameSetup -HostUsage $HostUsage
        RebootCheck -NoReboot $NoReboot -Force $Force
    }
    
    end
    {
        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        if(-not(Test-ValentiaPowerShellElevated))
        {
            throw "Your PowerShell Console is not elevated! Must start PowerShell as an elevated to run this function because of UAC."
        }
        else
        {
            "Current session is already elevated, continue setup environment." | Write-ValentiaVerboseDebug
        }

        function ExecutionPolicy
        {
            Write-Host "Configuring ExecutionPolicy." -ForegroundColor Cyan
            "Set ExecutionPolicy to '{0}' only if execution policy is restricted." -f $valentia.ExecutionPolicy | Write-ValentiaVerboseDebug
            $executionPolicy = Get-ExecutionPolicy
            if ($executionPolicy -eq "Restricted")
            {
                Set-ExecutionPolicy $valentia.ExecutionPolicy -Force
            }
        }

        function FirewallNetWorkProfile
        {
            Write-Host "Configuring Firewall to accept PowerShell Remoting." -ForegroundColor Cyan
            if ([System.Environment]::OSVersion.Version -ge (New-Object 'Version' 6.2.0.0)) # over Win8/2012
            {
                "Enable WindowsPowerShell Remoting Firewall Rule." | Write-ValentiaVerboseDebug
                New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985

                "Set FireWall Status from Public to Private." | Write-ValentiaVerboseDebug
                if ((Get-NetConnectionProfile).NetworkCategory -ne "DomainAuthenticated")
                {
                    Set-NetConnectionProfile -NetworkCategory Private
                }
            }
            else
            {
                Write-Warning ("Your OS Version detected as '{0}', which is lower than 'Windows 8' or 'Windows Server 2012'. Skip setting Firewall rule and Network location." -f [System.Environment]::OSVersion.Version)
            }
        }

        function DisablePSRemotingCredSSP
        {
            Write-Host "Disabling PSRemoting and CredSSP" -ForegroundColor Cyan
            Start-Service winrm -PassThru 
            winrm invoke restore winrm/config

            Disable-PSRemoting -Force
            Disable-WSManCredSSP -Role Client
            Disable-WSManCredSSP -Role Server
            Stop-Service winrm
        }

        function EnablePSRemoting ($TrustedHosts)
        {
            Write-Host "Enabling PSRemoting" -ForegroundColor Cyan
            "Setup PSRemoting" | Write-ValentiaVerboseDebug
            Start-Service winrm -PassThru 
            Enable-PSRemoting -Force

            "Add $TrustedHosts hosts to trustedhosts" | Write-ValentiaVerboseDebug
            Enable-ValentiaWsManTrustedHosts -TrustedHosts $TrustedHosts

            "show winrm configuration result" | Write-ValentiaVerboseDebug
            winrm enumerate winrm/config/listener
        }

        function WSManConfiguration
        {
            Write-Host "Configure WSMan parameter." -ForegroundColor Cyan
            Set-ValetntiaWSManConfiguration
        }

        function EnableCredSSP ($TrustedHosts)
        {
            Write-Host "Enabling CredSSP" -ForegroundColor Cyan
            "Enable CredSSP for $TrustedHosts" | Write-ValentiaVerboseDebug
            Enable-ValentiaCredSSP -TrustedHosts $TrustedHosts
            
            "Enable winrm/Trustedhosts to registry AllowFreshCredentialsWhenNTLMOnly" | Write-ValentiaVerboseDebug
            Add-ValentiaCredSSPDelegateReg
            Add-ValentiaCredSSPDelegateRegKey
            Add-ValentiaCredSSPDelegateRegKeyProperty
        }

        function IESettings
        {
            Write-Host "Disable Enganced Security for Ineternet Explorer." -ForegroundColor Cyan
            "Disable Enhanced Security for Internet Explorer" | Write-ValentiaVerboseDebug
            Disable-ValentiaEnhancedIESecutiry
        }

        function CredentialCheck ($NoOSUser, $NoPassSave, [PSCredential]$credential = $null)
        {
            if ((-not $NoOSUser) -or (-not $NoPassSave))
            {
                if ($null -ne $credential)
                {
                    Write-Host "Credential information already passed. Skip Credential prompt." -ForegroundColor Cyan
                    return $credential
                }
                else
                {
                    Write-Host "Obtain PSCredential to set Credential information." -ForegroundColor Cyan
                    return (Get-Credential -Credential $valentia.users.deployUser)
                }
            }
        }

        function OSUserSetup ($NoOSUser, $credential)
        {
            Write-Host "Adding Deploy User." -ForegroundColor Cyan
            if ($NoOSUser)
            {
                "NoOSUser switch was enabled, skipping create OSUser." | Write-ValentiaVerboseDebug
            }
            else
            {
                "Add valentia connection user" | Write-ValentiaVerboseDebug
                New-ValentiaOSUser -Credential $credential
            }
        }

        function ServerSetup ($server, $credential)
        {
            if ($Server)
            {
                Write-Host "Add valentia DeployFolder." -ForegroundColor Cyan
                New-ValentiaFolder
            
                "Set Valentia credential in Windows Credential Manager." | Write-ValentiaVerboseDebug
                # validation
                if ($NoPassSave){ "NoPassSave switch was enabled, skipping Create/Revise set password into Windows Credential Manager." | Write-ValentiaVerboseDebug; return; }
                if ($null -eq $credential){ "Credential was empty. Skipping Create/Revise set password into Windows Credential Manager." | Write-ValentiaVerboseDebug; return; }

                "Create Deploy user credential .pass" | Write-ValentiaVerboseDebug
                Set-ValentiaCredential -Credential $credential
            }
        }

        function HostnameSetup ($HostUsage)
        {
            Write-Host "Check HostName configuration." -ForegroundColor Cyan
            if ($HostUsage -eq "")
            {
                "skipping Set HostName." | Write-ValentiaVerboseDebug
            }
            else
            {
                "Update HostName." | Write-ValentiaVerboseDebug
                Set-ValentiaHostName -HostUsage $HostUsage
            }
        }

        function RebootCheck ($NoReboot, $Force)
        {
            Write-Host "Check Reboot status." -ForegroundColor Cyan
            if(Get-ValentiaRebootRequiredStatus)
            {
                if ($NoReboot)
                {
                    Write-Host 'NoReboot switch was enabled, skipping reboot.' -ForegroundColor Cyan
                }
                elseif ($Force)
                {
                    Write-Host "Start Restart Force." -ForegroundColor Cyan
                    "Start Restart Force." | Write-ValentiaVerboseDebug
                    Restart-Computer -Force:$Force
                }
                else
                {
                    Write-Host "Start Restart with confirmation." -ForegroundColor Cyan
                    "Start Restart with confirmation." | Write-ValentiaVerboseDebug
                    Restart-Computer -Force:$Force -Confirm
                }
            }
        }
    }
}

# file loaded from path : \functions\Helper\Initialize\Initialize-ValentiaEnvironment.ps1

#Requires -Version 3.0

#-- Helper for valentia --#

# go
<#
.SYNOPSIS 
Move location to valentia folder

.DESCRIPTION
You can specify branch path in configuration.
If you changed from default, then change validation set for BranchPath for intellisence.

.NOTES
Author: guitarrapc
Created: 13/Jul/2013

.EXAMPLE
go
--------------------------------------------
just move to root deployment path.

.EXAMPLE
go application
--------------------------------------------
change location to BranchPath c:\deployment\application (in default configuration.)
#>
function Set-ValentiaLocation
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Select branch deploy folder to change directory.")]
        [ValentiaBranchPath]$BranchPath
    )

    begin
    {
        $prevLocation = (Get-Location).Path
        $newlocation = Join-Path $valentia.RootPath ([ValentiaBranchPath]::$BranchPath)
    }

    process
    {
        # Move to BrachPath if exist
        ("moving to new location as '{0}' : '{1}'" -f $BranchPath, $newlocation) | Write-ValentiaVerboseDebug
        if (Test-Path $newlocation)
        {
            Set-Location -Path $newlocation
        }
        else
        {
            throw "Path not found exception! Make sure {0} is exist." -f $newlocation
        }
    }

    end
    {
        ("moved Location : '{0}', previous Location : '{1}'" -f (Get-Location).Path, $prevLocation) | Write-ValentiaVerboseDebug
        if ((Get-Location).Path -ne $prevLocation)
        {
            ("Location change to '{0}'" -f (Get-Location).Path) | Write-ValentiaVerboseDebug
        }
        else
        {
            Write-Warning "Location not changed."
        }
    }
}

# file loaded from path : \functions\Helper\Location\Set-ValentiaLocation.ps1

#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Settings -- #

<#
.SYNOPSIS 
Setup Valentia Log Folder

.DESCRIPTION
Check Valentia Log folder and return log full path

.NOTES
Author: guitarrapc
Created: 18/Sep/2013

.EXAMPLE
New-ValentiaLog -LogFolder c:\logs\deployment -LogFile "hoge.log"
--------------------------------------------
This is format sample.

.EXAMPLE
New-ValentiaLog
--------------------------------------------
As New-ValentiaLog have default value in parameter, you do not required to specify log information
#>
function New-ValentiaLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Path to LogFolder.")]
        [string]$LogFolder = $(Join-Path $valentia.Log.path (Get-Date).ToString("yyyyMMdd")),

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Name of LogFile.")]
        [string]$LogFile = "$($valentia.Log.name)_$((Get-Date).ToString("yyyyMMdd_HHmmss"))$($valentia.Log.extension)"
    )


    if (-not(Test-Path $LogFolder))
    {
        ("LogFolder not found creating {0}" -f $LogFolder) | Write-ValentiaVerboseDebug
        New-Item -Path $LogFolder -ItemType Directory > $null
    }

    try
    {
        "Defining LogFile full path." | Write-ValentiaVerboseDebug
        $valentia.Log.fullPath = Join-Path $LogFolder $LogFile
    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        $ErrorCmdletName += ($MyInvocation.MyCommand).Name
        throw $_
    }

}

# file loaded from path : \functions\Helper\Log\New-ValentiaLog.ps1

#Requires -Version 3.0

#-- Helper for valentia --#
#-- End Result Execution -- #

function Out-ValentiaResult
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [System.Diagnostics.Stopwatch]$StopWatch,

        [parameter(Mandatory = 1)]
        [string]$Cmdlet,

        [parameter(Mandatory = 0)]
        [string]$TaskFileName = "",

        [parameter(Mandatory = 1)]
        [string[]]$DeployGroups,

        [parameter(Mandatory = 1)]
        [bool]$SkipException,

        [parameter(Mandatory = 1)]
        [bool]$Quiet
    )

    # obtain Result
    $CommandResult = [ordered]@{
        Success         = !($valentia.Result.SuccessStatus -contains $false)
        TimeStart       = $valentia.Result.TimeStart
        TimeEnd         = (Get-Date).DateTime
        TotalDuration   = $stopwatch.Elapsed.TotalSeconds
        Module          = "$($MyInvocation.MyCommand.Module)"
        Cmdlet          = $Cmdlet
        Alias           = "$((Get-Alias | where ResolvedCommandName -eq $Cmdlet).Name)"
        TaskFileName    = $TaskFileName
        ScriptBlock     = "{0}" -f $valentia.Result.ScriptTorun
        DeployGroup     = "{0}" -f "$($DeployGroups -join ', ')"
        TargetHostCount = $($valentia.Result.DeployMembers).count
        TargetHosts     = "{0}" -f ($valentia.Result.DeployMembers -join ', ')
        Result          = $valentia.Result.Result
        SkipException   = $SkipException
        ErrorMessage    = $($valentia.Result.ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
    }

    # show result
    WriteValentiaResultHost -quiet $Quiet -CommandResult $CommandResult

    # output result Log as json
    OutValentiaResultLog -CommandResult $CommandResult
}
# file loaded from path : \functions\Helper\Log\Out-ValentiaResult.ps1

#Requires -Version 3.0

#-- Helper for valentia --#
# - Out Log and Host -#

filter OutValentiaModuleLogHost
{        
    [CmdletBinding(DefaultParameterSetName = "message")]
    param
    (
        [parameter(mandatory = 0, position  = 0, valuefromPipeline = 1, ValuefromPipelineByPropertyName = 1)]
        [string]$logmessage,

        [parameter(mandatory = 0, position  = 1)]
        [string]$logfile = $valentia.log.fullpath,

        [parameter(mandatory = 0, position  = 2)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $valentia.fileEncode,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "message")]
        [switch]$message,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "showdata")]
        [switch]$showdata,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "hidedata")]
        [switch]$hidedata,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "hidedataAsString")]
        [switch]$hidedataAsString,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "warning")]
        [switch]$warning,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "verbosing")]
        [switch]$verbosing,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "error")]
        [switch]$error,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "result")]
        [switch]$result,

        [parameter(mandatory = 0, position  = 3, ParameterSetName = "resultAppend")]
        [switch]$resultAppend
    )

    process
    {
        if($message)
        {
            $item = "[$(Get-Date)][message][$_]"
            Write-Host "$item" -ForegroundColor Cyan
            $item | Out-File -FilePath $logfile -Encoding $encoding -Append -Force -Width 1048
        }
        elseif($showdata)
        {
            $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($hidedata)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($hideDataAsString)
        {
            $item = "[$(Get-Date)][message][$_]"
            $item | Out-File -FilePath $logfile -Encoding $encoding -Append -Force -Width 1048
        }
        elseif($warning)
        {
            Write-Warning $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($verbosing)
        {
            Write-Verbose $_
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($error)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Append -Width 512
        }
        elseif($result)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Force -Width 1048
        }
        elseif($resultAppend)
        {
            $_ | Out-File -FilePath $logfile -Encoding $encoding -Force -Width 1048 -Append
        }
    }
}
# file loaded from path : \functions\Helper\Log\Private\OutValentiaModuleLogHost.ps1

#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Output Result Settings -- #

function OutValentiaResultLog
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [System.Collections.Specialized.OrderedDictionary]$CommandResult,

        [parameter(Mandatory = 0)]
        [string]$removeProperty = "Result",

        [bool]$Append = $false
    )

    try
    {
        $json = $CommandResult | ConvertTo-Json
    }
    catch
    {
        $json = $CommandResult.Remove($removeProperty) | ConvertTo-Json
    }
    finally
    {
        if ($Append)
        {
            $json | OutValentiaModuleLogHost -resultAppend
        }
        else
        {
            $json | OutValentiaModuleLogHost -result
        }
    }
}
# file loaded from path : \functions\Helper\Log\Private\OutValentiaResultLog.ps1

#Requires -Version 3.0

#-- Helper for valentia --#
#-- Log Output Result Settings -- #

function WriteValentiaResultHost
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [bool]$quiet,

        [parameter(Mandatory = 1)]
        [System.Collections.Specialized.OrderedDictionary]$CommandResult
    )

    if (-not $quiet)
    {
        # Show Stopwatch for Total section
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $CommandResult.TotalDuration)
        [PSCustomObject]$CommandResult
    }
    else
    {
        ([PSCustomObject]$Commandresult).Success
    }
}
# file loaded from path : \functions\Helper\Log\Private\WriteValentiaResultHost.ps1

#Requires -Version 3.0

#-- Public Module Functions to load Task --#

# Task

<#
.SYNOPSIS 
Execute Task and push into CurrentContext

.NOTES
Author: guitarrapc
Created: 31/July/2014

.EXAMPLE
Push-ValentiaCurrentContextToTask -ScriptBlock $scriptBlock -TaskFileName $TaskFileName
#>
function Push-ValentiaCurrentContextToTask
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [ScriptBlock]$ScriptBlock,

        [parameter(Mandatory = 0)]
        [string]$TaskFileName
    )

    # Swtich ScriptBlock or ScriptFile was selected
    switch ($true)
    {
        {$ScriptBlock} {
            # run Task with ScriptBlock
            ("ScriptBlock parameter [ {0} ] was selected." -f $ScriptBlock) | Write-ValentiaVerboseDebug
            $taskkey = Task -name ScriptBlock -action $ScriptBlock

            # Read Current Context
            $currentContext = $valentia.context.Peek()
        }
        {$TaskFileName} {
            # check file exist or not
            if (-not(Test-Path (Join-Path (Get-Location).Path $TaskFileName)))
            {
                $TaskFileStatus = [PSCustomObject]@{
                    ErrorMessageDetail = "TaskFileName '{0}' not found in '{1}' exception!!" -f $TaskFileName,(Join-Path (Get-Location).Path $TaskFileName)
                    SuccessStatus = $false
                }             
                $valentia.Result.SuccessStatus += $TaskFileStatus.SuccessStatus
                $valentia.Result.ErrorMessageDetail += $TaskFileStatus.ErrorMessageDetail                    
            }
                
            # Read Task File and get Action to run
            ("TaskFileName parameter '{0}' was selected." -f $TaskFileName) | Write-ValentiaVerboseDebug

            # run Task $TaskFileName inside functions and obtain scriptblock written in.
            $taskkey = & $TaskFileName

            # Read Current Context
            $currentContext = $valentia.context.Peek()
        }
        default {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += "TaskFile or ScriptBlock parameter must not be null"
            throw "TaskFile or ScriptBlock parameter must not be null"
        }
    }

    return $currentContext.tasks.$taskKey
}

# file loaded from path : \functions\Helper\Prerequisites\Private\Push-ValentiaCurrentContextToTask.ps1

#Requires -Version 3.0

#-- Helper for valentia Invokation Prerequisite setup--#

function Set-ValentiaInvokationPrerequisites
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1)]
        [System.Diagnostics.Stopwatch]$StopWatch,

        [Parameter(Position = 0, Mandatory = 1)]
        [string[]]$DeployGroups,

        [Parameter(Position = 1, Mandatory = 0)]
        [string]$TaskFileName,

        [Parameter(Position = 2, Mandatory = 0)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(Position = 3, Mandatory = 0)]
        [string]$DeployFolder,

        [Parameter(Position = 4, Mandatory = 0)]
        [string[]]$TaskParameter
    )
    
    # clear previous result
    Invoke-ValentiaCleanResult

    # Initialize Error status
    $valentia.Result.SuccessStatus = $valentia.Result.ErrorMessageDetail = @()

    # Get Start Time
    $valentia.Result.TimeStart = (Get-Date).DateTime

    # Import default Configurations
    $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
    Import-ValentiaConfiguration

    # Import default Modules
    $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
    Import-valentiaModules

    # Log Setting
    New-ValentiaLog

    # Set Task and push CurrentContext
    $task = Push-ValentiaCurrentContextToTask -ScriptBlock $ScriptBlock -TaskFileName $TaskFileName
  
    # Set Task as CurrentContext with task key
    $valentia.Result.ScriptTorun = $task.Action

    # Obtain DeployMember IP or Hosts for deploy
    try
    {
        "Get host addresses to connect." | Write-ValentiaVerboseDebug
        $valentia.Result.DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
    }
    catch
    {
        $valentia.Result.SuccessStatus += $false
        $valentia.Result.ErrorMessageDetail += $_
        Write-Error $_
    }

    # Show Stopwatch for Begin section
    Write-Verbose ("{0}Duration Second for Begin Section: {1}" -f "`t`t", $Stopwatch.Elapsed.TotalSeconds)
}
# file loaded from path : \functions\Helper\Prerequisites\Private\Set-ValentiaInvokationPrerequisites.ps1

#Requires -Version 3.0

# -- helper function -- #

<#
.SYNOPSIS 
Show valentia Prompt For Choice description and will return item you passed.

.DESCRIPTION
You can show choice Description with your favored items.

.NOTES
Author: guitarrapc
Created: 17/Nov/2013

.EXAMPLE
Show-ValentiaPromptForChoice
--------------------------------------------
default will use what you have written in valentia-config.ps1

.EXAMPLE
Show-ValentiaPromptForChoice -questionHelps $(Show-ValentiaGroup).Name 
--------------------------------------------
Will check valentia deploy folder and get deploygroup files.
You can see choice description for each deploygroup file, and will get which item was selected.
#>
function Show-ValentiaPromptForChoice
{
    [CmdletBinding()]
    param
    (
        # input prompt items with array. second index is for help message.
        [parameter(mandatory = 0, position = 0)]
        [string[]]$questions = $valentia.promptForChoice.questions,

        # input title message showing when prompt.
        [parameter(mandatory = 0, position = 1)]
        [string[]]$title = $valentia.promptForChoice.title,
                
        # input message showing when prompt.
        [parameter(mandatory = 0, position = 2)]
        [string]$message = $valentia.promptForChoice.message,

        # input additional message showing under message.
        [parameter(mandatory = 0, position = 3)]
        [string]$additionalMessage = $valentia.promptForChoice.additionalMessage,
        
        # input Index default selected when prompt.
        [parameter(mandatory = 0, position = 4)]
        [int]$defaultIndex = $valentia.promptForChoice.defaultIndex
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    
    try
    {
        # create caption Messages
        if(-not [string]::IsNullOrEmpty($additionalMessage))
        {
            $message += ([System.Environment]::NewLine + $additionalMessage)
        }

        # create dictionary include dictionary <int, KV<string, string>> : accessing KV <string, string> with int key return from prompt
        $script:dictionary = New-Object 'System.Collections.Generic.Dictionary[int, System.Collections.Generic.KeyValuePair[string, string]]'
        
        foreach ($question in $questions)
        {
            if ("$questions" -eq "$($valentia.promptForChoice.questions)")
            {
                if ($private:count -eq 1)
                {
                    # create key to access value
                    $private:key = $valentia.promptForChoice.defaultChoiceNo
                }
                else
                {
                    # create key to access value
                    $private:key = $valentia.promptForChoice.defaultChoiceYes
                }
            }
            else
            {
                # create key to access value
                $private:key = [System.Text.Encoding]::ASCII.GetString($([byte[]][char[]]'a') + [int]$private:count)
            }

            # create KeyValuePair<string, string> for prompt item : accessing value with 1 letter Alphabet by converting char
            $script:keyValuePair = New-Object 'System.Collections.Generic.KeyValuePair[string, string]'($key, $question)
            
            # add to Dictionary
            $dictionary.Add($count, $keyValuePair)

            # increment to next char
            $count++

            # prompt limit to max 26 items as using single Alphabet charactors.
            if ($count -gt 26)
            {
                throw ("Not allowed to pass more then '{0}' items for prompt" -f ($dictionary.Keys).count)
            }
        }

        # create choices Collection
        $script:collectionType = [System.Management.Automation.Host.ChoiceDescription]
        $script:choices = New-Object "System.Collections.ObjectModel.Collection[$CollectionType]"

        # create choice description from dictionary<int, KV<string, string>>
        foreach ($dict in $dictionary.GetEnumerator())
        {
            foreach ($kv in $dict)
            {
                # create prompt choice item. Currently you could not use help message.
                $private:choice = (("{0} (&{1}){2}-" -f $kv.Value.Value, "$($kv.Value.Key)".ToUpper(), [Environment]::NewLine), ($valentia.promptForChoice.helpMessage -f $kv.Value.Key, $kv.Value.Value))

                # add to choices
                $choices.Add((New-Object $CollectionType $choice))
            }
        }

        # show choices on host
        $script:answer = $host.UI.PromptForChoice($title, $message, $choices, $defaultIndex)

        # return value from key
        return ($dictionary.GetEnumerator() | where Key -eq $answer).Value.Value
    }
    catch
    {
        throw $_
    }
}
# file loaded from path : \functions\Helper\PromptForChoice\Show-ValentiaPromptForChoice.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension  to Disable TaskScheduler Log Status

.DESCRIPTION
You can change TaskScheduler Log to State => Enable
Make sure Log affect to all TaskScheduler.

.NOTES
Author: guitarrapc
Created: 19/Sep/2014

.EXAMPLE
Disable-ValentiaScheduledTaskLogSetting

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Disable-ValentiaScheduledTaskLogSetting
{
    [CmdletBinding()]
    param()

    begin
    {
        $ErrorMessages = Data
        {
            ConvertFrom-StringData -StringData @"
                LogOperationNotPermitted = "Attempted to perform an unauthorized operation. You must elevate PowerShell Session to Change TaskSchedulerLog setting."
"@
        }
    }

    end
    {
        if (-not(Test-ValentiaPowerShellElevated)){ throw New-Object System.UnauthorizedAccessException ($ErrorMessages.LogOperationNotPermitted) }
        try
        {
            $logName = 'Microsoft-Windows-TaskScheduler/Operational'
            $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
            $log.IsEnabled = $false
            $log.SaveChanges()
        }
        finally
        {
            $log.Dispose()
        }
    }
}
# file loaded from path : \functions\Helper\ScheduledTask\Disable-ValentiaScheduledTaskLogSetting.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension  to Enable TaskScheduler Log Status

.DESCRIPTION
You can change TaskScheduler Log to State => Enable
Make sure Log affect to all TaskScheduler.

.NOTES
Author: guitarrapc
Created: 19/Sep/2014

.EXAMPLE
Enable-ValentiaScheduledTaskLogSetting

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Enable-ValentiaScheduledTaskLogSetting
{
    [CmdletBinding()]
    param()

    begin
    {
        $ErrorMessages = Data
        {
            ConvertFrom-StringData -StringData @"
                LogOperationNotPermitted = "Attempted to perform an unauthorized operation. You must elevate PowerShell Session to Change TaskSchedulerLog setting."
"@
        }
    }

    end
    {
        if (-not(Test-ValentiaPowerShellElevated)){ throw New-Object System.UnauthorizedAccessException ($ErrorMessages.LogOperationNotPermitted) }
        try
        {
            $logName = 'Microsoft-Windows-TaskScheduler/Operational'
            $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
            $log.IsEnabled = $true
            $log.SaveChanges()
        }
        finally
        {
            $log.Dispose()
        }
    }
}
# file loaded from path : \functions\Helper\ScheduledTask\Enable-ValentiaScheduledTaskLogSetting.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and Unregister Task you selected.

.DESCRIPTION
You can remove task and Empty folder if desired.

.NOTES
Author: guitarrapc
Created: 24/Sep/2014

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath

# remove Task from your selected path

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath -RemoveEmptyFolder $true

# remove Task and Empty Folder

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Get-ScheduledTask -TaskName hoge -TaskPath \fuga\ | Remove-ValentiaScheduledTask

# Remove ScheduledTask passed as CIMInstance

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Remove-ValentiaScheduledTask
{
    [CmdletBinding(DefaultParameterSetName="TaskName")]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ParameterSetName = "TaskName", ValueFrompipelineByPropertyName = 1)]
        [string]$taskName,
    
        [parameter(Mandatory = 0, Position  = 1, ParameterSetName = "TaskName", ValueFrompipelineByPropertyName = 1)]
        [string]$taskPath = "\",

        [parameter(Mandatory = 0, Position  = 1, ParameterSetName = "CimTask", ValueFrompipeline = 1)]
        [CimInstance[]]$InputObject,

        [parameter(Mandatory = 0,　Position  = 2)]
        [bool]$RemoveEmptyFolder = $false,

        [parameter(Mandatory = 0,　Position  = 3)]
        [bool]$Force = $false
    )

    end
    {
        $Confirm = !$Force

        if ($PSBoundParameters.ContainsKey('taskName'))
        {
            # exist
            $existingTaskParam = 
            @{
                TaskName = $taskName
                TaskPath = ValidateTaskPathLastChar -taskPath $taskPath
            }

            # Unregister Task
            $task = GetExistingTaskScheduler @existingTaskParam
            if (($task | measure).count -eq 0)
            {
                Write-Verbose ($VerboseMessages.TaskNotFound -f $existingTaskParam.taskName, $existingTaskParam.taskPath)
            }
            else
            {
                Write-Verbose ($VerboseMessages.RemoveTask -f $existingTaskParam.taskName, $existingTaskParam.taskPath)
                $task | Unregister-ScheduledTask -PassThru -Confirm:$Confirm
            }

        }
        else
        {
            $InputObject | Unregister-ScheduledTask -PassThru -Confirm:$confirm
        }

        # Remove Empty task folder
        if ($RemoveEmptyFolder){ Remove-ValentiaScheduledTaskEmptyDirectoryPath }
    }

    begin
    {
        $VerboseMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                RemoveTask = "Removing Task Scheduler Name '{0}', Path '{1}'"
                TaskNotFound = "Task not found for TaskName '{0}', TaskPath '{1}'. Skip execution."
"@
        }

        function GetExistingTaskScheduler ($TaskName, $TaskPath)
        {
            $task = Get-ScheduledTask | where TaskName -eq $taskName | where TaskPath -eq $taskPath
            return $task
        }

        function ValidateTaskPathLastChar ($taskPath)
        {
            $lastChar = [System.Linq.Enumerable]::ToArray($taskPath) | select -Last 1
            if ($lastChar -ne "\"){ return $taskPath + "\" }
            return $taskPath
        }
    }
}
# file loaded from path : \functions\Helper\ScheduledTask\Remove-ValentiaScheduledTask.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and Remove Task folder where Task not exist

.DESCRIPTION
You can remove task Empty folder. Normal Unregister Cmdlet never erase them and it may cause some issue like TaskScheduler could not name as same as child folder of TaskPath.

You can not create hoge task in root (\) when there are \hoge\ folder.

\
 -> \hoge\
 -> \Microsoft\


.NOTES
Author: guitarrapc
Created: 24/Sep/2014

.EXAMPLE
$param = @{
    taskName          = "hoge"
    Description       = "None"
    taskPath          = "\fuga"
    execute           = "powershell.exe"
    Argument          = '-Command "Get-Date | out-File c:\task01.log"'
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
    Runlevel          = "limited"
}
Set-ValentiaScheduledTask @param
Remove-ValentiaScheduledTask -taskName $param.taskName -taskPath $param.taskPath
Remove-ValentiaScheduledTaskEmptyDirectoryPath

# Remove task not exist any task or taskfolder.

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Remove-ValentiaScheduledTaskEmptyDirectoryPath
{
    # validate target Directory is existing
    $path = Join-Path $env:windir "System32\Tasks"
    $result = Get-ChildItem -Path $path -Directory | where Name -ne "Microsoft"
    if (($result | measure).count -eq 0){ return; }

    # validate Child is blank
    $result.FullName `
    | where {(Get-ChildItem -Path $_) -eq $null} `
    | Remove-Item -Force
}
# file loaded from path : \functions\Helper\ScheduledTask\Remove-ValentiaScheduledTaskEmptyDirectoryPath.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Extension to set TaskScheduler and define them as enumerable.

.DESCRIPTION
You can pass several task scheduler definition at once.

.NOTES
Author: guitarrapc
Created: 11/Aug/2014

.EXAMPLE
$param = @{
    taskName          = "Sample Repeatable Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]::Now
    ScheduledTimeSpan = (New-TimeSpan -Minutes 5)
    ScheduledDuration = ([TimeSpan]::MaxValue)
    Hidden            = $true
    Disable           = $false
    Force             = $true
},
@{
    taskName          = "Sample Daily Task"
    Description       = "None"
    taskPath          = "\"
    execute          = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]"00:00:00"
    Daily             = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
},
@{
    taskName          = "Sample OneTime Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]"00:30:00"
    Once              = $true
    Hidden            = $true
    Disable           = $false
    Force             = $true
}

$Credential = Get-ValentiaCredential

foreach ($p in $param.GetEnumerator())
{
    Set-ValentiaScheduledTask @p -Credential $Credential
}

# Multipole task With Credential

.EXAMPLE
$param = @{
    taskName          = "Sample No Credential Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]::Now
    ScheduledTimeSpan = (New-TimeSpan -Minutes 5)
    ScheduledDuration = ([TimeSpan]::MaxValue)
    Hidden            = $true
    Disable           = $false
    Force             = $true
}
Set-ValentiaScheduledTask @param

# single task without credential

.EXAMPLE
$param = @{
    taskName          = "Sample High Runlevel without Credential Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]::Now
    ScheduledTimeSpan = (New-TimeSpan -Minutes 5)
    ScheduledDuration = ([TimeSpan]::MaxValue)
    Hidden            = $true
    Disable           = $false
    Force             = $true
    RunLevel          = "Highest"
}
Set-ValentiaScheduledTask @param

# single task without credential and set Runlevel High

.EXAMPLE
$param = @{
    taskName          = "Sample High Runlevel with Credential Task"
    Description       = "None"
    taskPath          = "\"
    execute           = "PATH TO EXE"
    Argument          = ''
    ScheduledAt       = [datetime]::Now
    ScheduledTimeSpan = (New-TimeSpan -Minutes 5)
    ScheduledDuration = ([TimeSpan]::MaxValue)
    Hidden            = $true
    Disable           = $false
    Force             = $true
    RunLevel          = "Highest"
}
$Credential = Get-ValentiaCredential

Set-ValentiaScheduledTask @param -Credential $Credential

# single task with credential and set Runlevel High

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation

#>

function Set-ValentiaScheduledTask
{
    [CmdletBinding(DefaultParameterSetName = "ScheduledDuration")]
    param
    (
        [parameter(Mandatory = 0, Position  = 0)]
        [string]$Execute,

        [parameter(Mandatory = 0, Position  = 1)]
        [string]$Argument = "",
    
        [parameter(Mandatory = 0, Position  = 2)]
        [string]$WorkingDirectory = "",

        [parameter(Mandatory = 1, Position  = 3)]
        [string]$TaskName,
    
        [parameter(Mandatory = 0, Position  = 4)]
        [string]$TaskPath = "\",

        [parameter(Mandatory = 0, Position  = 5)]
        [datetime[]]$ScheduledAt,

        [parameter(Mandatory = 0, Position  = 6, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledTimeSpan = ([TimeSpan]::FromHours(1)),

        [parameter(Mandatory = 0, Position  = 7, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledDuration = [TimeSpan]::MaxValue,

        [parameter(Mandatory = 0, Position  = 8, parameterSetName = "Daily")]
        [bool]$Daily = $false,

        [parameter(Mandatory = 0, Position  = 9, parameterSetName = "Once")]
        [bool]$Once = $false,

        [parameter(Mandatory = 0, Position  = 10)]
        [string]$Description,

        [parameter(Mandatory = 0, Position  = 11)]
        [PScredential]$Credential = $null,

        [parameter(Mandatory = 0, Position  = 12)]
        [bool]$Disable = $true,

        [parameter(Mandatory = 0, Position  = 13)]
        [bool]$Hidden = $true,

        [parameter(Mandatory = 0, Position  = 14)]
        [TimeSpan]$ExecutionTimeLimit = ([TimeSpan]::FromDays(3)),

        [parameter(Mandatory = 0,Position  = 15)]
        [ValidateSet("At", "Win8", "Win7", "Vista", "V1")]
        [string]$Compatibility = "Win8",

        [parameter(Mandatory = 0,Position  = 16)]
        [ValidateSet("Highest", "Limited")]
        [string]$Runlevel = "Limited",

        [parameter(Mandatory = 0,　Position  = 17)]
        [bool]$Force = $false
    )

    end
    {
        Write-Verbose ($VerboseMessages.CreateTask -f $TaskName, $TaskPath)
        # exist
        $existingTaskParam = 
        @{
            TaskName = $TaskName
            TaskPath = $TaskPath
        }

        $currentTask = GetExistingTaskScheduler @existingTaskParam

    #region Exclude Action Change : Only Disable / Enable Task

        if (($Execute -eq "") -and (TestExistingTaskScheduler -Task $currentTask))
        {
            EnableDisableScheduleTask -Disable $Disable
            return;
        }

    #endregion

    #region Include Action Change

        # credential
        if($Credential -ne $null)
        {
            # Credential
            $credentialParam = @{
                User = $Credential.UserName
                Password = $Credential.GetNetworkCredential().Password
            }

            # Principal
            $principalParam = 
            @{
                UserId = $Credential.UserName
                RunLevel = $Runlevel
                LogOnType = "InteractiveOrPassword"
            }
        }

        # validation
        if ($Execute -eq ""){ throw New-Object System.InvalidOperationException ($ErrorMessages.ExecuteBrank) }
        if (Test-ValentiaPowerShellElevated)
        {
            if (TestExistingTaskSchedulerWithPath @existingTaskParam)
            {
                throw New-Object System.InvalidOperationException ($ErrorMessages.SameNameFolderFound -f $taskName)
            }
        }

        # Action
        $actionParam = 
        @{
            Argument = $Argument
            Execute = $Execute
            WorkingDirectory = $WorkingDirectory
        }

        # trigger
        $triggerParam =
        @{
            ScheduledTimeSpan = $scheduledTimeSpan
            ScheduledDuration = $scheduledDuration
            ScheduledAt = $ScheduledAt
            Daily = $Daily
            Once = $Once
        }

        # Description
        if ($Description -eq ""){ $Description = "No Description"}     

        # Setup Task items
        $action = CreateTaskSchedulerAction @actionParam
        $trigger = CreateTaskSchedulerTrigger @triggerParam
        $settings = New-ScheduledTaskSettingsSet -Disable:$Disable -Hidden:$Hidden -Compatibility $Compatibility -ExecutionTimeLimit $ExecutionTimeLimit
        $registerParam = if ($null -ne $Credential)
        {
            Write-Verbose $VerboseMessages.UsePrincipal
            $principal = New-ScheduledTaskPrincipal @principalParam
            $scheduledTask = New-ScheduledTask -Description $Description -Action $action -Settings $settings -Trigger $trigger -Principal $principal
            @{
                InputObject = $scheduledTask
                TaskName = $TaskName
                TaskPath = $TaskPath
                Force = $Force
            }
        }
        else
        {
            Write-Verbose $VerboseMessages.SkipPrincipal
            @{
                Action = $action
                Settings = $settings
                Trigger = $trigger
                Description = $Description
                TaskName = $TaskName
                TaskPath = $TaskPath
                Runlevel = $Runlevel
                Force = $Force
            }
        }

        # Register
        if ($force -or -not(TestExistingTaskScheduler -Task $currentTask))
        {
            if ($null -ne $Credential)
            {
                Register-ScheduledTask @registerParam @credentialParam
                return;
            }
            else
            {
                Register-ScheduledTask @registerParam
                return;
            }
        }

    #endregion
    }

    begin
    {
        $ErrorMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                InvalidTrigger = "Invalid Operation detected, you can't set same or greater timespan for RepetitionInterval '{0}' than RepetitionDuration '{1}'."
                ExecuteBrank = "Invalid Operation detected, Execute detected as blank. You must set executable string."
                SameNameFolderFound = "Already same FolderName existing as TaskPath : \\{0}\\ . Please change TaskName or Rename TaskFolder.."
"@
        }

        $VerboseMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                CreateTask = "Creating Task Scheduler Name '{0}', Path '{1}'"
                UsePrincipal = "Using principal with Credential. Execution will be fail if not elevated."
                SkipPrincipal = "Skip Principal and Credential. Runlevel Highest requires elevated."
"@
        }

        $WarningMessages = Data 
        {
            ConvertFrom-StringData -StringData @"
                TaskAlreadyExist = '"{0}" already exist on path "{1}". Please Set "-Force $true" to overwrite existing task.'
"@
        }

        function GetExistingTaskScheduler ($TaskName, $TaskPath)
        {
            return Get-ScheduledTask | where TaskName -eq $taskName | where TaskPath -eq $taskPath
        }

        function TestExistingTaskScheduler ($Task)
        {
            $result = ($task | Measure-Object).count -ne 0
            if ($result){ Write-Verbose ($WarningMessages.TaskAlreadyExist -f $task.taskName, $task.taskPath) }
            return $result
        }

        function TestExistingTaskSchedulerWithPath ($TaskName, $TaskPath)
        {
            if ($TaskPath -ne "\"){ return $false }

            # only run when taskpath is \
            $path = Join-Path $env:windir "System32\Tasks"
            $result = Get-ChildItem -Path $path -Directory | where Name -eq $TaskName

            if (($result | measure).count -ne 0)
            {
                return $true
            }
            return $false
        }

        function CreateTaskSchedulerAction ($Argument, $Execute, $WorkingDirectory)
        {
            if (($Argument -eq "") -and ($WorkingDirectory -eq ""))
            {
                return New-ScheduledTaskAction -Execute $execute
            }

            if (($Argument -ne "") -and ($WorkingDirectory -eq ""))
            {
                return New-ScheduledTaskAction -Execute $Execute -Argument $Argument
            }

            if (($Argument -ne "") -and ($WorkingDirectory -ne ""))
            {
                return New-ScheduledTaskAction -Execute $Execute -Argument $Argument -WorkingDirectory $WorkingDirectory
            }
        }

        function CreateTaskSchedulerTrigger ($ScheduledTimeSpan, $ScheduledDuration, $ScheduledAt, $Daily, $Once)
        {

            $trigger = if (($false -eq $Daily) -and ($false -eq $Once))
            {
                $ScheduledTimeSpanPair = New-ValentiaZipPairs -first $ScheduledTimeSpan -Second $ScheduledDuration
                $ScheduledAtPair = New-ValentiaZipPairs -first $ScheduledAt -Second $ScheduledTimeSpanPair
                $ScheduledAtPair `
                | %{
                    if ($_.Item2.Item1 -ge $_.Item2.Item2){ throw New-Object System.InvalidOperationException ($ErrorMessages.InvalidTrigger -f $_.Item2.Item1, $_.Item2.Item2)}
                    New-ScheduledTaskTrigger -At $_.Item1 -RepetitionInterval $_.Item2.Item1 -RepetitionDuration $_.Item2.Item2 -Once
                }
            }
            elseif ($Daily)
            {
                $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Daily}
            }
            elseif ($Once)
            {
                $ScheduledAt | %{New-ScheduledTaskTrigger -At $_ -Once}
            }
            return $trigger
        }

        function EnableDisableScheduleTask
        {
            [OutputType([Void])]
            [CmdletBinding()]
            param
            (
                [bool]$Disable
            )

            switch ($Disable)
            {
                $true {
                    $currentTask | Disable-ScheduledTask
                    return;
                }
                $false {
                    $currentTask | Enable-ScheduledTask
                    return;
                }
            }
        }
    }
}
# file loaded from path : \functions\Helper\ScheduledTask\Set-ValentiaScheduledTask.ps1

#Requires -Version 3.0

#-- Scheduler Task Functions --#

<#
.SYNOPSIS 
Test is TaskScheduler is same prameter.

.DESCRIPTION
You can test is scheduled task setting is desired.

.NOTES
Author: guitarrapc
Created: 23/Feb/2015

.EXAMPLE
$param = @{
    Execute = "powershell.exe"
    TaskName = "hoge"
    ScheduledAt = [datetime]"2015/1/1 0:0:0"
    Once = $true
}
Set-ValentiaScheduledTask @param -Force $true

Test-ValentiaScheduledTask `
-TaskName hoge `
-Execute "powershell.exe" -Verbose `

# This example is minimum testing and will return $true
# None passed parameter will skip checking

.EXAMPLE
Test-ValentiaScheduledTask `
-TaskName hoge `
-Execute "powershell.exe" `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Once $true

# You can add parameter for strict parameter checking.

.EXAMPLE
$param = @{
    Execute = "powershell.exe"
    Argument = "-Command ''"
    WorkingDirectory = ""
    Description = "hoge"
    TaskName = "hoge"
    TaskPath = "\hoge\"
    ScheduledAt = [datetime]"2015/1/1 0:0:0"
    #Daily = $true
    Once = $true
    Disable = $true
    Hidden = $true
    Credential = Get-ValentiaCredential
}
Set-ValentiaScheduledTask @param -Force $true

Test-ValentiaScheduledTask `
-TaskName hoge `
-TaskPath "\hoge\" `
-Execute "powershell.exe" `
-Argument "-Command ''" `
-Description hoge `
-Credential (Get-ValentiaCredential) `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Once $true

# Testing scheduled task would return true

.EXAMPLE
Test-ValentiaScheduledTask `
-TaskName hoge `
-TaskPath "\hoge\" `
-Execute "powershell.exe" `
-Argument "-Command ''" `
-Description hoge `
-Credential (Get-ValentiaCredential) `
-ScheduledAt ([datetime]"2015/01/1 0:0:0") `
-Daily $true -Debug -Verbose

# Testing scheduled task would return false as Daily is invalid. (Should check Once).
# You can check progress with -Debug and -Verbose switch

.LINK
https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation
#>
function Test-ValentiaScheduledTask
{
    [OutputType([bool])]
    [CmdletBinding(DefaultParameterSetName = "ScheduledDuration")]
    param
    (
        [parameter(Mandatory = 1, Position  = 0)]
        [string]$TaskName,
    
        [parameter(Mandatory = 0, Position  = 1)]
        [string]$TaskPath = "\",

        [parameter(Mandatory = 0, Position  = 2)]
        [string]$Execute,

        [parameter(Mandatory = 0, Position  = 3)]
        [string]$Argument,
    
        [parameter(Mandatory = 0, Position  = 4)]
        [string]$WorkingDirectory,

        [parameter(Mandatory = 0, Position  = 5)]
        [datetime[]]$ScheduledAt,

        [parameter(Mandatory = 0, Position  = 6, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledTimeSpan,

        [parameter(Mandatory = 0, Position  = 7, parameterSetName = "ScheduledDuration")]
        [TimeSpan[]]$ScheduledDuration,

        [parameter(Mandatory = 0, Position  = 8, parameterSetName = "Daily")]
        [bool]$Daily = $false,

        [parameter(Mandatory = 0, Position  = 9, parameterSetName = "Once")]
        [bool]$Once = $false,

        [parameter(Mandatory = 0, Position  = 10)]
        [string]$Description,

        [parameter(Mandatory = 0, Position  = 11)]
        [PScredential]$Credential,

        [parameter(Mandatory = 0, Position  = 12)]
        [bool]$Disable,

        [parameter(Mandatory = 0, Position  = 13)]
        [bool]$Hidden,

        [parameter(Mandatory = 0, Position  = 14)]
        [TimeSpan]$ExecutionTimeLimit = [TimeSpan]::FromDays(3),

        [parameter(Mandatory = 0,Position  = 15)]
        [ValidateSet("At", "Win8", "Win7", "Vista", "V1")]
        [string]$Compatibility,

        [parameter(Mandatory = 0,Position  = 16)]
        [ValidateSet("Highest", "Limited")]
        [string]$Runlevel
    )

    begin
    {
        function GetScheduledTask
        {
            [OutputType([HashTable])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance[]]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $true)]
                [string]$Value
            )

            Write-Debug ("Checking {0} is exists with : {1}" -f $parameter, $Value)
            $task = $root | where $Parameter -eq $Value
            $uniqueValue = $task.$Parameter | sort -Unique
            $result = $uniqueValue -eq $Value
            Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $uniqueValue)
            return @{
                task = $task
                result = $result
            }
        }

        function TestScheduledTask
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [ValentiaScheduledParameterType]$Type,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [PSObject]$Value,

                [bool]$IsExist
            )

            # skip when Parameter not use
            if ($IsExist -eq $false)
            {
                Write-Debug ("Skipping {0} as value not passed to function." -f $Parameter)
                return $true
            }

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value '{1}' is null." -f $Parameter, $Value)
                return $true
            }

            Write-Debug ("Checking {0} is match with : {1}" -f $Parameter, $Value)
            $target = switch ($Type)
            {
                ([ValentiaScheduledParameterType]::Root)
                {
                    $ScheduledTask.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Actions)
                {
                    $ScheduledTask.Actions.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Principal)
                {
                    $ScheduledTask.Principal.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Settings)
                {
                    $ScheduledTask.Settings.$Parameter | sort -Unique
                }
                ([ValentiaScheduledParameterType]::Triggers)
                {
                    $ScheduledTask.Triggers.$Parameter | sort -Unique
                }
            }
            
            # value check
            $result = $target -eq $Value
            Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $target)
            return $result
        }

        function TestScheduledTaskExecutionTimeLimit
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $false)]
                [TimeSpan]$Value
            )

            $private:parameter = "ExecutionTimeLimit"

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            Write-Debug ("Checking {0} is match with : {1}min" -f $parameter, $Value.TotalMinutes)
            $executionTimeLimitTimeSpan = [System.Xml.XmlConvert]::ToTimeSpan($ScheduledTask.Settings.$parameter)
            $result = $Value -eq $executionTimeLimitTimeSpan
            Write-Verbose ("{0} : {1} ({2}min)" -f $parameter, $result, $executionTimeLimitTimeSpan.TotalMinutes)
            return $result            
        }

        function TestScheduledTaskDisable
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $false)]
                [PSObject]$Value,

                [bool]$IsExist
            )

            # skip when Parameter not use
            if ($IsExist -eq $false)
            {
                Write-Debug ("Skipping {0} as value not passed to function." -f $Parameter)
                return $true
            }

            # convert Enable -> Disable
            $target = $ScheduledTask.Settings.Enabled -eq $false
            
            # value check
            Write-Debug ("Checking {0} is match with : {1}" -f "Disable", $Value)
            $result = $target -eq $Value
            Write-Verbose ("{0} : {1} ({2})" -f "Disable", $result, $target)
            return $result
        }

        function TestScheduledTaskScheduledAt
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $false)]
                [DateTime[]]$Value
            )

            $private:parameter = "StartBoundary"

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            $valueCount = ($Value | measure).Count
            $scheduleCount = ($ScheduledTask.Triggers | measure).Count
            if ($valueCount -ne $scheduleCount)
            {
                throw New-Object System.ArgumentException ("Argument length not match with current ScheduledAt {0} and passed ScheduledAt {1}." -f $scheduleCount, $valueCount)
            }

            $result = @()
            for ($i = 0; $i -le ($ScheduledTask.Triggers.$parameter.Count -1); $i++)
            {
                Write-Debug ("Checking {0} is match with : {1}" -f $parameter, $Value[$i])
                $startBoundaryDateTime = [System.Xml.XmlConvert]::ToDateTime(@($ScheduledTask.Triggers.$parameter)[$i])
                $result += @($Value)[$i] -eq $startBoundaryDateTime
                Write-Verbose ("{0} : {1} ({2})" -f $parameter, $result[$i], $startBoundaryDateTime)
            }
            return $result | sort -Unique
        }

        function TestScheduledTaskScheduledRepetition
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [Microsoft.Management.Infrastructure.CimInstance]$ScheduledTask,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [TimeSpan[]]$Value
            )

            # skip null
            if ($Value -eq $null)
            {
                Write-Debug ("Skipping {0} as passed value is null" -f $Parameter)
                return $true
            }

            $valueCount = ($Value | measure).Count
            $scheduleCount = ($ScheduledTask.Triggers | measure).Count
            if ($valueCount -ne $scheduleCount)
            {
                throw New-Object System.ArgumentException ("Arugument length not match with current ScheduledAt {0} and passed ScheduledAt {1}." -f $scheduleCount, $valueCount)
            }

            $result = @()
            for ($i = 0; $i -le ($ScheduledTask.Triggers.Repetition.$Parameter.Count -1); $i++)
            {
                Write-Debug ("Checking {0} is match with : {1}" -f $Parameter, $Value[$i])
                $target = [System.Xml.XmlConvert]::ToTimeSpan(@($ScheduledTask.Triggers.Repetition.$Parameter)[$i])
                $result = @($Value)[$i] -eq $target
                Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result[$i], $target.TotalMinutes)
            }
            return $result | sort -Unique
        }

        function TestScheduledTaskTriggerBy
        {
            [OutputType([bool])]
            [CmdletBinding()]
            param
            (
                [parameter(Mandatory = $true)]
                [System.Xml.XmlDocument]$ScheduledTaskXml,

                [parameter(Mandatory = $true)]
                [string]$Parameter,

                [parameter(Mandatory = $false)]
                [PSObject]$Value,

                [bool]$IsExist
            )

            # skip when Parameter not use
            if ($IsExist -eq $false)
            {
                Write-Debug ("Skipping {0} as value not passed to function." -f $Parameter)
                return $true
            }

            $trigger = ($ScheduledTaskXml.task.Triggers.CalendarTrigger.ScheduleByDay | measure).Count
            $result = $false
            switch ($Parameter)
            {
                "Daily"
                {
                    Write-Debug "Checking Trigger is : Daily"
                    $result = if ($Value)
                    {
                        $trigger -ne 0
                    }
                    else
                    {
                        $trigger-eq 0
                    }
                Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $trigger)
                }
                "Once"
                {
                    Write-Debug "Checking Trigger is : Once"
                    $result = if ($Value)
                    {
                        $trigger -eq 0
                    }
                    else
                    {
                        $trigger -ne 0
                    }
                    Write-Verbose ("{0} : {1} ({2})" -f $Parameter, $result, $trigger)
                }
            }
            return $result
        }
    }
    
    end
    {
        #region Root

            $private:result = $true

            # get whole task
            $root = Get-ScheduledTask

            # TaskPath
            $taskResult = GetScheduledTask -ScheduledTask $root -Parameter TaskPath -Value $TaskPath
            if ($taskResult.result -eq $false){ return $taskResult.Result; }

            # TaskName
            $taskResult = GetScheduledTask -ScheduledTask $taskResult.task -Parameter Taskname -Value $TaskName
            if ($taskResult.result -eq $false){ return $taskResult.Result; }

            # default
            $current = $taskResult.task
            if (($current | measure).Count -eq 0){ return $false }

            # export as xml
            [xml]$script:xml = Export-ScheduledTask -TaskName $current.TaskName -TaskPath $current.TaskPath

            # Description
            $result = TestScheduledTask -ScheduledTask $current -Parameter Description -Value $Description -Type ([ValentiaScheduledParameterType]::Root) -IsExist ($PSBoundParameters.ContainsKey('Description'))
            if ($result -eq $false){ return $result; }

        #endregion

        #region Action

            # Execute
            $result = TestScheduledTask -ScheduledTask $current -Parameter Execute -Value $Execute -Type ([ValentiaScheduledParameterType]::Actions) -IsExist ($PSBoundParameters.ContainsKey('Execute'))
            if ($result -eq $false){ return $result; }

            # Arguments
            $result = TestScheduledTask -ScheduledTask $current -Parameter Arguments -Value $Argument -Type ([ValentiaScheduledParameterType]::Actions) -IsExist ($PSBoundParameters.ContainsKey('Argument'))
            if ($result -eq $false){ return $result; }

            # WorkingDirectory
            $result = TestScheduledTask -ScheduledTask $current -Parameter WorkingDirectory -Value $WorkingDirectory -Type ([ValentiaScheduledParameterType]::Actions) -IsExist ($PSBoundParameters.ContainsKey('WorkingDirectory'))
            if ($result -eq $false){ return $result; }

        #endregion

        #region Principal

            # UserId
            $result = TestScheduledTask -ScheduledTask $current -Parameter UserId -Value $Credential.UserName -Type ([ValentiaScheduledParameterType]::Principal) -IsExist ($PSBoundParameters.ContainsKey('Credential'))
            if ($result -eq $false){ return $result; }

            # RunLevel
            $result = TestScheduledTask -ScheduledTask $current -Parameter RunLevel -Value $Runlevel -Type ([ValentiaScheduledParameterType]::Principal) -IsExist ($PSBoundParameters.ContainsKey('Runlevel'))
            if ($result -eq $false){ return $result; }

        #endregion

        #region Settings

            # Compatibility
            $result = TestScheduledTask -ScheduledTask $current -Parameter Compatibility -Value $Compatibility -Type ([ValentiaScheduledParameterType]::Settings) -IsExist ($PSBoundParameters.ContainsKey('Compatibility'))
            if ($result -eq $false){ return $result; }

            # ExecutionTimeLimit
            $result = TestScheduledTaskExecutionTimeLimit -ScheduledTask $current -Value $ExecutionTimeLimit
            if ($result -eq $false){ return $result; }

            # Hidden
            $result = TestScheduledTask -ScheduledTask $current -Parameter Hidden -Value $Hidden -Type ([ValentiaScheduledParameterType]::Settings) -IsExist ($PSBoundParameters.ContainsKey('Hidden'))
            if ($result -eq $false){ return $result; }

            # Disable
            $result = TestScheduledTaskDisable -ScheduledTask $current -Value $Disable -IsExist ($PSBoundParameters.ContainsKey('Disable'))
            if ($result -eq $false){ return $result; }

        #endregion

        #region Triggers

            # SchduledAt
            $result = TestScheduledTaskScheduledAt -ScheduledTask $current -Value $ScheduledAt
            if ($result -contains $false){ return $false; }

            # ScheduledTimeSpan (Repetition Interval)
            $result = TestScheduledTaskScheduledRepetition -ScheduledTask $current -Value $ScheduledTimeSpan -Parameter Interval
            if ($result -contains $false){ return $false; }

            # ScheduledDuration (Repetition Duration)
            $result = TestScheduledTaskScheduledRepetition -ScheduledTask $current -Value $ScheduledDuration -Parameter Duration
            if ($result -contains $false){ return $false; }

            # Daily
            $result = TestScheduledTaskTriggerBy -ScheduledTaskXml $xml -Parameter Daily -Value $Daily -IsExist ($PSBoundParameters.ContainsKey('Daily'))
            if ($result -eq $false){ return $result; }

            # Once
            $result = TestScheduledTaskTriggerBy -ScheduledTaskXml $xml -Parameter Once -Value $Once -IsExist ($PSBoundParameters.ContainsKey('Once'))
            if ($result -eq $false){ return $result; }

        #endregion

        return $result
    }
}
# file loaded from path : \functions\Helper\ScheduledTask\Test-ValentiaScheduledTask.ps1

#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

<#
.SYNOPSIS 
PowerShell Sed alternate function

.DESCRIPTION
This cmdlet replace string in the file as like as sed on linux

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-ValentiaSed -path D:\Deploygroup\*.ps1 -searchPattern "^10.0.0.10$" -replaceWith "#10.0.0.10" -overwrite
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and replace file. (like sed -f "s/^10.0.0.10$/#10.0.0.10" -i)

.EXAMPLE
Invoke-ValentiaSed -path D:\Deploygroup\*.ps1 -searchPattern "^#10.0.0.10$" -replaceWith "10.0.0.10"
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and not replace file.
#>
function Invoke-ValentiaSed
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 0, mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [string]$path,

        [parameter(position = 1, mandatory = 1, ValueFromPipeline = 1,ValueFromPipelineByPropertyName = 1)]
        [string]$searchPattern,

        [parameter(position = 2, mandatory = 1,ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [string]$replaceWith,

        [parameter(position = 3, mandatory = 0)]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $valentia.fileEncode,

        [parameter(position = 4, mandatory = 0)]
        [switch]$overWrite,

        [parameter(position = 5, mandatory = 0)]
        [switch]$compress
    )

    $read = Select-String -Path $path -Pattern $searchPattern -Encoding $encoding

    $read.path `
    | sort -Unique `
    | %{Write-Warning ("Executing string replace for '{0}'. 'overwrite': '{1}'." -f $path, ($PSBoundParameters.overWrite.IsPresent -eq $true))

        $path = $_
        $extention = [System.IO.Path]::GetExtension($path)

        if ($overWrite)
        {
            $tmpextension = "$extention" + "______"
            $tmppath = [System.IO.Path]::ChangeExtension($path,$tmpextension)

            ("execute replace string '{0}' with '{1}' for file '{2}', Output to '{3}'" -f $searchPattern, $replaceWith, $path, $tmppath) | Write-ValentiaVerboseDebug
            Get-Content -Path $path `
                | %{$_ -replace $searchPattern,$replaceWith} `
                | Out-File -FilePath $tmppath -Encoding $valentia.fileEncode -Force -Append

            ("remove original file '{0}'" -f $path, $tmppath) | Write-ValentiaVerboseDebug
            Remove-Item -Path $path -Force

            ("rename tmp file '{0}' to original file '{1}'" -f $tmppath, $path) | Write-ValentiaVerboseDebug
            Rename-Item -Path $tmppath -NewName ([System.IO.Path]::ChangeExtension($tmppath,$extention))
        }
        else
        {
            ("execute replace string '{0}' with '{1}' for file '{2}'" -f $searchPattern, $replaceWith, $path) | Write-ValentiaVerboseDebug
            if (-not $PSBoundParameters.Compress.IsPresent)
            {
                Get-Content -Path $path -Encoding $encoding `
                    | %{$_ -replace $searchPattern,$replaceWith}
            }
        }
    }
}
# file loaded from path : \functions\Helper\Sed\Invoke-ValentiaSed.ps1

#Requires -Version 3.0

#-- SymbolicLink Functions --#

<#
.SYNOPSIS 
This function will detect only SymbolicLink items.

.DESCRIPTION
PowerShell SymbolicLink function. Alternative to mklink Symbolic Link.
This function detect where input file fullpath item is file/directory SymbolicLink, then only Ennumerate if it is SymbolicLink.

.NOTES
Author: guitarrapc
Created: 12/Aug/2014

.EXAMPLE
ls d:\ | Get-ValentiaSymbolicLink
--------------------------------------------
Pipeline Input to detect SymbolicLink items.

.EXAMPLE
Get-ValentiaSymbolicLink (ls d:\).FullName
--------------------------------------------
Parameter Input to detect SymbolicLink items.
#>
function Get-ValentiaSymbolicLink
{
    [OutputType([System.IO.DirectoryInfo[]])]
    [cmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String[]]$Path
    )
    
    process
    {
        try
        {
            $Path `
            | %{
                if ($file = IsFile -Path $_)
                {
                    if (IsFileReparsePoint -Path $file.FullName)
                    {
                        # [Valentia.SymbolicLinkGet]::GetSymbolicLinkTarget()
                        # [System.Type]::GetType($typeQualifiedName)::GetSymbolicLinkTarget()
                        $symTarget = $SymbolicLinkGet::GetSymbolicLinkTarget($file.FullName)
                        Add-Member -InputObject $file -MemberType NoteProperty -Name SymbolicPath -Value $symTarget -Force
                        return $file
                    }
                }
                elseif ($directory = IsDirectory -Path $_)
                {
                    if (IsDirectoryReparsePoint -Path $directory.FullName)
                    {
                        # [Valentia.SymbolicLinkGet]::GetSymbolicLinkTarget()
                        # [System.Type]::GetType($typeQualifiedName)::GetSymbolicLinkTarget()
                        $symTarget = $SymbolicLinkGet::GetSymbolicLinkTarget($directory.FullName)
                        Add-Member -InputObject $directory -MemberType NoteProperty -Name SymbolicPath -Value $symTarget -Force
                        return $directory
                    }
                }
            }
        }
        catch
        {
            throw $_
        }
    }    

    begin
    {
        $private:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        try
        {
            $private:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
            $private:SymbolicCS = Join-Path $CSPath GetSymLink.cs -Resolve
            $private:sig = Get-Content -Path $SymbolicCS -Raw

            $private:addType = @{
                MemberDefinition = $sig
                Namespace        = "Valentia"
                Name             = "SymbolicLinkGet"
                UsingNameSpace   = "System.Text", "Microsoft.Win32.SafeHandles", "System.ComponentModel"
            }
            Add-ValentiaTypeMemberDefinition @addType -PassThru `
            | select -First 1 `
            | %{
                $SymbolicLinkGet = $_.AssemblyQualifiedName -as [type]
            }
        }
        catch
        {
            # catch Exception and ignore it
        }

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            Write-Verbose ('File attribute detected as ReparsePoint')
            $fileAttributes = [System.IO.FileAttributes]::Archive, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $attribute = [System.IO.File]::GetAttributes($Path)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
        }
    }
}
# file loaded from path : \functions\Helper\SymbolicLink\Get-ValentiaSymbolicLink.ps1

#Requires -Version 3.0

#-- SymbolicLink Functions --#

<#
.SYNOPSIS 
This function will Remove only SymbolicLink items.

.DESCRIPTION
PowerShell SymbolicLink function. Alternative to mklink Symbolic Link.
This function detect where input file fullpath item is file/directory SymbolicLink, then only remove if it is SymbolicLink.
You don't need to care about input Path is FileInfo or DirectoryInfo.

.NOTES
Author: guitarrapc
Created: 12/Aug/2014

.EXAMPLE
ls d:\ | Remove-ValentiaSymbolicLink
--------------------------------------------
Pipeline Input to detect SymbolicLink items.

.EXAMPLE
Remove-ValentiaSymbolicLink (ls d:\).FullName
--------------------------------------------
Parameter Input to detect SymbolicLink items.
#>
function Remove-ValentiaSymbolicLink
{
    [OutputType([Void])]
    [cmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String[]]$Path
    )
    
    process
    {
        try
        {
            $Path `
            | %{
                if ($file = IsFile -Path $_)
                {
                    if (IsFileReparsePoint -Path $file)
                    {
                        RemoveFileReparsePoint -Path $file
                    }
                }
                elseif ($directory = IsDirectory -Path $_)
                {
                    if (IsDirectoryReparsePoint -Path $directory)
                    {
                        RemoveDirectoryReparsePoint -Path $directory
                    }
                }           
            }
        }
        catch
        {
            throw $_
        }
    }    

    begin
    {
        $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            Write-Verbose ('File attribute detected as ReparsePoint')
            $fileAttributes = [System.IO.FileAttributes]::Archive, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $attribute = [System.IO.File]::GetAttributes($Path.fullname)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
        }

        function RemoveFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            [System.IO.File]::Delete($Path.FullName)
        }
        
        function RemoveDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            [System.IO.Directory]::Delete($Path.FullName)
        }
    }
}
# file loaded from path : \functions\Helper\SymbolicLink\Remove-ValentiaSymbolicLink.ps1

#Requires -Version 3.0

<#
.SYNOPSIS 
This function will Set SymbolicLink items for desired Path.

.DESCRIPTION
PowerShell SymbolicLink function. Alternative to mklink Symbolic Link.
This function will create Symbolic Link for input file fullpath.
Also it works as like LINQ Zip method for different number items was passed for each -Path and -SymbolicPath.
As Zip use minimal number item, this function also follow it.

.NOTES
Author: guitarrapc
Created: 12/Aug/2014

.EXAMPLE
ls d:\ `
| select -Last 2 `
| %{
    @{
        Path = $_.FullName
        SymbolicPath = Join-Path "d:\zzzzz" $_.Name
    }
} `
| Set-SymbolicLink -Verbose--------------------------------------------
Pipeline Input to create SymbolicLink items. This will make symbolic in d:\zzzz with samename of input Path name.
This means you can easily create Symbolic for different Path.

.EXAMPLE
Set-SymbolicLink -Path (ls d:\ | select -Last 2).FullName -SymbolicPath d:\hoge1, d:\hoge2, d:\hoge3 -Verbose
--------------------------------------------
Parameter Input. This will create Symbolic Link for -Path input 2 items, with -SymbolicPath input d:\hoge1 and d:\hoge2.
As number input was less with -Path, d:\hoge3 will be ignore.

#>
function Set-ValentiaSymbolicLink
{
    [OutputType([Void])]
    [cmdletBinding(DefaultParameterSetName = "ForceFile")]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('TargetPath')]
        [Alias('FullName')]
        [String[]]$Path,

        [parameter(Mandatory = 1, Position  = 1, ValueFromPipelineByPropertyName = 1)]
        [String[]]$SymbolicPath,

        [parameter(Mandatory = 0, Position  = 2, ValueFromPipelineByPropertyName = 1, ParameterSetName = "ForceFile")]
        [bool]$ForceFile = $false,

        [parameter(Mandatory = 0, Position  = 2, ValueFromPipelineByPropertyName = 1, ParameterSetName = "ForceDirectory")]
        [bool]$ForceDirectory = $false
    )
    
    process
    {
        # Work as like LINQ Zip() method
        $zip = New-ValentiaZipPairs -first $Path -second $SymbolicPath
        foreach ($x in $zip)
        {
            # reverse original key
            $targetPath = $x.item1
            $SymbolicNewPath = $x.item2

            if ($ForceFile -eq $true)
            {
                $SymbolicLinkSet::CreateSymLink($SymbolicNewPath, $Path, $false)
            }
            elseif ($ForceDirectory -eq $true)
            {
                $SymbolicLinkSet::CreateSymLink($SymbolicNewPath, $Path, $true)
            }
            elseif ($file = IsFile -Path $targetPath)
            {
                # Check File Type
                if (IsFileAttribute -Path $file)
                {
                    Write-Verbose ("symbolicPath : '{0}',  target : '{1}', isDirectory : '{2}'" -f $SymbolicNewPath, $file.fullname, $false)
                    # [Valentia.SymbolicLinkSet]::CreateSymLink()
                    $SymbolicLinkSet::CreateSymLink($SymbolicNewPath, $file.fullname, $false)
                }
            }
            elseif ($directory = IsDirectory -Path $targetPath)
            {
                # Check Directory Type
                if (IsDirectoryAttribute -Path $directory)
                {
                    Write-Verbose ("symbolicPath : '{0}',  target : '{1}', isDirectory : '{2}'" -f $SymbolicNewPath, $directory.fullname, $true)
                    # [Valentia.SymbolicLinkSet]::CreateSymLink()
                    $SymbolicLinkSet::CreateSymLink($SymbolicNewPath, $directory.fullname, $true)
                }
            } 
        }
    }    

    begin
    {
        $private:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        $prefix = "_"
        $i = 0 # Initialize prefix Length

        try
        {
            $private:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
            $private:SymbolicCS = Join-Path $CSPath CreateSymLink.cs -Resolve
            $private:sig = Get-Content -Path $SymbolicCS -Raw

            $private:addType = @{
                MemberDefinition = $sig
                Namespace        = "Valentia"
                Name             = "SymbolicLinkSet"
            }
            Add-ValentiaTypeMemberDefinition @addType -PassThru `
            | select -First 1 `
            | %{
                $SymbolicLinkSet = $_.AssemblyQualifiedName -as [type]
            }
        }
        catch
        {
            # catch Exception and ignore it
        }

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileAttribute ([System.IO.FileInfo]$Path)
        {
            $fileAttributes = [System.IO.FileAttributes]::Archive
            $attribute = [System.IO.File]::GetAttributes($Path.fullname)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as File Archive. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT File archive. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryAttribute ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as Directory. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT Directory. : {0}' -f $Path.Attributes)
                return $result
            }
        }
    }
}
# file loaded from path : \functions\Helper\SymbolicLink\Set-ValentiaSymbolicLink.ps1

#Requires -Version 3.0

#-- SymbolicLink Functions --#

<#
.SYNOPSIS 
This function will Test whether target path is Symbolic Link or not.

.DESCRIPTION
If target is Symbolic Link (reparse point), function will return $true.
Others, return $false.

.NOTES
Author: guitarrapc
Created: 12/Feb/2015

.EXAMPLE
Test-ValentiaSymbolicLink -Path "d:\SymbolicLink"
--------------------------------------------
As Path is Symbolic Link, this returns $true.

#>
function Test-ValentiaSymbolicLink
{
    [OutputType([System.IO.DirectoryInfo[]])]
    [cmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String]$Path
    )
    
    process
    {
        $result = Get-ValentiaSymbolicLink -Path $Path
        if ($null -eq $result){ return $false }
        return $true
    }

    begin
    {
        $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    }
}

# file loaded from path : \functions\Helper\SymbolicLink\Test-ValentiaSymbolicLink.ps1

#Requires -Version 3.0

#-- Helper Function --#

<#
.SYNOPSIS 
Convert PowerShell script to Valentia Task format

.DESCRIPTION
You can specify "filepath for PowerShell Script" or "scriptBlock".
This Cmldet will automatically add "task $taskname -Action {" on top and "}" on bottom.

.NOTES
Author: guitarrapc
Created: 18/Nov/2013

.EXAMPLE
ConvertTo-ValentiaTask -inputFilePath d:\hogehoge.ps1 -taskName hoge -outputFilePath d:\fuga.ps1
--------------------------------------------
Convert PowerShell Script written in inputFilePath into valentia Task file.

.EXAMPLE
ConvertTo-ValentiaTask -scriptBlock {ps} -taskName test -outputFilePath d:\test.ps1
--------------------------------------------
Convert ScriptBlock into valentia Task file.
#>
function ConvertTo-ValentiaTask
{
    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        # Path to PowerShell Script .ps1 you want to convert into Task
        [Parameter(Position = 0, Mandatory = 1, ParameterSetName = "File")]
        [string]$inputFilePath,
    
        # Path to PowerShell Script .ps1 you want to convert into Task
        [Parameter(Position = 1, Mandatory = 0, ParameterSetName = "File")]
        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$encoding = $valentia.fileEncode,

        # Script Block to Convert into Task
        [Parameter(Position = 0, Mandatory = 1, ParameterSetName = "Script")]
        [scriptBlock]$scriptBlock,

        # Task Name you want to set
        [Parameter(Position = 1, Mandatory = 1)]
        [string]$taskName,

        # Path to output Task
        [Parameter(Position = 2, Mandatory = 1)]
        [string]$outputFilePath
    )

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        if ($PSBoundParameters.inputFilePath)
        {
            if (Test-Path $inputFilePath)
            {
                $read = Get-Content -Path $inputFilePath -Encoding $encoding -Raw
            }
            else
            {
                throw ("Path not found exception. file path '{0}' not exists." -f $inputFilePath)
            }
        }
        elseif ($PSBoundParameters.scriptBlock)
        {
            $read = $scriptBlock
        }
    }

    process
    {
        try
        {
            # create String Builder
            $sb = New-Object System.Text.StringBuilder

            # append Header
            $sb.AppendLine($("Task {0} -Action {1}" -f $taskName,"{")) > $null

            # append Original source
            $sb.AppendLine($read) > $null

            # append end charactor
            $sb.AppendLine("}") > $null

            # serialize
            $output = $sb.ToString()
        }
        finally
        {
            $sb.Clear() > $null
        }
        
    }

    end
    {
        $output | Out-File -FilePath $outputFilePath -Encoding $valentia.fileEncode
    }
    
}
# file loaded from path : \functions\Helper\Task\ConvertTo-ValentiaTask.ps1

#Requires -Version 3.0

#-- Public Module Functions to load Task --#

# Task

<#
.SYNOPSIS 
Load Task File format into $valentia.context.tasks.$taskname hashtable.

.DESCRIPTION
Loading ps1 file which format is task <taskname> -Action { <scriptblock> }

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
task taskname -Action { What you want to do in ScriptBlock}
--------------------------------------------
This is format sample.

.EXAMPLE
task lstest -Action { Get-ChildItem c:\ }
--------------------------------------------
Above example will create taskkey as lstest, run "Get-ChildItem c:\" when invoke.
#>
function Get-ValentiaTask
{
    [CmdletBinding()]  
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input TaskName you want to set and not dupricated.")]
        [string]$Name = $null,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Write ScriptBlock Action to execute with this task.")]
        [scriptblock]$Action = $null
    )

    # Load Task
    Write-Verbose $valeWarningMessages.warn_import_task_begin
    $newTask = @{
        Name = $Name
        Action = $Action
    }

    # convert into LowerCase for keyname
    Write-Verbose $valeWarningMessages.warn_import_task_end
    $taskKey = $Name.ToLower()

    # Get current context variables
    Write-Verbose $valeWarningMessages.warn_get_current_context
    $currentContext = $valentia.context.Peek()

    # Check dupricate key name
    if ($currentContext.tasks.ContainsKey($taskKey))
    {
        throw $valeErrorMessages.error_duplicate_task_name -F $Name
    }
    else
    {
        $valeWarningMessages.warn_set_taskkey | Write-ValentiaVerboseDebug
        $currentContext.tasks.$taskKey = $newTask
    }

    # return taskkey to determin key name in $valentia.context.tasks.$taskkey
    return $taskKey

}

# file loaded from path : \functions\Helper\Task\Get-ValentiaTask.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Create New Local User for Deployment

.DESCRIPTION
Deployment will use deploy user account credential to avoid any change for administartor.
You must add all this user credential for each clients.

# User Flag Property Samples. You should combinate these 0x00zz if required.
#
#  &H0001    Run LogOn Script　
#  0X0001    ADS_UF_SCRIPT 
#
#  &H0002    Account Disable
#  0X0002    ADS_UF_ACCOUNTDISABLE
#
#  &H0008    Account requires Home Directory
#  0X0008    ADS_UF_HOMEDIR_REQUIRED
#
#  &H0010    Account Lockout
#  0X0010    ADS_UF_LOCKOUT
#
#  &H0020    No Password reqyured for account
#  0X0020    ADS_UF_PASSWD_NOTREQD
#
#  &H0040    No change Password
#  0X0040    ADS_UF_PASSWD_CANT_CHANGE
#
#  &H0080    Allow Encypted Text Password
#  0X0080    ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED
#
#  0X0100    ADS_UF_TEMP_DUPLICATE_ACCOUNT
#  0X0200    ADS_UF_NORMAL_ACCOUNT
#  0X0800    ADS_UF_INTERDOMAIN_TRUST_ACCOUNT
#  0X1000    ADS_UF_WORKSTATION_TRUST_ACCOUNT
#  0X2000    ADS_UF_SERVER_TRUST_ACCOUNT
#
#  &H10000   Password infinit
#  0X10000   ADS_UF_DONT_EXPIRE_PASSWD
#
#  0X20000   ADS_UF_MNS_LOGON_ACCOUNT
#
#  &H40000   Smart Card Required
#  0X40000   ADS_UF_SMARTCARD_REQUIRED
#
#  0X80000   ADS_UF_TRUSTED_FOR_DELEGATION
#  0X100000  ADS_UF_NOT_DELEGATED
#  0x200000  ADS_UF_USE_DES_KEY_ONLY
#
#  0x400000  ADS_UF_DONT_REQUIRE_PREAUTH
#
#  &H800000  Password expired
#  0x800000  ADS_UF_PASSWORD_EXPIRED
#
#  0x1000000 ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaOSUser
--------------------------------------------
Recommend - Secure Input.
secure prompt will up and mask your PASSWORD input as *****.

.EXAMPLE
New-valentiaOSUser -Password "1231231qawerqwe87$%"
--------------------------------------------
NOT-Recommend - Unsecure Input
Visible prompt will up and non-mask your PASSWORD input as *****.
#>
function New-ValentiaOSUser
{
    [CmdletBinding()]
    param
    (
        [parameter(position  = 0, mandatory = 0, HelpMessage = "PSCredential for New OS User setup.")]
        [PSCredential]$credential = (Get-Credential -Credential $valentia.users.deployUser),

        [parameter(position  = 1, mandatory = 0, HelpMessage = "User account belonging UserGroup.")]
        [string]$Group = $valentia.group.Name,

        [parameter(position  = 2, mandatory = 0, HelpMessage = "User flag bit to set.")]
        [string]$UserFlag = $valentia.group.userFlag
    )

    process
    {
        if ($IsUserExist)
        {
            Set-UserPassword @paramUser
        }
        else
        {
            New-User @paramUser
        }

        $Domain= Get-DomainName
        $paramUserFlag = @{
            targetUser = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0}/{1}/{2}" -f $Domain, $HostPC, $user))
            UserFlag   = $UserFlag
        }
        Set-UserFlag @paramUserFlag
        
        if ((Get-UserAndGroup @paramUserAndGroup).Groups -ne $Group)
        {
            Add-UserToUserGroup @paramGroup
        }
    }

    end
    {
        Get-UserAndGroup @paramUserAndGroup
    }

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        $HostPC = [System.Environment]::MachineName
        $user = $credential.UserName
        $DirectoryComputer = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0},computer" -f $HostPC))
        $IsUserExist = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount='true'" | where Name -eq $user

        $paramUser = @{
            user       = $user
            HostPC     = $HostPC
            Credential = $credential
        }

        $paramGroup = @{
            Group  = $Group
            HostPC = $HostPC
            user   = $user
        }

        $paramUserAndGroup = @{
            DirectoryComputer = $DirectoryComputer
            user              = $user
        }

        function Get-DomainName
        {
            if ((Get-WMIObject Win32_ComputerSystem).PartOfDomain)
            {
                $dn = (Get-CimInstance -ClassName win32_computersystem).Domain
                return (Get-CimInstance -ClassName Win32_NTDomain | where DNSForestName -eq $dn).DomainName
            }
            else
            {
                return (Get-CimInstance -ClassName win32_computersystem).Domain
            }
        }

        function New-User ($user, $HostPC, $credential)
        {
            ("User '{0}' not exist, start creating user." -f $user) | Write-ValentiaVerboseDebug
            $NewUser = $DirectoryComputer.Create("user", $user)
            $NewUser.SetPassword(($credential.GetNetworkCredential().password))
            $NewUser.SetInfo()
        }

        function Set-UserPassword ($user, $HostPC, $credential)
        {
            ("User '{0}' already exist, start reset password." -f $user) | Write-ValentiaVerboseDebug
            $SetUser = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0}/{1}" -f $HostPC, $user))
            $SetUser.psbase.invoke('SetPassword', $credential.GetNetworkCredential().Password)
        }

        function Set-UserFlag ($targetUser, $UserFlag)
        {
            "Set userflag to define account as bor '{0}'" -f $UserFlag | Write-ValentiaVerboseDebug
            $userFlags = $targetUser.Get("UserFlags")
            $userFlags = $userFlags -bor $UserFlag 
            $targetUser.Put("UserFlags", $userFlags)
            $targetUser.SetInfo()
        }

        function Add-UserToUserGroup ($Group, $HostPC, $user)
        {
            ("Assign User to UserGroup '{0}'" -f $Group) | Write-ValentiaVerboseDebug
            $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
            $DirectoryGroup.Add(("WinNT://{0}/{1}" -f $HostPC, $user))
        }

        function Get-UserAndGroup ($DirectoryComputer, $user)
        {
            $DirectoryComputer.Children `
            | where SchemaClassName -eq 'user' `
            | where Name -eq $user `
            | %{ 
                $groups = $_.Groups() | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
                $_ | %{
                    [PSCustomObject]@{
                        UserName = $_.Name
                        Groups   = $groups
                    }
                }
            }
        }
    }
}

# file loaded from path : \functions\Helper\User\New-ValentiaOSUser.ps1

function New-ValentiaZipPairs
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0, Position = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1)]
        [PSObject[]]$first,
 
        [parameter(Mandatory = 0, Position = 1, ValueFromPipelineByPropertyName = 1)]
        [PSObject[]]$second,

        [parameter(Mandatory = 0, Position = 2, ValueFromPipelineByPropertyName = 1)]
        [scriptBlock]$resultSelector
    )

    process
    {
        if ([string]::IsNullOrWhiteSpace($first)){ break }        
        if ([string]::IsNullOrWhiteSpace($second)){ break }
        
        try
        {
            $e1 = @($first).GetEnumerator()

            while ($e1.MoveNext() -and $e2.MoveNext())
            {
                if ($PSBoundParameters.ContainsKey('resultSelector'))
                {
                    $first = $e1.Current
                    $second = $e2.Current
                    $context = $resultselector.InvokeWithContext(
                        $null,
                        ($psvariable),
                        {
                            (New-Object System.Management.Automation.PSVariable ("first", $first)),
                            (New-Object System.Management.Automation.PSVariable ("second", $second))
                        }
                    )
                    $context
                }
                else
                {
                    $tuple = New-Object 'System.Tuple[PSObject, PSObject]' ($e1.Current, $e2.current)
                    $tuple
                }
            }
        }
        finally
        {
            if(($d1 = $e1 -as [IDisposable]) -ne $null) { $d1.Dispose() }
            if(($d2 = $e2 -as [IDisposable]) -ne $null) { $d2.Dispose() }
            if(($d3 = $psvariable -as [IDisposable]) -ne $null) {$d3.Dispose() }
            if(($d4 = $context -as [IDisposable]) -ne $null) {$d4.Dispose() }
            if(($d5 = $tuple -as [IDisposable]) -ne $null) {$d5.Dispose() }
        }
    }

    begin
    {
        $e2 = @($second).GetEnumerator()
        $psvariable = New-Object 'System.Collections.Generic.List[System.Management.Automation.psvariable]'
    }
}
# file loaded from path : \functions\Helper\Utils\New-ValentiaZpPairs.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Get reboot require status for client

.DESCRIPTION
When Windows Update or Change Hostname event is done, it will requires reboot to take change effect.
You can obtain reboot required status with this cmdlet.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Get-ValentiaRebootRequiredStatus
--------------------------------------------
Obtain reboot required status.
#>
function Get-ValentiaRebootRequiredStatus
{
    [CmdletBinding()]
    param
    (
    )

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        $WindowsUpdateRebootStatus = $false
        $FileRenameRebootStatus = $false
        $WindowsUpdateRebootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        $FileRenameRebootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    }

    process
    {
        if (Test-Path $WindowsUpdateRebootPath)
        {
            $WindowsUpdateRebootStatus = $true
        }


        if (Get-ItemProperty -Path $FileRenameRebootPath | Get-Member -MemberType NoteProperty | where Name -eq "PendingFileRenameOperations")
        {
            $FileRenameRebootStatus = $True
        }

        $Result = [PSCustomObject]@{
            ComputerName = [Net.DNS]::GetHostName()
            PendingWindowsUpdateReboot= $WindowsUpdateRebootStatus
            PendingFileRenameReboot = $FileRenameRebootStatus
        }

    }

    end
    {
        return $Result
    }

}
# file loaded from path : \functions\Helper\Windows\Get-ValentiaRebootRequiredStatus.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

# rename

<#
.SYNOPSIS 
Change Computer name as specified usage.

.DESCRIPTION
To control hosts, set prefix for each client with IPAddress octets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-valentiaHostName -HostUsage web
--------------------------------------------
Change Hostname as web-$PrefixHostName-$PrefixIpString-Ip1-Ip2-Ip3-Ip4
#>
function Set-ValentiaHostName
{
    [CmdletBinding()]  
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "set usage for the host.")]
        [string]$HostUsage,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Set Prefix IpString for hostname if required.")]
        [string]$PrefixIpString = $valentia.prefic.ipstring,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Set this switch to check whatif.")]
        [switch]$WhatIf
    )

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        # Get IpAddress
        $ipAddress = ([Net.Dns]::GetHostAddresses('').IPAddressToString | Select-String -Pattern "^\d*.\.\d*.\.\d*.\.\d*.").line

        # Replace . of IpAddress to -
        $ipAddressString = $ipAddress -replace "\.","-"

        # Create New Host Name
        $newHostName = $HostUsage + "-" + $PrefixIpString + $ipAddressString

        $currentHostName = [Net.Dns]::GetHostName()
    }
    
    process
    {
        if ( $currentHostName -eq $newHostName)
        {
            Write-Verbose ("Current HostName [ {0} ] was same as new HostName [ {1} ]. Nothing Changed." -f $currentHostName, $newHostName)
        }
        else
        {
            if ($PSBoundParameters.WhatIf.IsPresent -ne $true)
            {
                Write-Warning -Message ("Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
                Rename-Computer -NewName $newHostName -Force
            }
            else
            {
                $Host.UI.WriteLine("what if: Current HostName [ {0} ] change to New HostName [ {1} ]" -f $currentHostName, $newHostName)
            }
        }
    }
}

# file loaded from path : \functions\Helper\Windows\Set-ValentiaHostName.ps1

#Requires -Version 3.0

#-- Helper function --#

#-- Check Current PowerShell session is elevated or not --#

<#
.SYNOPSIS
    Retrieve elavated status of PowerShell Console.

.DESCRIPTION
    Test-ValentiaPowerShellElevated will check shell was elevated is required for some operations access to system folder, files and objects.
      
.NOTES
    Author: guitarrapc
    Date:   June 17, 2013

.OUTPUTS
    bool

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated
    true

.EXAMPLE
    C:\PS> Test-ValentiaPowerShellElevated
    false        
#>
function Test-ValentiaPowerShellElevated
{
    [CmdletBinding()]
    param
    (
    )

    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# file loaded from path : \functions\Helper\Windows\Private\Test-ValentiaPowerShellElevated.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Enable WsMan Trusted hosts

.DESCRIPTION
Specify Trustedhosts to allow

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Enable-WsManTrustedHosts
--------------------------------------------
allow all hosts as * 
#>
function Enable-ValentiaWsManTrustedHosts
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Specify TrustedHosts to allow.")]
        [string]$TrustedHosts,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Specify path to WSMan TrustedHosts.")]
        [string]$TrustedHostsPath = "WSman:localhost\client\TrustedHosts"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-ChildItem $TrustedHostsPath).Value -eq $TrustedHosts))
    {
        Set-Item -Path $TrustedHostsPath -Value $TrustedHosts -Force
    }
    else
    {
        ("WinRM Trustedhosts was alredy enabled for {0}." -f $TrustedHosts) | Write-ValentiaVerboseDebug
        Get-ChildItem $TrustedHostsPath
    }
}


# file loaded from path : \functions\Helper\WsMan\Enable-WsManTrustedHosts.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Set WsMan Max Memory Per user to prevent PowerShell failed with large memory usage. 

.DESCRIPTION
This user is allowed a maximum memory. 0 will be unlimited.
Default value : 1024 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 15/Feb/2014

.EXAMPLE
Set-ValentiaWsManMaxMemoryPerShellMB -MaxMemoryPerShellMB 0
--------------------------------------------
set as unlimited
#>
function Set-ValentiaWsManMaxMemoryPerShellMB
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input MaxMemoryPerShellMB. 0 will be unlimited.")]
        [int]$MaxMemoryPerShellMB,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Set WSMan Path.")]
        [string]$MaxMemoryPerShellMBPath = "WSMan:\localhost\Shell\MaxMemoryPerShellMB"
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest
    
    if (-not((Get-ChildItem $MaxMemoryPerShellMBPath).Value -eq $MaxMemoryPerShellMB))
    {
        Set-Item -Path $MaxMemoryPerShellMBPath -Value $MaxMemoryPerShellMB -Force -PassThru
    }
    else
    {
        ("Current value for MaxMemoryPerShellMB is {0}." -f $MaxMemoryPerShellMB) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxMemoryPerShellMBPath
    }
}

# file loaded from path : \functions\Helper\WsMan\Set-ValentiaWsManMaxMemoryPerShellMB.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Set WsMan Max Proccesses Per Shell. 

.DESCRIPTION
Unlimit process.
Default value : 100 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 15/Feb/2014

.EXAMPLE
Set-ValentiaWsManMaxProccessesPerShell -MaxProccessesPerShell 0
--------------------------------------------
set as 100
#>
function Set-ValentiaWsManMaxProccessesPerShell
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input MaxProccessesPerShell value.")]
        [int]$MaxProccessesPerShell,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Set path to WSMan MaxProccessesPerShell.")]
        [string]$MaxProccessesPerShellPath = "WSMan:\localhost\Shell\MaxProcessesPerShell"
    )
    
    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-ChildItem $MaxProccessesPerShellPath).Value -eq $MaxProccessesPerShell))
    {
        Set-Item -Path $MaxProccessesPerShellPath -Value $MaxProccessesPerShell -Force -PassThru
    }
    else
    {
        ("Current value for MaxShellsPerUser is {0}." -f $MaxProccessesPerShell) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxProccessesPerShellPath
    }
}

# file loaded from path : \functions\Helper\WsMan\Set-ValentiaWsManMaxProccessesPerShell.ps1

#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Set WsMan Max Shells Per user to prevent "The WS-Management service cannot process the request. 

.DESCRIPTION
This user is allowed a maximum number of xx concurrent shells, which has been exceeded."
Default value : 25 (Windows Server 2012)

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Set-ValentiaWsManMaxShellsPerUser -ShellsPerUser 100
--------------------------------------------
set as 100
#>
function Set-ValentiaWsManMaxShellsPerUser
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input ShellsPerUser count.")]
        [int]$ShellsPerUser,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Set path to WSMan MaxShellsPerUser.")]
        [string]$MaxShellsPerUserPath = "WSMan:\localhost\Shell\MaxShellsPerUser"
    )
    
    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    if (-not((Get-ChildItem $MaxShellsPerUserPath).Value -eq $ShellsPerUser))
    {
        Set-Item -Path $MaxShellsPerUserPath -Value $ShellsPerUser -Force -PassThru
    }
    else
    {
        ("Current value for MaxShellsPerUser is {0}." -f $ShellsPerUser) | Write-ValentiaVerboseDebug
        Get-ChildItem $MaxShellsPerUserPath
    }
}

# file loaded from path : \functions\Helper\WsMan\Set-ValentiaWsManMaxShellsPerUser.ps1

#Requires -Version 3.0

#-- Public Functions for WSMan Parameter Configuration --#

function Set-ValetntiaWSManConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'")]
        [ValidateNotNullOrEmpty()]
        [int]$ShellsPerUser = $valentia.wsman.MaxShellsPerUser,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'")]
        [ValidateNotNullOrEmpty()]
        [int]$MaxMemoryPerShellMB = $valentia.wsman.MaxMemoryPerShellMB,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Configure WSMan MaxProccessesPerShell to improve performance")]
        [ValidateNotNullOrEmpty()]
        [int]$MaxProccessesPerShell = $valentia.wsman.MaxProccessesPerShell
    )

    $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    Set-StrictMode -Version latest

    "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'" | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxShellsPerUser -ShellsPerUser $ShellsPerUser

    "Configure WSMan MaxMBPerUser to prevent huge memory consumption crach PowerShell issue." | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxMemoryPerShellMB -MaxMemoryPerShellMB $MaxMemoryPerShellMB

    "Configure WSMan MaxProccessesPerShell to improve performance" | Write-ValentiaVerboseDebug
    Set-ValentiaWsManMaxProccessesPerShell -MaxProccessesPerShell $MaxProccessesPerShell

    "Restart-Service WinRM -PassThru" | Write-ValentiaVerboseDebug
    Restart-Service WinRM -PassThru
}
# file loaded from path : \functions\Helper\WsMan\Set-ValetntiaWSManConfiguration.ps1

#Requires -Version 3.0

#-- Public Module Job / Functions for Remote Execution --#

# vale

<#
.SYNOPSIS 
1 of invoking valentia by PowerShell Backgroud Job execution to remote host

.DESCRIPTION
Run Job valentia execution to remote host

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  vale 192.168.1.100 {Get-ChildItem}
--------------------------------------------
Get-ChildItem ScriptBlock execute on 192.168.1.100

.EXAMPLE
  vale 192.168.1.100 {Get-ChildItem; hostname}
--------------------------------------------
You can run multiple script in pipeline.

.EXAMPLE
  vale 192.168.1.100 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

.EXAMPLE
  vale 192.168.1.100,192.168.1.200 .\default.ps1
--------------------------------------------
You can target multiple deploymember with comma separated. Running Synchronously.

.EXAMPLE
  vale DeployGroupFile.ps1 {ScriptBlock}
--------------------------------------------
Specify DeployGroupFile and ScriptBlock

.EXAMPLE
  vale DeployGroupFile.ps1 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.
#>
function Invoke-Valentia
{
    [CmdletBinding(DefaultParameterSetName = "TaskFileName")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]$DeployGroups,

        [Parameter(Position = 1, Mandatory = 1, ParameterSetName = "TaskFileName", HelpMessage = "Move to Brach folder you sat taskfile, then input TaskFileName. exclusive with ScriptBlock.")]
        [ValidateNotNullOrEmpty()]
        [string]$TaskFileName,

        [Parameter(Position = 1, Mandatory = 1, ParameterSetName = "SctriptBlock", HelpMessage = "Input Script Block {hogehoge} you want to execute with this commandlet. exclusive with TaskFileName")]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]$ScriptBlock,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Usually automatically sat to DeployGroup Folder. No need to modify.")]
        [ValidateNotNullOrEmpty()]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input parameter pass into task's arg[0....x].values")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$TaskParameter,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Hide execution progress.")]
        [switch]$Quiet,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential),

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Select Authenticateion for Credential.")]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication = $valentia.Authentication,

        [Parameter(Position = 7, Mandatory = 0, HelpMessage = "Select SSL is use or not.")]
        [switch]$UseSSL = $valentia.UseSSL,

        [Parameter(Position = 8, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false
    )

    process
    {
        try
        {

        #region Prerequisite
        
            # Prerequisite setup
            $prerequisiteParam = @{
                Stopwatch     = $TotalstopwatchSession
                DeployGroups  = $DeployGroups
                TaskFileName  = $TaskFileName
                ScriptBlock   = $ScriptBlock
                DeployFolder  = $DeployFolder
                TaskParameter = $TaskParameter
            }
            Set-ValentiaInvokationPrerequisites @prerequisiteParam

        #endregion

        #region Process

            # Job execution
            $param = @{
                Credential      = $Credential
                TaskParameter   = $TaskParameter
                Authentication  = $Authentication
                UseSSL          = $UseSSL
                SkipException   = $SkipException
                ErrorAction     = $originalErrorAction
            }
            Invoke-ValentiaJobProcess @param

        #endregion

        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            if ($ErrorActionPreference -eq 'Stop')
            {
                throw $_
            }
        }
        finally
        {
            # obtain Result
            $resultParam = @{
                StopWatch     = $TotalstopwatchSession
                Cmdlet        = $($MyInvocation.MyCommand.Name)
                TaskFileName  = $TaskFileName
                DeployGroups  = $DeployGroups
                SkipException = $SkipException
                Quiet         = $Quiet
            }
            Out-ValentiaResult @resultParam

            # Cleanup valentia Environment
            Invoke-ValentiaClean
        }
    }

    begin
    {
        # Initialize Stopwatch
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Reset ErrorActionPreference
        if ($PSBoundParameters.ContainsKey('ErrorAction'))
        {
            $originalErrorAction = $ErrorActionPreference
        }
        else
        {
            $originalErrorAction = $ErrorActionPreference = $valentia.preference.ErrorActionPreference.original
        }
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\Job\Invoke-Valentia.ps1

#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

<#
.SYNOPSIS 
Invoke Command as Job to remote host

.DESCRIPTION
Background job execution with Invoke-Command.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun $ScriptToRun

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls}

.EXAMPLE
  Invoke-ValentiaCommand -ScriptToRun {ls | where {$_.extensions -eq ".txt"}}

.EXAMPLE
  Invoke-ValentiaCommand {test-connection localhost}
#>
function Invoke-ValentiaCommand
{
    [CmdletBinding(DefaultParameterSetName = "All")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ParameterSetName = "Default", ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input Session")]
        [string[]]$ComputerNames,

        [Parameter(Position = 1, Mandatory = 1, ParameterSetName = "Default", ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input ScriptBlock. ex) Get-ChildItem, Get-NetAdaptor | where MTUSize -gt 1400")]
        [ScriptBlock]$ScriptToRun,

        [Parameter(Position = 2, Mandatory = 1, HelpMessage = "Input PSCredential for Remote Command execution.")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [hashtable]$TaskParameter,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Input Authentication for credential.")]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input SSL is use or not.")]
        [bool]$UseSSL,

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]$SkipException
    )

    process
    {
        foreach ($computerName in $ComputerNames)
        {
            # Run ScriptBlock in Job
            Write-Verbose ("ScriptBlock..... {0}" -f $($ScriptToRun))
            Write-Verbose ("Argumentlist..... {0}" -f $($TaskParameter))
            ("Running ScriptBlock to {0} as Job" -f $computerName) | Write-ValentiaVerboseDebug
            $job = Invoke-Command -ScriptBlock $ScriptToRun -ArgumentList $TaskParameter -ComputerName $computerName -Credential $Credential -Authentication $Authentication -UseSSL:$UseSSL -AsJob
            $list.Add($job)
        }

        # receive job result
        "Receive all job result." | Write-ValentiaVerboseDebug
        $jobParam = @{
            listJob       = $list
            SkipException = $skipException
            ErrorAction   = $ErrorActionPreference
        }
        Receive-ValentiaResult @jobParam
    }

    begin
    {
        $list = New-Object System.Collections.Generic.List[System.Management.Automation.Job]

        # Set variable for output each task result
        $task = @{}

        # Cleanup previous Job before start
        if ((Get-Job).count -gt 0)
        {
            "Clean up previous Job" | Write-ValentiaVerboseDebug
            Get-Job | Remove-Job -Force -Verbose:$VerbosePreference
        }
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\Job\Private\Invoke-ValentiaCommand.ps1

#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

function Invoke-ValentiaJobProcess
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [string[]]$ComputerNames = $valentia.Result.DeployMembers,

        [parameter(Mandatory = 0)]
        [scriptBlock]$ScriptToRun = $valentia.Result.ScriptTorun,

        [parameter(Mandatory = 1)]
        [PSCredential]$Credential,

        [parameter(Mandatory = 0)]
        [hashtable]$TaskParameter,

        [parameter(Mandatory = 1)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [parameter(Mandatory = 1)]
        [bool]$UseSSL,

        [parameter(Mandatory = 1)]
        [bool]$SkipException
    )

    # Splatting
    $param = @{
        ComputerNames   = $ComputerNames
        ScriptToRun     = $ScriptToRun
        Credential      = $Credential
        TaskParameter   = $TaskParameter
        Authentication  = $Authentication
        UseSSL          = $UseSSL
        SkipException   = $SkipException
        ErrorAction     = $ErrorActionPreference
    }

    # Run ScriptBlock as Sequence for each DeployMember
    Write-Verbose ("Execute command : {0}" -f $param.ScriptToRun)
    Write-Verbose ("Target Computers : '{0}'" -f ($param.ComputerNames -join ", "))

    # Executing job
    Invoke-ValentiaCommand @param  `
    | %{$valentia.Result.Result = New-Object 'System.Collections.Generic.List[PSCustomObject]'
    }{
        $valentia.Result.ErrorMessageDetail += $_.ErrorMessageDetail
        $valentia.Result.SuccessStatus += $_.SuccessStatus
        if ($_.host -ne $null)
        {
            $hash = [ordered]@{
                Hostname = $_.host
                Values    = $_.result
                Success  = $_.success
            }
            $valentia.Result.Result.Add([PSCustomObject]$hash)
        }

        if(!$quiet)
        {
            "Show result for host '{0}'" -f $_.host | Write-ValentiaVerboseDebug
            $_.result
        }
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\Job\Private\Invoke-ValentiaJobProcess.ps1

#Requires -Version 3.0

#-- Private Module Job / Functions for Remote Execution --#

<#
.SYNOPSIS 
Receives a results of one or more jobs.

.DESCRIPTION
Get background job execution result.

.NOTES
Author: guitarrapc
Created: 14/Feb/2014

.EXAMPLE
  Receive-ValentiaResult -listJob $listJob
#>
function Receive-ValentiaResult
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input list<job> to recieve result of each job.")]
        [System.Collections.Generic.List[System.Management.Automation.Job]]$listJob,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]$SkipException
    )

    process
    {
        # monitor job status
        "Waiting for job running complete." | Write-ValentiaVerboseDebug
        Wait-Job -Job $listJob -Force > $null

        foreach ($job in $listJob)
        {
            # Obtain HostName
            $task.host = $job.Location

            ("Receive ScriptBlock result from Job for '{0}'" -f $job.Location) | Write-ValentiaVerboseDebug
            if ($SkipException)
            {
                $task.result = Receive-Job -Job $job -ErrorAction SilentlyContinue -ErrorVariable ErrorVariable
            }
            else
            {
                $task.result = Receive-Job -Job $job -ErrorVariable ErrorVariable
            }

            # Error actions
            if (($ErrorVariable | measure).Count -ne 0)
            {
                $task.ErrorMessageDetail = $ErrorVariable
                $task.SuccessStatus = $false
                $task.success = $false

                if (-not $SkipException)
                {
                    if ($ErrorActionPreference -eq 'Stop')
                    {
                        throw $ErrorVariable
                    }
                }
            }
            else
            {
                $task.success = $true
            }

            # output
            $task

            ("Removing Job ID '{0}'" -f $job.id) | Write-ValentiaVerboseDebug
            Remove-Job -Job $job -Force
        }
    }

    begin
    {
        # Set variable for output
        $task = @{}
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\Job\Private\Receive-ValentiaResult.ps1

#Requires -Version 3.0

#-- Public Module Asynchronous / Functions for Remote Execution --#

# valea

<#
.SYNOPSIS 
Run Asynchronous valentia execution to remote host

.DESCRIPTION
Asynchronous running thread through AsyncPipeLine handling PS Runspace.
Allowed to run from C# code.

.NOTES
Author: guitarrapc
Created: 20/June/2013

.EXAMPLE
  valea 192.168.1.100 {Get-ChildItem}
--------------------------------------------
Get-ChildItem ScriptBlock execute on 192.168.1.100

.EXAMPLE
  valea 192.168.1.100 {Get-ChildItem; hostname}
--------------------------------------------
You can run multiple script in pipeline.

.EXAMPLE
  valea 192.168.1.100 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.

.EXAMPLE
  valea 192.168.1.100,192.168.1.200 .\default.ps1
--------------------------------------------
You can target multiple deploymember with comma separated. Running Asynchronously.

.EXAMPLE
  valea DeployGroupFile.ps1 {ScriptBlock}
--------------------------------------------
Specify DeployGroupFile and ScriptBlock

.EXAMPLE
  valea DeployGroupFile.ps1 .\default.ps1
--------------------------------------------
You can prepare script file to run, and specify path.
#>
function Invoke-ValentiaAsync
{
    [CmdletBinding(DefaultParameterSetName = "TaskFileName")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]$DeployGroups,

        [Parameter(Position = 1, Mandatory = 1, ParameterSetName = "TaskFileName", HelpMessage = "Move to Brach folder you sat taskfile, then input TaskFileName. exclusive with ScriptBlock.")]
        [ValidateNotNullOrEmpty()]
        [string]$TaskFileName,

        [Parameter(Position = 1, Mandatory = 1, ParameterSetName = "SctriptBlock", HelpMessage = "Input Script Block {hogehoge} you want to execute with this commandlet. exclusive with TaskFileName")]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]$ScriptBlock,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Usually automatically sat to DeployGroup Folder. No need to modify.")]
        [ValidateNotNullOrEmpty()]
        [string]$DeployFolder = (Join-Path $script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input parameter pass into task's arg[0....x].Values")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$TaskParameter,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Hide execution progress.")]
        [switch]$Quiet,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential),

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Select Authenticateion for Credential.")]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication = $valentia.Authentication,

        [Parameter(Position = 7, Mandatory = 0, HelpMessage = "Select SSL is use or not.")]
        [switch]$UseSSL = $valentia.UseSSL,

        [Parameter(Position = 8, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false
    )

    process
    {
        try
        {
        #region Prerequisite
        
            # Prerequisite setup
            $prerequisiteParam = @{
                Stopwatch     = $TotalstopwatchSession
                DeployGroups  = $DeployGroups
                TaskFileName  = $TaskFileName
                ScriptBlock   = $ScriptBlock
                DeployFolder  = $DeployFolder
                TaskParameter = $TaskParameter
            }
            Set-ValentiaInvokationPrerequisites @prerequisiteParam

        #endregion

        #region Process

            # RunSpace execution
            $param = @{
                Credential      = $Credential
                TaskParameter   = $TaskParameter
                Authentication  = $Authentication
                UseSSL          = $UseSSL
                SkipException   = $SkipException
                ErrorAction     = $originalErrorAction
                quiet           = $Quiet
            }
            Invoke-ValentiaRunspaceProcess @param

        #endregion

        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            if (-not $SkipException)
            {
                throw $_
            }
        }
        finally
        {
            # obtain Result
            $resultParam = @{
                StopWatch     = $TotalstopwatchSession
                Cmdlet        = $($MyInvocation.MyCommand.Name)
                TaskFileName  = $TaskFileName
                DeployGroups  = $DeployGroups
                SkipException = $SkipException
                Quiet         = $PSBoundParameters.ContainsKey("quiet") -and $quiet
            }
            Out-ValentiaResult @resultParam

            # Cleanup valentia Environment
            Invoke-ValentiaClean
        }
    }

    begin
    {
        # Initialize Stopwatch
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Reset ErrorActionPreference
        if ($PSBoundParameters.ContainsKey('ErrorAction'))
        {
            $originalErrorAction = $ErrorActionPreference
        }
        else
        {
            $originalErrorAction = $ErrorActionPreference = $valentia.preference.ErrorActionPreference.original
        }
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Invoke-ValentiaAsync.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Creating a PowerShell pipeline then executes a ScriptBlock Asynchronous with Remote Host.

.DESCRIPTION
Pipeline will execute less overhead then Invoke-Command, Job, or PowerShell Cmdlet.
All cmdlet will execute with Invoke-Command -ComputerName -Credential wrapped by Invoke-ValentiaAsync pipeline.
Wrapped by Pipeline will give you avility to run Invoke-Command Asynchronous. (Usually Sencronous)
Asynchrnous execution will complete much faster then Syncronous execution.
   
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
Invoke-ValeinaAsyncCommand -RunspacePool $(New-ValentiaRunspacePool 10) `
    -ScriptBlock { Get-ChildItem } `
    -Computers $(Get-Content .\ComputerList.txt)
    -Credential $(Get-Credential)

--------------------------------------------
Above example will concurrently running with 10 processes for each Computers.
#>
function Invoke-ValentiaAsyncCommand
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position  = 0, Mandatory = 1, HelpMessage = "Runspace Poll required to set one or more, easy to create by New-ValentiaRunSpacePool.")]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,
        
        [Parameter(Position  = 1, Mandatory = 1, HelpMessage = "The scriptblock to be executed to the Remote host.")]
        [HashTable]$ScriptToRunHash,
        
        [Parameter(Position  = 2, Mandatory = 1, HelpMessage = "Target Computers to be execute.")]
        [string[]]$DeployMembers,
        
        [Parameter(Position  = 3, Mandatory = 1, HelpMessage = "Remote Login PSCredentail for PS Remoting. (Get-Credential format)")]
        [HashTable]$CredentialHash,

        [Parameter(Position  = 4, Mandatory = 1, HelpMessage = "Input parameter pass into task's arg[0....x].")]
        [HashTable]$TaskParameterHash,

        [Parameter(Position  = 5, Mandatory = 1, HelpMessage = "Input Authentication for credential.")]
        [HashTable]$AuthenticationHash,

        [Parameter(Position  = 6, Mandatory = 1, HelpMessage = "Select SSL is use or not.")]
        [HashTable]$UseSSLHash
    )

    end
    {
        try
        {
            # Create PowerShell Instance
            "Creating PowerShell Instance" | Write-ValentiaVerboseDebug
            $Pipeline = [System.Management.Automation.PowerShell]::Create()

            # Add Script and Parameter arguments from Hashtables
            "Adding Script and Arguments Hastables to PowerShell Instance" | Write-ValentiaVerboseDebug
            Write-Verbose ('Add InvokeCommand Script : {0}'                          -f   $InvokeCommand)
            Write-Verbose ("Add ScriptBlock Argument..... Keys : {0}, Values : {1}"  -f   $($ScriptToRunHash.Keys)   , $($ScriptToRunHash.Values))
            Write-Verbose ("Add ComputerName Argument..... Keys : {0}, Values : {1}" -f   $($ComputerName.Keys)      , $($ComputerName.Values))
            Write-Verbose ("Add Credential Argument..... Keys : {0}, Values : {1}"   -f   $($CredentialHash.Keys)    , $($CredentialHash.Values))
            Write-Verbose ("Add ArgumentList Argument..... Keys : {0}, Values : {1}" -f   $($TaskParameterHash.Keys) , $($TaskParameterHash.Values))
            Write-Verbose ("Add Authentication Argument..... Keys : {0}, Values : {1}" -f $($AuthenticationHash.Keys), $($AuthenticationHash.Values))
            Write-Verbose ("Add UseSSL Argument..... Keys : {0}, Values : {1}"       -f $($UseSSLHash.Keys), $($UseSSLHash.Values))
            $Pipeline.
                AddScript($InvokeCommand).
                AddArgument($ScriptToRunHash).
                AddArgument($ComputerName).
                AddArgument($CredentialHash).
                AddArgument($TaskParameterHash).
                AddArgument($AuthenticationHash).
                AddArgument($UseSSLHash) > $null

            # Add RunSpacePool to PowerShell Instance
            ("Adding Runspaces {0}" -f $RunspacePool) | Write-ValentiaVerboseDebug
            $Pipeline.RunspacePool = $RunspacePool

            # Invoke PowerShell Command
            "Invoking PowerShell Instance" | Write-ValentiaVerboseDebug
            $AsyncResult = $Pipeline.BeginInvoke() 

            # Get Result
            Write-Verbose "Obtain result"
            $Output = New-Object AsyncPipeline 
    
            # Output Pipeline Infomation
            $Output.Pipeline = $Pipeline

            # Output AsyncCommand Result
            $Output.AsyncResult = $AsyncResult
    
            ("Output Result '{0}' and '{1}'" -f $Output.Pipeline, $Output.AsyncResult) | Write-ValentiaVerboseDebug
            return $Output
        }
        catch
        {
            $valentia.Result.SuccessStatus += $false
            $valentia.Result.ErrorMessageDetail += $_
            Write-Error $_
        }
    }

    begin
    {
        # Create Hashtable for ComputerName passed to Pipeline
        $ComputerName = @{ComputerName = $DeployMember}

        # Declare execute Comdlet format as Invoke-Command
        $InvokeCommand = {
            param(
                $ScriptToRunHash,
                $ComputerName,
                $CredentialHash,
                $TaskParameterHash,
                $AuthenticationHash,
                $UseSSLHash
            )

            $param = @{
                ScriptBlock    = $($ScriptToRunHash.Values)
                ComputerName   = $($ComputerName.Values)
                Credential     = $($CredentialHash.Values)
                ArgumentList   = $($TaskParameterHash.Values)
                Authentication = $($AuthenticationHash.Values)
                UseSSL         = $($UseSSLHash.Values)
            }

            Invoke-Command @param
        }
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\Invoke-ValentiaAsyncCommand.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

function Invoke-ValentiaRunspaceProcess
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [string[]]$ComputerNames = $valentia.Result.DeployMembers,

        [parameter(Mandatory = 0)]
        [scriptBlock]$ScriptToRun = $valentia.Result.ScriptTorun,

        [parameter(Mandatory = 1)]
        [PSCredential]$Credential,

        [parameter(Mandatory = 0)]
        [hashtable]$TaskParameter,

        [parameter(Mandatory = 1)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [parameter(Mandatory = 1)]
        [bool]$UseSSL,

        [parameter(Mandatory = 1)]
        [bool]$SkipException,

        [parameter(Mandatory = 0)]
        [bool]$quiet
    )

    process
    {
        try
        {
            # Execute Async Job
            $asyncPipelineparam = @{
                scriptBlock    = $scriptBlock
                Credential     = $credential
                TaskParameter  = $TaskParameter
                Authentication = $Authentication
                UseSSL         = $UseSSL
            }
            Invoke-ValentiaAsyncPipeline @asyncPipelineparam

            # Monitoring status for Async result (Even if no monitoring, but asynchronous result will obtain after all hosts available)
            Watch-ValentiaAsyncPipelineStatus -AsyncPipelines $valentia.runspace.asyncPipeline
        
            # Obtain Async Command Result
            $asyncResultParam = @{
                AsyncPipelines = $valentia.runspace.asyncPipeline
                quiet          = $quiet
                ErrorAction    = $ErrorActionPreference
                skipException  = $skipException
            }
            Receive-ValentiaAsyncResults @asyncResultParam `
            | %{$valentia.Result.Result = New-Object 'System.Collections.Generic.List[PSCustomObject]'
            }{
                $valentia.Result.ErrorMessageDetail += $_.ErrorMessageDetail
                $valentia.Result.SuccessStatus += $_.SuccessStatus
                if ($_.host -ne $null)
                {
                    $hash = [ordered]@{
                        Hostname = $_.host
                        Values    = $_.result
                        Success  = $_.success
                    }
                    $valentia.Result.Result.Add([PSCustomObject]$hash)
                }

                if (-not $quiet)
                {
                    "Show result for host '{0}'" -f $_.host | Write-ValentiaVerboseDebug
                    $_.result
                }
            }
        }
        finally
        {
            # Dispose RunspacePool
            Remove-ValentiaRunSpacePool

            # Dispose AsyncPipeline variables
            $valentia.runspace.asyncPipeline = $null
        }
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\Invoke-ValentiaRunspaceProcess.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Receives a results of one or more asynchronous pipelines.

.DESCRIPTION
This function receives the results of a pipeline running in a separate runspace.  
Since it is unknown what exists in the results stream of the pipeline, this function will not have a standard return type.
 
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $valentia.runspace.pool.instance  -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncResults -AsyncPipelines $AsyncPipelines -ShowProgress

--------------------------------------------
Above will retrieve Async Result
#>
function Receive-ValentiaAsyncResults
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]$AsyncPipelines,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Hide execution progress.")]
        [bool]$quiet,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Input Skip ErrorActionPreferenceOption.")]
        [bool]$SkipException
    )
    
    process
    {
        foreach($Pipeline in $AsyncPipelines)
        {
            try
            {
                # Get HostName of Pipeline
                $task.host = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
                if (-not $quiet)
                {
                    Write-Warning  -Message ("{0} Asynchronous execution done." -f $task.host)
                }

                # output Asyanc result
                $task.result = $Pipeline.Pipeline.EndInvoke($Pipeline.AsyncResult)
            
                # Check status of stream
                if($Pipeline.Pipeline.Streams.Error)
                {
                    $task.SuccessStatus = $false
                    $task.ErrorMessageDetail = $Pipeline.Pipeline.Streams.Error
                    $task.success = $false

                    if (-not $SkipException)
                    {
                        if ($ErrorActionPreference -eq "Stop")
                        {
                            throw $Pipeline.Pipeline.Streams.Error
                        }
                        else
                        {
                            Write-Error "$($Pipeline.Pipeline.Streams.Error)"
                        }
                    }
                }
                else
                {
                    $task.success = $true
                }
       
                # Output $task variable to file. This will obtain by other cmdlet outside function.
                $task
            }
            catch 
            {
                $task.SuccessStatus = $false
                $task.ErrorMessageDetail = $_
                Write-Error $_
            }
            finally
            {
                # Dispose Pipeline
                $Pipeline.Pipeline.Dispose()                
            }
        }
    }

    begin
    {
        # Inherite variable
        [HashTable]$task = @{}
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\Receive-ValentiaAsyncResults.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Receives one or more Asynchronous pipeline State.

.DESCRIPTION
Asynchronous execution required to check status whether it done or not.
  
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$AsyncPipelines += Invoke-ValentiaAsyncCommand -RunspacePool $valentia.runspace.pool.instance -ScriptToRun $ScriptToRun -Deploymember $DeployMember -Credential $credential -Verbose
Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines

--------------------------------------------
Above will retrieve Async Result
#>
function Receive-ValentiaAsyncStatus
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]
        $Pipelines
    )
    
    foreach($Pipeline in $Pipelines)
    {
       [PSCustomObject]@{
            HostName   = $Pipeline.Pipeline.Commands.Commands.parameters.Value.ComputerName
            InstanceID = $Pipeline.Pipeline.Instance_Id
            State      = $Pipeline.Pipeline.InvocationStateInfo.State
            Reason     = $Pipeline.Pipeline.InvocationStateInfo.Reason
            Completed  = $Pipeline.AsyncResult.IsCompleted
            AsyncState = $Pipeline.AsyncResult.AsyncState			
            Error      = $Pipeline.Pipeline.Streams.Error
       }
    } 
}

# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\Receive-ValentiaAsyncStatus.ps1

#Requires -Version 3.0

#-- Private Module Function for AsyncPipelline execution --#

function Invoke-ValentiaAsyncPipeline
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 0)]
        [scriptBlock]$ScriptBlock,

        [parameter(Mandatory = 1)]
        [PSCredential]$Credential,

        [parameter(Mandatory = 0)]
        [hashtable]$TaskParameter,

        [parameter(Mandatory = 1)]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

        [parameter(Mandatory = 1)]
        [bool]$UseSSL
    )

    # Create RunSpacePools
    [System.Management.Automation.Runspaces.RunspacePool]$valentia.runspace.pool.instance = New-ValentiaRunSpacePool

    Write-Verbose ("Target Computers : [{0}]" -f ($ComputerNames -join ", "))
    $param = @{
        RunSpacePool       = $valentia.runspace.pool.instance
        ScriptToRunHash    = @{ScriptBlock    = $ScriptToRun}
        credentialHash     = @{Credential     = $Credential}
        TaskParameterHash  = @{TaskParameter  = $TaskParameter}
        AuthenticationHash = @{Authentication = $Authentication}
        UseSSL             = @{UseSSL         = $UseSSL}
    }
    $valentia.runspace.asyncPipeline = New-Object 'System.Collections.Generic.List[AsyncPipeline]'

    foreach ($DeployMember in $valentia.Result.DeployMembers)
    {
        $AsyncPipeline = Invoke-ValentiaAsyncCommand @param -Deploymember $DeployMember
        $valentia.runspace.asyncPipeline.Add($AsyncPipeline)
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\AsyncPipeline\Invoke-ValentiaAsyncPipeline.ps1

#Requires -Version 3.0

#-- Private Module Function for AsyncPipelline monitor --#

function Watch-ValentiaAsyncPipelineStatus
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "An array of Async Pipeline objects, returned by Invoke-ValentiaAsync.")]
        [System.Collections.Generic.List[AsyncPipeline]]$AsyncPipelines
    )

    process
    {
        while ((($ReceiveAsyncStatus = (Receive-ValentiaAsyncStatus -Pipelines $AsyncPipelines | group state, hostname -NoElement)) | where name -like "Running*").count -ne 0)
        {
            $count++
            $completed     = $ReceiveAsyncStatus | where name -like "Completed*"
            $running       = $ReceiveAsyncStatus | where name -like "Running*"
            $statusPercent = ($completed.count/$ReceiveAsyncStatus.count) * 100

            # hide progress or not
            if (-not $quiet -and ($sw.Elapsed.TotalMilliseconds -ge 500))
            {
                # hide progress or not
                if ($statusPercent -ne 100)
                {
                    $paramProgress = @{
                        Activity        = 'Async Execution Running Status.... ({0}sec elapsed)' -f $TotalstopwatchSession.Elapsed.TotalSeconds
                        PercentComplete = $statusPercent
                        status          = ("{0}/{1}({2:0.00})% Completed" -f $completed.count, $ReceiveAsyncStatus.count, $statusPercent)
                    }
                    
                    Write-Progress @paramProgress
                    $sw.Reset()
                    $sw.Start()
                }
            }

            # Log Current Status
            if (-not $null -eq $prevRunningCount)
            {
                if ($running.count -lt $prevRunningCount)
                {
                    $ReceiveAsyncStatus.Name | OutValentiaModuleLogHost -hideDataAsString
                    [PSCustomObject]@{
                        Running   = $running.count
                        Completed = $completed.count
                    } | OutValentiaModuleLogHost -hideDataAsString
                }
            }
            $prevRunningCount = $running.count

            # Wait a moment
            sleep -Milliseconds $valentia.runspace.async.sleepMS

            # safety release
            if ($count -ge $valentia.runspace.async.limitCount)
            {
                break
            }
        }
    }

    end
    {
        # Clear Progress bar from Host, YOU MUST CLEAR PROGRESS BAR, other wise host output will be terriblly slow down.
        Write-Progress "done" "done" -Completed

        # Dispose variables
        if (-not ($null -eq $ReceiveAsyncStatus))
        {
            $ReceiveAsyncStatus = $null
        }
    }

    begin
    {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
    }
}

# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\AsyncPipeline\Watch-ValentiaAsyncPipelineStatus.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Create a PowerShell Runspace Pool.

.DESCRIPTION
This function returns a runspace pool, a collection of runspaces that PowerShell pipelines can be executed.
The number of available pools determines the maximum number of processes that can be running concurrently.
This enables multithreaded execution of PowerShell code.

.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
$pool = New-ValentiaRunspacePool -minPoolSize 50 -maxPoolSize 50

--------------------------------------------
Above will creates a pool of 10 runspaces
#>
function New-ValentiaRunSpacePool
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position =0, Mandatory = 0, HelpMessage = "Defines the minium number of pipelines that can be concurrently (asynchronously) executed on the pool.")]
        [int]$minPoolSize = $valentia.runspace.pool.minSize,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Defines the maximum number of pipelines that can be concurrently (asynchronously) executed on the pool.")]
        [int]$maxPoolSize = $valentia.runspace.pool.maxSize
    )

    try
    {
        $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # RunspaceFactory.CreateRunspacePool (Int32, Int32, InitialSessionState, PSHost)
        #   - Creates a runspace pool that specifies minimum and maximum number of opened runspaces, 
        #     and a custom host and initial session state information that is used by each runspace in the pool.
        $pool = [runspacefactory]::CreateRunspacePool($minPoolSize, $maxPoolSize,  $sessionstate, $Host)	
    
        # Only support STA mode. No MTA mode.
        $pool.ApartmentState = "STA"
    
        # open RunSpacePool
        $pool.Open()
    
        return $pool
    }
    catch
    {
        $valentia.Result.SuccessStatus += $false
        $valentia.Result.ErrorMessageDetail += $_
        Write-Error $_
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\RunSpacePool\New-ValentiaRunSpacePool.ps1

#Requires -Version 3.0

#-- Private Module Function for Async execution --#

<#
.SYNOPSIS 
Close and Dispose PowerShell Runspace Pool.

.DESCRIPTION
This function Close runspace pool, then dispose.

.NOTES
Author: guitarrapc
Created: 14/Feb/2014

.EXAMPLE
Remove-ValentiaRunspacePool -RunSpacePool $valentia.runspace.pool.instance
#>
function Remove-ValentiaRunSpacePool
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = 0, HelpMessage = "Specify RunSpace Pool to close and dispose.")]
        [System.Management.Automation.Runspaces.RunspacePool]$Pool = $valentia.runspace.pool.instance
    )

    $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

    try
    {
        if ($Pool)
        {
            $Pool.Close()
            $Pool.Dispose()
        }
    }
    catch
    {
        $valentia.Result.SuccessStatus += $false
        $valentia.Result.ErrorMessageDetail += $_
        Write-Error $_
    }
}
# file loaded from path : \functions\Invokation\CommandExecution\RunSpacePool\Private\RunSpacePool\Remove-ValentiaRunSpacePool.ps1

#Requires -Version 3.0

#-- Public Module Functions for Download Files --#

# download

<#
.SYNOPSIS 
Use BITS Transfer to downlpad a file from remote server.
If -Force switch enable, then use smbmapping and copy -force will run.

.DESCRIPTION
If target path was directory then download files below path. (None recurse)
If target path was file then download specific file.

.NOTES
Author: guitarrapc
Created: 14/Aug/2013

.EXAMPLE
download -SourcePath c:\logs\white\20130719 -DestinationFolder c:\logs\white -DeployGroup production-g1.ps1 -Directory -Async
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job.

.EXAMPLE
download -SourcePath c:\logs\white\20130716\Http.0001.log -DestinationFolder c:\test -DeployGroup.ps1 production-first -File
--------------------------------------------
download remote sourth item to local destinationfolder

.EXAMPLE
download -SourcePath c:\logs\white\20130716 -DestinationFolder c:\test -DeployGroup production-first.ps1 -Directory
--------------------------------------------
download remote sourthdirectory items to local destinationfolder in backgroud job. Omit parameter name.
#>
function Invoke-ValentiaDownload
{
    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input Client SourcePath to be downloaded.")]
        [String]$SourcePath,

        [Parameter(Position = 1, Mandatory = 1, HelpMessage = "Input Server Destination Folder to save download items.")]
        [string]$DestinationFolder = $null, 

        [Parameter(Position = 2, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]$DeployGroups,

        [Parameter(position = 3, ParameterSetName = "File", HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]$File = $true,

        [Parameter(position = 3, ParameterSetName = "Directory", HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]$Directory,

        [Parameter(position = 4, Mandatory = 0, HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]$Async = $false,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Set this switch if you want to Force download. This will smbmap with source folder and Copy-Item -Force. (default is BitTransfer)")]
        [switch]$force = $false,

        [Parameter(Position = 7, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false,

        [Parameter(Position = 8, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential)
    )

    try
    {

    ### Begin

        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime

        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration -Verbose

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-ValentiaConfiguration
            Import-valentiaModules
        }
        
        # Log Setting
        New-ValentiaLog
                
        # Obtain DeployMember IP or Hosts for BITsTransfer
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-ValentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        if ($DeployMembers.SuccessStatus -eq $false)
        {
            $SuccessStatus += $DeployMembers.SuccessStatus
            $ErrorMessageDetail += $DeployMembers.ErrorMessageDetail
        }        
        
        # Parse Network Source
        ("Parsing Network SourcePath {0} as :\ should change to $." -f $SourcrePath) | Write-ValentiaVerboseDebug
        $SourcePath = "$SourcePath".Replace(":","$")


        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""
        
    ### Process
    
        ("Downloading {0} from Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers){
            
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Source 
            $Source = Join-Path "\\" $(Join-Path "$DeployMember" "$SourcePath")

            if (Test-Path $Source)
            {
                if ($Directory)
                {
                    # Set Source files in source
                    try
                    {
                        # Remove last letter of \ or /
                        if (($Source[-1] -eq "\") -or ($Source[-1] -eq "/"))
                        {
                            $Source = $Source.Substring(0,($Source.Length-1))
                        }

                        # Get File Information - No recurse
                        $SourceFiles = Get-ChildItem -Path $Source
                    }
                    catch
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_
                        throw $_
                    }
                }
                elseif ($File)
                {
                    # Set Source files in source
                    try
                    {
                        # Get File Information
                        $SourceFiles = Get-Item -Path $Source
                    
                        if ($SourceFiles.Attributes -eq "Directory")
                        {
                            $SuccessStatus += $false
                            $ErrorMessageDetail += "Target is Directory, you must set Filename with -File Switch."
                            throw "Target is Directory, you must set Filename with -File Switch."
                        }
                    }
                    catch
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_
                        throw $_
                    }
                }
                else
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw "Missing File or Directory switch. Please set -File or -Directory Switch to specify download type."
                }


                # Set Destination with date and DeproyMemberName
                if ($DestinationFolder -eq $null)
                {
                    $DestinationFolder = $(Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Download))
                }

                $Date = (Get-Date).ToString("yyyyMMdd")
                $DestinationPath = Join-Path $DestinationFolder $Date
                $Destination = Join-Path $DestinationPath $DeployMember

                # Create Destination if not exist
                if (-not(Test-Path $Destination))
                {
                    New-Item -Path $Destination -ItemType Directory -Force > $null
                }

                if ($force)
                {
                    # Show Start-BitsTransfer Parameter
                    ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember) | Write-ValentiaVerboseDebug
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose "Aync Mode : You cannot use Async switch with force"

                    # Get Cimsession for target Computer
                    "cim : New-CimSession to the ComputerName '{0}'" -f $DeployMember | Write-ValentiaVerboseDebug
                    $cim = New-CimSession -Credential $Credential -ComputerName $DeployMember
                        
                    # Create SMB Mapping to target parent directory
                    if ($Directory)
                    {
                        "Directory switch Selected" | Write-ValentiaVerboseDebug
                        $smbRemotePath = (Get-Item $Source).FullName
                    }
                    elseif ($file)
                    {
                        "File switch Selected" | Write-ValentiaVerboseDebug
                        $smbRemotePath = (Get-Item $source).DirectoryName
                    }

                    # Running Copy-Item cmdlet, switch with $force
                    try
                    {                     
                        #Only start download for file.
                        foreach($SourceFile in $SourceFiles)
                        {
                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                            {
                                Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                $ScriptToRun = "Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force"
                                Copy-Item -Path $(($SourceFile).fullname) -Destination $Destination -Force
                            }
                        }
                    }
                    catch [System.Management.Automation.ActionPreferenceStopException]
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_

                        # Show Error Message
                        throw $_
                    }
                    finally
                    {
                        # Stopwatch
                        $Duration = $stopwatchSession.Elapsed.TotalSeconds
                        Write-Verbose ("Session duration Second : {0}" -f $Duration)
                        ""
                    }
                }
                else # Not Force Swtich
                {
                    # Show Start-BitsTransfer Parameter
                    ("Downloading {0} from {1}." -f $SourceFiles, $DeployMember) | Write-ValentiaVerboseDebug
                    Write-Verbose ("DeployFolder : {0}" -f $DeployFolder)
                    Write-Verbose ("DeployMembers : {0}" -f $DeployMembers)
                    Write-Verbose ("DeployMember : {0}" -f $DeployMember)
                    Write-Verbose ("Source : {0}" -f $Source)
                    Write-Verbose ("Destination : {0}" -f $Destination)
                    Write-Verbose ("Aync Mode : {0}" -f $Async)

                    # Running Bits Transfer, switch with $Async and no $Async
                    try
                    {
                        switch ($true)
                        {
                            # Async Transfer
                            $Async {
                                try
                                {
                                    $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download"
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        try
                                        {
                                            #Only start download for file.
                                            if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                            {
                                                # Run Job
                                                Write-Warning ("Async Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                                $Job = Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Download
                                        
                                                # Waiting for complete job
                                                $Sleepms = 10

                                                "Current States was {0}" -f $Job.JobState | Write-ValentiaVerboseDebug
                                            }
                                        }
                                        catch
                                        {
                                            $SuccessStatus += $false
                                            $ErrorMessageDetail += $_

                                            # Show Error Message
                                            throw $_
                                        }
                                    }

                                    # Retrieving transfer status and monitor for transffered
                                    $Sleepms = 10
                                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                    { 
                                        "Current Job States was {0}, waiting for {1} ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count)) | Write-ValentiaVerboseDebug
                                        Sleep -Milliseconds $Sleepms
                                    }

                                    # Retrieve all files when completed
                                    Get-BitsTransfer | Complete-BitsTransfer
                                }
                                catch
                                {
                                    $SuccessStatus += $false
                                    $ErrorMessageDetail += $_

                                    # Show Error Message
                                    throw $_
                                }
                                finally
                                {
                                    # Delete all not compelte job
                                    Get-BitsTransfer | Remove-BitsTransfer

                                    # Stopwatch
                                    $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                    Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                    ""
                                    $DurationTotal += $Duration
                                }

                            }
                            default {
                                # NOT Async Transfer
                                try
                                {
                                    $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType Download"
                                    foreach($SourceFile in $SourceFiles)
                                    {
                                        #Only start download for file.
                                        if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                        {
                                            Write-Warning ("Downloading {0} from {1} to {2}" -f ($SourceFile).fullname, $DeployMember, $Destination)
                                            Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential -TransferType Download
                                        }
                                    }
                                }
                                catch [System.Management.Automation.ActionPreferenceStopException]
                                {
                                    $SuccessStatus += $false
                                    $ErrorMessageDetail += $_

                                    # Show Error Message
                                    throw $_
                                }
                                finally
                                {
                                    # Delete all not compelte job
                                    Get-BitsTransfer | Remove-BitsTransfer

                                    # Stopwatch
                                    $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                    Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                    ""
                                }
                            }
                        }
                    }
                    catch
                    {

                        # Show Error Message
                        Write-Error $_

                        # Set ErrorResult
                        $SuccessStatus += $false
                        $ErrorMessageDetail += $_

                    }
                }
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    
    ### End

        Write-Verbose "All transfer with BitsTransfer had been removed."

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        if (-not $SkipException)
        {
            throw $_
        }
    }
    finally
    {

        # obtain Result
        $resultParam = @{
            StopWatch     = $TotalstopwatchSession
            Cmdlet        = $($MyInvocation.MyCommand.Name)
            TaskFileName  = $TaskFileName
            DeployGroups  = $DeployGroups
            SkipException = $SkipException
            Quiet         = $PSBoundParameters.ContainsKey("quiet") -and $quiet
        }
        Out-ValentiaResult @resultParam

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}

# file loaded from path : \functions\Invokation\Download\Invoke-ValentiaDownload.ps1

#Requires -Version 3.0

#-- ping Connection to the host --#

# PingAsync

<#
.SYNOPSIS 
Ping to the host by IP Address Asynchronous

.DESCRIPTION
This Cmdlet will ping and get reachability to the host.

.NOTES
Author: guitarrapc
Created: 03/Feb/2014

.EXAMPLE
Ping-ValentiaGroupAsync production-hoge.ps1
--------------------------------------------
Ping production-hoge.ps1 from deploy group branch path
#>
function Ping-ValentiaGroupAsync
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ValueFromPipeLine = 1, ValueFromPipeLineByPropertyName = 1, HelpMessage = "Input target computer name or ipaddress to test ping.")]
        [string[]]$HostNameOrAddresses,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Input timeout ms wait for the responce answer.")]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout = $valentia.ping.timeout,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Input buffer size for the data size send/recieve with ICMP send.")]
        [ValidateNotNullOrEmpty()]
        [byte[]]$Buffer = $valentia.ping.buffer,

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input ttl for the ping option.")]
        [ValidateNotNullOrEmpty()]
        [int]$Ttl = $valentia.ping.pingOption.ttl,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Input dontFragment for the ping option.")]
        [ValidateNotNullOrEmpty()]
        [bool]$dontFragment = $valentia.ping.pingOption.dontfragment,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Change return type to bool only.")]
        [ValidateNotNullOrEmpty()]
        [switch]$quiet
    )

    begin
    {
        # Preference
        $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        # new object for event and job
        $pingOptions = New-Object Net.NetworkInformation.PingOptions($Ttl, $dontFragment)
        $tasks = New-Object System.Collections.Generic.List[PSCustomObject]
        $output = New-Object System.Collections.Generic.List[PSCustomObject]
    }

    process
    {
        foreach ($hostNameOrAddress in $HostNameOrAddresses)
        {
            $ping  = New-Object System.Net.NetworkInformation.Ping

            ("Execute SendPingAsync to host '{0}'." -f $hostNameOrAddress) | Write-ValentiaVerboseDebug
            $PingReply = $ping.SendPingAsync($hostNameOrAddress, $timeout, $buffer, $pingOptions)

            $task = [PSCustomObject]@{
                HostNameOrAddress = $hostNameOrAddress
                Task              = $PingReply
                Ping              = $ping}
            $tasks.Add($task)
        }
    }

    end
    {
        "WaitAll for Task PingReply have been completed." | Write-ValentiaVerboseDebug
        [System.Threading.Tasks.Task]::WaitAll($tasks.Task)
        
        foreach ($task in $tasks)
        {
            try
            {
                [System.Net.NetworkInformation.PingReply]$result = $task.Task.Result

                if (-not ($PSBoundParameters.ContainsKey("quiet") -and $quiet))
                {
                        [PSCustomObject]@{
                        Id                 = $task.Task.Id
                        HostNameOrAddress  = $task.HostNameOrAddress
                        Status             = $result.Status
                        IsSuccess          = $result.Status -eq [Net.NetworkInformation.IPStatus]::Success
                        RoundtripTime      = $result.RoundtripTime
                    }
                }
                else
                {
                    $result.Status -eq [Net.NetworkInformation.IPStatus]::Success
                }
            }
            finally
            {
                "Dispose Ping Object" | Write-ValentiaVerboseDebug
                if ($null -ne $task){ $task.Ping.Dispose() }
            
                "Dispose PingReply Object" | Write-ValentiaVerboseDebug
                if ($null -ne $task){ $task.Task.Dispose() }
            }
        }
    }
}
# file loaded from path : \functions\Invokation\Ping\Ping-ValentiaGroupAsync.ps1

#Requires -Version 3.0

#-- ping Connection to the host --#

# PingAsync

<#
.SYNOPSIS 
Monitor host by Ping for selected Second

.DESCRIPTION
This function will pingasync to the host.
You can set Interval seconds and endup limitCount to prevent eternal execution.

.NOTES
Author: guitarrapc
Created: 27/July/2014

.EXAMPLE
Watch-ValentiaPingAsyncReplyStatus -deploygroups 192.168.100.100 -DesiredStatus $true -limitCount 1000 | ft
--------------------------------------------
Continuous ping to the 192.168.100.100 for sleepSec 1 sec. (default)
This will break if host is reachable or when count up to limitCount 1000.
#>
function Watch-ValentiaPingAsyncReplyStatus
{

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = 1, position  = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$deploygroups,

        [parameter(Mandatory = 1, position  = 1)]
        [ValidateNotNullOrEmpty()]
        [bool]$DesiredStatus = $true,

        [parameter(Mandatory = 0, position  = 2)]
        [ValidateNotNullOrEmpty()]
        [int]$sleepSec = 1,

        [parameter(Mandatory = 0, position  = 3)]
        [ValidateNotNullOrEmpty()]
        [int]$limitCount = 100
    )

    process
    {
        $i = 0
        while ($true)
        {
            $date = Get-Date
            $hash = pingAsync -HostNameOrAddresses $ipaddress `
            | %{
                Add-Member -InputObject $_ -MemberType NoteProperty -Name Date -Value $date -Force -PassThru
            }
        
            Write-Verbose ("Filtering status as '{0}'" -f $DesiredStatus)
            $hash `
            | where IsSuccess -eq $DesiredStatus `
            | where HostNameOrAddress -in $ipaddress.IPAddressToString `
            | %{$result = $ipaddress.Remove($_.HostNameOrAddress)
                if ($result -eq $false)
                {
                    throw "failed to remove ipaddress '{0}' from list" -f $_.HostNameOrAddress
                }
                else
                {
                    Write-Host ("ipaddress '{0}' turned to be DesiredStatus '{1}'" -f "$($_.HostNameOrAddress -join ', ')", $DesiredStatus) -ForegroundColor Green
                }
            }

            $count = ($ipaddress | measure).count

            if ($count -eq 0)
            {
                Write-Host ("HostnameOrAddress '{0}' IsSuccess : '{1}'. break monitoring" -f $($hash.HostNameOrAddress -join ", "), $DesiredStatus) -ForegroundColor Cyan
                $hash
                break;
            }
            elseif ($i -ge $limitCount)
            {
                write-Warning ("exceeed {0} count of sleep. break." -f $limitCount)
                $hash
                break;
            }
            else
            {
                Write-Verbose ("sleep {0} second for next status check." -f $sleepSec)
                $hash
                sleep -Seconds $sleepSec
                $i++
            }
        }
    }

    end
    {
        $end = Get-Date
        Write-Host ("Start Time  : {0}" -f $start) -ForegroundColor Cyan
        Write-Host ("End   Time  : {0}" -f $end) -ForegroundColor Cyan
        Write-Host ("Total Watch : {0}sec" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Cyan
    }

    begin
    {
        $start = Get-Date
        $sw = New-Object System.Diagnostics.Stopwatch
        $sw.Start()

        $ipaddress = New-Object 'System.Collections.Generic.List[ipaddress]'
        Get-ValentiaGroup -DeployGroups $deploygroups | %{$ipaddress.Add($_)}
    }
}
# file loaded from path : \functions\Invokation\Ping\Watch-ValentiaPingAsyncReplyStatus.ps1

#Requires -Version 3.0

#-- Public Module Functions for Sync Files or Directories--#

# Sync

<#
.SYNOPSIS 
Use fastcopy.exe to Sync Folder for Diff folder/files not consider Diff from remote server.

.DESCRIPTION
You must install fastcopy.exe to use this function.

.NOTES
Author: gutiarrapc
Created: 13/July/2013

.EXAMPLE
Sync -Source sourcepath -Destination desitinationSharePath -DeployGroup DeployGroup.ps1
--------------------------------------------
Sync sourthpath and destinationsharepath directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync c:\deployment\upload c:\deployment\upload 192.168.1.100
--------------------------------------------
Sync c:\deployment\upload directory and remote server listed in new.ps1 c:\deployment\upload directory in Diff mode. (Will not delete items but only update to add new)

.EXAMPLE
Sync -Source c:\upload.txt -Destination c:\share\ -DeployGroup 192.168.1.100,192.168.1.102
--------------------------------------------
Sync c:\upload.txt file and c:\share directory in Diff mode. (Will not delete items but only update to add new)
#>
function Invoke-ValentiaSync
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input Deploy Server Source Folder Sync to Client PC.")]
        [string]$SourceFolder, 

        [Parameter(Position = 1, Mandatory = 1, HelpMessage = "Input Client Destination Folder Sync with Desploy Server.")]
        [String]$DestinationFolder,

        [Parameter(Position = 2, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]$DeployGroups,

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed.")]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential),

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Input fastCopy.exe location folder if changed.")]
        [string]$FastCopyFolder = $valentia.fastcopy.folder,
        
        [Parameter(Position = 7, Mandatory = 0, HelpMessage = "Input fastCopy.exe name if changed.")]
        [string]$FastcopyExe =  $valentia.fastcopy.exe
    )

    try
    {


    ### Begin

        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime

        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration -Verbose

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-ValentiaConfiguration
            Import-valentiaModules
        }

        # Log Setting
        New-ValentiaLog

        # Check FastCopy.exe path
        "Checking FastCopy Folder is exist or not." | Write-ValentiaVerboseDebug
        if (-not(Test-Path $FastCopyFolder))
        {
            New-Item -Path $FastCopyFolder -ItemType Directory
        }

        # Set FastCopy.exe path
        Write-Verbose "Set FastCopy.exe path."
        $FastCopy = Join-Path $FastCopyFolder $FastcopyExe

        # Check SourceFolder Exist or not
        if (-not(Test-Path $SourceFolder))
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += "SourceFolder [ $SourceFolder ] not found exeptions! exit job."
            throw "SourceFolder [ {0} ] not found exeptions! exit job." -f $SourceFolder
        }

        # Obtain DeployMember IP or Hosts for FastCopy
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        # Parse Network Destination Path
        ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder) | Write-ValentiaVerboseDebug
        $DestinationPath = "$DestinationFolder".Replace(":","$")

        # Safety exit for root drive
        if ($SourceFolder.Length -ge 3)
        {
            Write-Verbose ("SourceFolder[-2]`t:`t$($SourceFolder[-2])")
            Write-Verbose ("SourceFolder[-1]`t:`t$($SourceFolder[-1])")
            if (($SourceFolder[-2] + $SourceFolder[-1]) -in (":\",":/"))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)

                throw ("SourceFolder path was Root Drive [ {0} ] exception! Exist for safety." -f $SourceFolder)
            }
        }

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""

    ### Process

        Write-Warning "Starting Sync Below files"
        Write-Verbose (" Syncing {0} to Target Computer : [{1}] {2} `n" -f $SourceFolder, $DeployMembers, $DestinationFolder)
        (Get-ChildItem $SourceFolder).FullName

        # Stopwatch
        [decimal]$DurationTotal = 0

        foreach ($DeployMember in $DeployMembers)
        {
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()

            # Create Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")

            # Set FastCopy.exe Argument for Sync
            $FastCopyArgument = "/cmd=sync /bufsize=512 /speed=full /wipe_del=FALSE /acl /stream /reparse /force_close /estimate /error_stop=FALSE /log=True /logfile=""$($valentia.log.fullPath)"" ""$SourceFolder"" /to=""$Destination"""

            # Run FastCopy
            Write-Warning ("[{0}]:Uploading {1} to {2}." -f $DeployMember ,$SourceFolder, $Destination)
            Write-Verbose ("FastCopy : {0}" -f $FastCopy)
            Write-Verbose ("FastCopyArgument : {0}" -f $FastCopyArgument)

            if (Ping-ValentiaGroupAsync -HostNameOrAddresses $DeployMember)
            {
                try
                {
                    'Command : Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -PassThru -Credential $Credential' | Write-ValentiaVerboseDebug
                    $Result = Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait -PassThru -Credential $Credential
                }
                catch
                {
                    Write-Error $_
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_ 
                }
            }
            else
            {
                Write-Error ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)
                $SuccessStatus += $false
                $ErrorMessageDetail += ("Target Host {0} unreachable. Check DeployGroup file [ {1} ] again" -f $DeployMember, $DeployGroups)
            }

            # Stopwatch
            $Duration = $stopwatchSession.Elapsed.TotalSeconds
            Write-Verbose ("Session duration Second : {0}" -f $Duration)
            ""
            $DurationTotal += $Duration
        }

    ### End
   
        "All Sync job complete." | Write-ValentiaVerboseDebug
        if (Test-Path $valentia.log.fullPath)
        {
            if (-not((Select-String -Path $valentia.log.fullPath -Pattern "No Errors").count -ge $DeployMembers.count))
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
                Write-Error ("One or more host was reachable with ping, but not authentiacate to DestinationFolder [ {0} ]" -f $DestinationFolder)
            }
        }
        else
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
            Write-Error ("None of the host was reachable with ping with DestinationFolder [ {0} ]" -f $DestinationFolder)
        }

    }

    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        if (-not $SkipException)
        {
            throw $_
        }
    }

    finally
    {    
        # Show Stopwatch for Total section
        $TotalDuration += $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)

        # Get End Time
        $TimeEnd = (Get-Date).DateTime

        # obtain Result
        $CommandResult = [ordered]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "Start-Process $FastCopy -ArgumentList $FastCopyArgument -Wait"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            Result = $result
            SkipException  = $SkipException
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $quiet = $PSBoundParameters.ContainsKey("quiet") -and $quiet
        WriteValentiaResultHost -quiet $quiet -CommandResult $CommandResult

        # output result
        OutValentiaResultLog -CommandResult $CommandResult -Append

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

}

# file loaded from path : \functions\Invokation\Sync\Invoke-ValentiaSync.ps1

#Requires -Version 3.0

#-- Public Module Functions for Upload Files --#

# upload

<#
.SYNOPSIS 
Use BITS Transfer to upload a file to remote server.

.DESCRIPTION
This function supports multiple file transfer, if you want to fix file in list then use uploadList function.
  
.NOTES
Author: guitarrapc
Created: 13/July/2013

.EXAMPLE
upload -SourcePath C:\hogehoge.txt -DestinationPath c:\ -DeployGroup production-first.ps1 -File
--------------------------------------------
upload file to destination for hosts written in production-first.ps1

.EXAMPLE
upload -SourcePath C:\deployment\Upload -DestinationPath c:\ -DeployGroup production-first.ps1 -Directory
--------------------------------------------
upload folder to destination for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload folder as Background Async job for hosts written in production-first.ps1

.EXAMPLE
upload C:\hogehoge.txt c:\ production-first -Directory 192.168.0.10 -Async
--------------------------------------------
upload file to Directory as Background Async job for host ip 192.168.0.10

.EXAMPLE
upload C:\hogehoge* c:\ production-first -Directory production-fist.ps1 -Async
--------------------------------------------
upload files in target to Directory as Background Async job for hosts written in production-first.ps1
#>
function Invoke-ValentiaUpload
{
    [CmdletBinding(DefaultParameterSetName = "File")]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, HelpMessage = "Input Deploy Server SourcePath to be uploaded.")]
        [string]$SourcePath, 

        [Parameter(Position = 1, Mandatory = 1, HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [String]$DestinationPath = $null,

        [Parameter(Position = 2, Mandatory = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]$DeployGroups,

        [Parameter(position = 3, Mandatory = 0, ParameterSetName = "File", HelpMessage = "Set this switch to execute command for File. exclusive with Directory Switch.")]
        [switch]$File = $null,

        [Parameter(position = 3, Mandatory = 0, ParameterSetName = "Directory", HelpMessage = "Set this switch to execute command for Directory. exclusive with File Switch.")]
        [switch]$Directory,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]$Async = $false,

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 6, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential),

        [Parameter(Position = 7, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false
    )

    try
    {

    ### Begin

        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
    
        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime

        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration -Verbose

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-ValentiaConfiguration
            Import-valentiaModules
        }

        # Log Setting
        New-ValentiaLog     

        # Obtain DeployMember IP or Hosts for BITsTransfer
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups

        # Parse Network Destination Path
        ("Parsing Network Destination Path {0} as :\ should change to $." -f $DestinationFolder) | Write-ValentiaVerboseDebug
        $DestinationPath = "$DestinationPath".Replace(":","$")

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""


    ### Process

        ("Uploading {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        # Create PSSession  for each DeployMember
        foreach ($DeployMember in $DeployMembers)
        {
            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
    
            # Set Destination
            $Destination = Join-Path "\\" $(Join-Path "$DeployMember" "$DestinationPath")

            if ($Directory)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-ChildItem -Path $SourcePath
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            elseif ($File)
            {
                # Set Source files in source
                try
                {
                    # No recurse
                    $SourceFiles = Get-Item -Path $SourcePath
                    
                    if ($SourceFiles.Attributes -eq "Directory")
                    {
                        $SuccessStatus += $false
                        $ErrorMessageDetail += "Target is Directory, you must set Filename with -File Switch."
                        throw "Target is Directory, you must set Filename with -File Switch."
                    }
                }
                catch
                {
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_
                    throw $_
                }
            }
            else
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += $_
                throw "Missing File or Directory switch. Please set -File or -Directory Switch to specify download type."
            }


            # Show Start-BitsTransfer Parameter
            Write-Warning ("[{0}]:Uploading {1} to {2}." -f $DeployMember,"$($SourceFiles.Name)", $Destination)
            Write-Verbose ("DestinationDeployFolder : {0}" -f $DeployFolder)
            Write-Verbose ("Aync Mode : {0}" -f $Async)

            if (Test-Path $SourcePath)
            {
                try
                {
                    switch ($true)
                    {
                        # Async Transfer
                        $Async {                    
                            $ScriptToRun = "Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload"
                            try
                            {
                                foreach ($SourceFile in $SourceFiles)
                                {
                                    try
                                    {
                                        # Run Job
                                        ("Running Async Job upload to {0}" -f $DeployMember) | Write-ValentiaVerboseDebug
                                        $Job = Start-BitsTransfer -Source $(($Sourcefile).FullName) -Destination $Destination -Credential $Credential -Asynchronous -DisplayName $DeployMember -Priority High -TransferType Upload

                                        # Waiting for complete job
                                        $Sleepms = 10
                                    }
                                    catch
                                    {
                                        $SuccessStatus += $false
                                        $ErrorMessageDetail += $_

                                        # Show Error Message
                                        throw $_
                                    }

                                }

                                $Sleepms = 10
                                # Retrieving transfer status and monitor for transffered
                                while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                                { 
                                    ("Current Job States was {0}, waiting for {1}ms {2}" -f ((Get-BitsTransfer).JobState | sort -Unique), $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count))) | Write-ValentiaVerboseDebug
                                    Sleep -Milliseconds $Sleepms
                                }

                                # Retrieve all files when completed
                                Get-BitsTransfer | Complete-BitsTransfer
                            }
                            catch
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                                $DurationTotal += $Duration
                            }

                        }
                        # NOT Async Transfer
                        default {
                            $ScriptToRun = "Start-BitsTransfer -Source $(($SourceFiles).fullname) -Destination $Destination -Credential $Credential -TransferType"

                            try
                            {
                                foreach($SourceFile in $SourceFiles)
                                {
                                    #Only start upload for file.
                                    if (-not((Get-Item $SourceFile.fullname).Attributes -eq "Directory"))
                                    {
                                        ("Uploading {0} to {1}'s {2}" -f $(($SourceFile).fullname), $DeployMember, $Destination) | Write-ValentiaVerboseDebug
                                        Start-BitsTransfer -Source $(($SourceFile).fullname) -Destination $Destination -Credential $Credential
                                    }
                                }
                            }
                            catch [System.Management.Automation.ActionPreferenceStopException]
                            {
                                $SuccessStatus += $false
                                $ErrorMessageDetail += $_

                                # Show Error Message
                                throw $_
                            }
                            finally
                            {
                                # Delete all not compelte job
                                Get-BitsTransfer | Remove-BitsTransfer

                                # Stopwatch
                                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                                ""
                            }
                        }
                    }
                }
                catch
                {

                    # Show Error Message
                    Write-Error $_

                    # Set ErrorResult
                    $SuccessStatus += $false
                    $ErrorMessageDetail += $_

                }
            }
            else
            {
                Write-Warning ("{0} could find from {1}. Skip to next." -f $Source, $DeployGroups)
            }
        }

    ### End

    }
    catch
    {

        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        if (-not $SkipException)
        {
            throw $_
        }
    }
    finally
    {
        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default

        # Get End Time
        $TimeEnd = (Get-Date).DateTime

        # obtain Result
        $CommandResult = [ordered]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            SkipException  = $SkipException
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $quiet = $PSBoundParameters.ContainsKey("quiet") -and $quiet
        WriteValentiaResultHost -quiet $quiet -CommandResult $CommandResult

        # output result
        OutValentiaResultLog -CommandResult $CommandResult

        # Cleanup valentia Environment
        Invoke-ValentiaClean

    }
}

# file loaded from path : \functions\Invokation\Upload\Invoke-ValentiaUpload.ps1

#Requires -Version 3.0

#-- Public Module Functions for Upload Listed Files --#

# uploadL

<#
.SYNOPSIS 
Use BITS Transfer to upload list files to remote server.

.DESCRIPTION
This function only support files listed in csv sat in upload context.
Make sure destination path format is not "c:\" but use "c$\" as UNC path.

.NOTES
Author: guitarrapc
Created: 13/July/2013


.EXAMPLE
uploadList -ListFile list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt


.EXAMPLE
uploadList list.csv -DeployGroup DeployGroup.ps1
--------------------------------------------
upload sourthfile to destinationfile as define in csv for hosts written in DeployGroup.ps1. You can omit -listFile parameter.

#   # CSV SAMPLE
#
#    Source, Destination
#    C:\Deployment\Upload\Upload.txt,C$\hogehoge\Upload.txt
#    C:\Deployment\Upload\DownLoad.txt,C$\hogehoge\DownLoad.txt
#>
function Invoke-ValentiaUploadList
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory, HelpMessage = "Input Clinet DestinationPath to save upload items.")]
        [string]$ListFile,

        [Parameter(Position = 1, Mandatory, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string]$DeployGroups,

        [Parameter(Position = 2, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 3, Mandatory = 0, HelpMessage = "Set this switch to execute command as Async (Job).")]
        [switch]$Async = $false,

        [Parameter(Position = 4, Mandatory = 0, HelpMessage = "Input PSCredential to use for wsman.")]
        [PSCredential]$Credential = (Get-ValentiaCredential),

        [Parameter(Position = 5, Mandatory = 0, HelpMessage = "Return success result even if there are error.")]
        [bool]$SkipException = $false
    )

    try
    {
       
    ### Begin
            
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        # Initialize Stopwatch
        [decimal]$TotalDuration = 0
        $TotalstopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
        # Initialize Errorstatus
        $SuccessStatus = $ErrorMessageDetail = @()

        # Get Start Time
        $TimeStart = (Get-Date).DateTime


        # Import default Configurations & Modules
        if ($PSBoundParameters['Verbose'])
        {
            # Import default Configurations
            $valeWarningMessages.warn_import_configuration | Write-ValentiaVerboseDebug
            Import-ValentiaConfiguration -Verbose

            # Import default Modules
            $valeWarningMessages.warn_import_modules | Write-ValentiaVerboseDebug
            Import-valentiaModules -Verbose
        }
        else
        {
            Import-ValentiaConfiguration
            Import-valentiaModules
        }

        # Log Setting
        New-ValentiaLog

        # Obtain DeployMember IP or Hosts for BITsTransfer
        "Get hostaddresses to connect." | Write-ValentiaVerboseDebug
        $DeployMembers = Get-valentiaGroup -DeployFolder $DeployFolder -DeployGroup $DeployGroups
        
        # Set SourcePath to retrieve target File full path (default Upload folder of deployment)
        $SourceFolder = Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Upload)

        if (-not(Test-Path $SourceFolder))
        {
            ("SourceFolder not found creating {0}" -f $SourceFolder) | Write-ValentiaVerboseDebug
            New-Item -Path $SourceFolder -ItemType Directory            
        }

        try
        {
            "Defining ListFile full path." | Write-ValentiaVerboseDebug
            $SourcePath = Join-Path $SourceFolder $ListFile -Resolve
        }
        catch
        {
            $SuccessStatus += $false
            $ErrorMessageDetail += $_
            throw $_
        }
        
        # Obtain List of File upload
        ("Retrive souce file list from {0} `n" -f $SourcePath) | Write-ValentiaVerboseDebug
        $List = Import-Csv $SourcePath -Delimiter "," 

        # Show Stopwatch for Begin section
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tDuration Second for Begin Section: {0}" -f $TotalDuration)
        ""

    ### Process

        (" Uploading Files written in {0} to Target Computer : [{1}] `n" -f $SourcePath, $DeployMembers) | Write-ValentiaVerboseDebug

        # Stopwatch
        [decimal]$DurationTotal = 0

        foreach ($DeployMember in $DeployMembers){

            # Stopwatch
            $stopwatchSession = [System.Diagnostics.Stopwatch]::StartNew()
            
            #Create New List
            $NewList = $List | %{
                [PSCustomObject]@{
                    Source = $_.source
                    Destination = "\\" + $DeployMember + "\" + $($_.destination)
                }
            }
            
            try
            {
                # Run Start-BitsTransfer
                Write-Warning ("[{0}]: Uploading {1} to {2} ." -f $DeployMember ,"$($NewList.Source)", "$($NewList.Destination)")
                Write-Verbose ("ListFile : {0}" -f $SourcePath)
                Write-Verbose ("Aysnc : {0}" -f $Async)

                if ($Async)
                {
                    #Command Detail
                    $ScriptToRun = '$NewList | Start-BitsTransfer -Credential $Credential -Async'

                    # Run Start-BitsTransfer retrieving files from List csv with Async switch
                    ("Running Async uploadL to '{0}'" -f $DeployMember) | Write-ValentiaVerboseDebug
                    $BitsJob = $NewList | Start-BitsTransfer -Credential $Credential -Async

                    # Monitoring Bits Transfer States complete
                    $Sleepms = 10
                    while (((Get-BitsTransfer).JobState -contains "Transferring") -or ((Get-BitsTransfer).JobState -contains "Connecting") -or ((Get-BitsTransfer).JobState -contains "Queued")) `
                    {
                        ("Current Job States was '{0}', waiting for '{1}' ms '{2}'" -f "$((Get-BitsTransfer).JobState | sort -Unique)", $Sleepms, (((Get-BitsTransfer | where JobState -eq "Transferred").count) / $((Get-BitsTransfer).count))) | Write-ValentiaVerboseDebug
                        sleep -Milliseconds $Sleepms
                    }

                    # Send Complete message to make file from ****.Tmp
                    ("Completing Async uploadL to '{0}'" -f $DeployMember) | Write-ValentiaVerboseDebug
                    # Retrieve all files when completed
                    Get-BitsTransfer | Complete-BitsTransfer

                }
                else
                {
                    #Command Detail
                    $ScriptToRun = "$NewList | Start-BitsTransfer -Credential $Credential"

                    # Run Start-BitsTransfer retrieving files from List csv
                    ("Running Sync uploadL to {0}" -f $DeployMember) | Write-ValentiaVerboseDebug
                    $NewList | Start-BitsTransfer -Credential $Credential
                }
            }
            catch
            {
                $SuccessStatus += $false
                $ErrorMessageDetail += $_

                # Show Error Message
                throw $_
            }
            finally
            {
                "Delete all not compelte job" | Write-ValentiaVerboseDebug
                Get-BitsTransfer | Remove-BitsTransfer

                # Stopwatch
                $Duration = $stopwatchSession.Elapsed.TotalSeconds
                Write-Verbose ("Session duration Second : {0}" -f $Duration)
                ""
            }
        }

    ### End

    }
    catch
    {
        $SuccessStatus += $false
        $ErrorMessageDetail += $_
        if (-not $SkipException)
        {
            throw $_
        }
    }
    finally
    {

        # Stopwatch
        $TotalDuration = $TotalstopwatchSession.Elapsed.TotalSeconds
        Write-Verbose ("`t`tTotal duration Second`t: {0}" -f $TotalDuration)
        "" | Out-Default

        # Get End Time
        $TimeEnd = (Get-Date).DateTime

        # obtain Result
        $CommandResult = [ordered]@{
            Success = !($SuccessStatus -contains $false)
            TimeStart = $TimeStart
            TimeEnd = $TimeEnd
            TotalDuration = $TotalDuration
            Module = "$($MyInvocation.MyCommand.Module)"
            Cmdlet = "$($MyInvocation.MyCommand.Name)"
            Alias = "$((Get-Alias -Definition $MyInvocation.MyCommand.Name).Name)"
            ScriptBlock = "$ScriptToRun"
            DeployGroup = "$DeployGroups"
            TargetHosCount = $($DeployMembers.count)
            TargetHosts = "$DeployMembers"
            SkipException  = $SkipException
            ErrorMessage = $($ErrorMessageDetail | where {$_ -ne $null} | sort -Unique)
        }

        # show result
        $quiet = $PSBoundParameters.ContainsKey("quiet") -and $quiet
        WriteValentiaResultHost -quiet $quiet -CommandResult $CommandResult

        # output result
        OutValentiaResultLog -CommandResult $CommandResult

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}

# file loaded from path : \functions\Invokation\Upload\Invoke-ValentiaUploadList.ps1

