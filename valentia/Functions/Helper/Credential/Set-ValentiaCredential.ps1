#Requires -Version 3.0

function Set-ValentiaCredential
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(mandatory = $false, position = 2)]
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