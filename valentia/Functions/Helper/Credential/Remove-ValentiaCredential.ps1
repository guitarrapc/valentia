#Requires -Version 3.0

function Remove-ValentiaCredential
{
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
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
        if ($CredentialType::CredDelete($TargetName, $Type.value__, 0))
        {
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