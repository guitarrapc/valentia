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
