#Requires -Version 3.0

function Set-ValentiaCredential
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(mandatory = $false, position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName = $valentia.name,

        [Parameter(mandatory = $false, position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credential = (Get-Credential -User $valentia.Users.DeployUser -Message "Input password to be save."),

        [Parameter(mandatory = $false, position = 2)]
        [ValidateNotNullOrEmpty()]
        [Valentia.CS.CredType]$Type = [Valentia.CS.CredType]::Generic
    )
    
    [Valentia.CS.CredentialManager]::Write($TargetName, $Credential, $Type)
}