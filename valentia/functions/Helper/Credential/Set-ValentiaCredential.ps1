#Requires -Version 3.0

function Set-ValentiaCredential
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            mandatory = 0,
            position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TargetName = $valentia.name,

        [Parameter(
            mandatory = 0,
            position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(
            mandatory = 0,
            position = 2)]
        [ValidateNotNullOrEmpty()]
        [WindowsCredentialManagerType]
        $Type = [WindowsCredentialManagerType]::Generic
    )

    $script:ErrorActionPreference = $valentia.errorPreference

    $script:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
    $script:CredWriteCS = Join-Path $CSPath CredWrite.cs -Resolve
    $script:sig = Get-Content -Path $CredWriteCS -Raw

    if ($null -eq $Credential)
    {
        $Credential  = (Get-Credential -user $valentia.users.DeployUser -Message ("Input {0} Password to be save." -f $valentia.users.DeployUser))
    }

    $script:domain = $Credential.GetNetworkCredential().Domain
    $script:user = $Credential.GetNetworkCredential().UserName
    $script:password = $Credential.GetNetworkCredential().Password
    switch ([String]::IsNullOrWhiteSpace($domain))
    {
        $true   {$userName = $user}
        $false  {$userName = $domain, $user -join "\"}
    }

    $script:addType = @{
        MemberDefinition = $sig
        Namespace        = "Advapi32"
        Name             = "Util"
    }
    $script:typeName = Add-ValentiaTypeMemberDefinition @addType -PassThru
    $script:typeFullName = $typeName.FullName | select -Last  1
    $script:typeQualifiedName = $typeName.AssemblyQualifiedName | select -First 1
    
    $script:cred = New-Object $typeFullName
    $cred.flags = 0
    $cred.type = $Type.value__
    $cred.targetName = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($TargetName)
    $cred.userName = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($userName)
    $cred.attributeCount = 0
    $cred.persist = 2
    $cred.credentialBlobSize = [System.Text.Encoding]::Unicode.GetBytes($password).length
    $cred.credentialBlob = [System.Runtime.InteropServices.Marshal]::StringToCoTaskMemUni($password)
    $script:result = [System.Type]::GetType($typeQualifiedName)::CredWrite([ref]$cred,0)

    if ($true -eq $result)
    {
        return $true
    }
    else
    {
        return $false
    }
}