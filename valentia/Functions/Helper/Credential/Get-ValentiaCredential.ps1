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
 
    $private:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

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