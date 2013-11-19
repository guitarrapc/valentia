#Requires -Version 3.0

#-- PSRemoting Connect Credential Module Functions --#

# cred
function Get-ValentiaCredential
{

<#

.SYNOPSIS 
Get Secure String of Deployment User / Password

.DESCRIPTION
Decript password file and set as PSCredential.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Get-ValentiaCredential
--------------------------------------------
This will get credential with default deploy user specified config as $valentia.users.DeployUser. Make sure credential was already created by New-ValentiaCredential.

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Enter user and Password.")]
        [string]
        $User = $valentia.users.DeployUser,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Enter Secure string saved path.")]
        [string]
        $BinFolder = (Join-Path $Script:valentia.RootPath $($valentia.BranchFolder).Bin)
    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference

        if([string]::IsNullOrEmpty($User))
        {
            throw '"$User" was "", input User.'
        }
    }

    process
    {

        # Set Credential save path        
        $currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $replaceuser = $currentuser.Replace("\","_")
        $credFolder = Join-Path $BinFolder $replaceuser

        # check credential save path exist or not
        if (-not(Test-Path $credFolder))
        {
            New-Item -ItemType Directory -Path $BinFolder -Name $replaceuser -Force
        }

        # Set CredPath with current Username
        $credPath = Join-Path $credFolder "$User.pass"

        if (Test-Path $CredPath)
        {
            $credPassword = Get-Content -Path $credPath | ConvertTo-SecureString

            Write-Verbose ("Obtain credential for User [ {0} ] from {1} " -f $User, $credPath)
            $credential = New-Object System.Management.Automation.PSCredential $User,$credPassword                
        }
    }
    
    end
    {
        $credential
    }
}
