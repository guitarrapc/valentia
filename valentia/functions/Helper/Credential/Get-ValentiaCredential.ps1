#Requires -Version 3.0

function Get-ValentiaCredential
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
        [WindowsCredentialManagerType]
        $Type = [WindowsCredentialManagerType]::Generic
    )
 
    $script:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

    $script:CSPath = Join-Path $valentia.modulePath $valentia.cSharpPath -Resolve
    $script:CredReadCS = Join-Path $CSPath CredRead.cs -Resolve
    $script:sig = Get-Content -Path $CredReadCS -Raw

    $script:addType = @{
        MemberDefinition = $sig
        Namespace        = "Advapi32"
        Name             = "Util"
    }
    Add-ValentiaTypeMemberDefinition @addType -PassThru `
    | select -First 1 `
    | %{
        $script:typeQualifiedName = $_.AssemblyQualifiedName
        $script:typeFullName = $_.FullName
    }

    $script:nCredPtr= New-Object IntPtr
    if ([System.Type]::GetType($typeQualifiedName)::CredRead($TargetName, $Type.value__, 0, [ref]$nCredPtr))
    {
        $script:critCred = New-Object $typeFullName+CriticalCredentialHandle $nCredPtr
        $script:cred = $critCred.GetCredential()
        $script:username = $cred.UserName
        $script:securePassword = $cred.CredentialBlob | ConvertTo-SecureString -AsPlainText -Force
        $cred = $null
        return New-Object System.Management.Automation.PSCredential $username, $securePassword
    }
    else
    {
        Write-Verbose ("No credentials found in Windows Credential Manager for TargetName: '{0}' with Type '{1}'" -f $TargetName, $Type)
    }
}