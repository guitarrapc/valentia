#Requires -Version 3.0

function Find-ValentiaCredential
{
    [OutputType([PSCredential])]
    [CmdletBinding()]
    param
    ()
    
    return [Valentia.CS.CredentialManager]::List();
}