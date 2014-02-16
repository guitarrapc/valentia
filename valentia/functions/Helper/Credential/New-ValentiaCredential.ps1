#Requires -Version 3.0

#-- PSRemoting Connect Credential Module Functions --#

function New-ValentiaCredential
{

<#

.SYNOPSIS 
Create Remote Login Credential for valentia

.DESCRIPTION
Log-in credential will preserve for this machine only. You could not copy and reuse.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-ValentiaCredential
--------------------------------------------
This will create credential with default deploy user specified config as $valentia.users.DeployUser

.EXAMPLE
New-ValentiaCredential -User hogehoge
--------------------------------------------
You can specify other user credential if required.

#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Enter user and Password.")]
        [string]
        $BinFolder = (Join-Path $Script:valentia.RootPath $($valentia.BranchFolder).Bin),

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Enter Secure string output path.")]
        [string]
        $User = $valentia.users.DeployUser
    )

    $ErrorActionPreference = $valentia.errorPreference

    $cred = Get-Credential -UserName $User -Message ("Input {0} Password to be save." -f $User)


    if ($User -eq "")
    {
        $User = $cred.UserName
    }
        
    if (-not([string]::IsNullOrEmpty($cred.Password)))
    {

        try
        {
            # Set Credential save path        
            $currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $replaceuser = $currentuser.Replace("\","_")
            $CredFolder = Join-Path $BinFolder $replaceuser

            # check credentail save path exist or not
            if (-not(Test-Path $CredFolder))
            {
                New-Item -ItemType Directory -Path $BinFolder -Name $replaceuser -Force
            }

            # Set CredPath with current Username
            $CredPath = Join-Path $CredFolder "$User.pass"
        }
        catch
        {
            throw $_
        }

        # get SecureString
        try
        {
            $savePass = $cred.Password | ConvertFrom-SecureString
        }
        catch
        {
            throw 'Credential input was empty!! "None pass" is not allowed.'
        }

        
        
        if (Test-Path $CredPath)
        {
            ("Remove existing Credential Password for {0} found in {1}" -f $User, $CredPath) | Write-ValentiaVerboseDebug
            Remove-Item -Path $CredPath -Force -Confirm
        }


        ("Save Credential Password for {0} set in {1}" -f $User, $CredPath) | Write-ValentiaVerboseDebug
        $savePass | Set-Content -Path $CredPath -Force


        ("Completed: Credential Password for {0} had been sat in {1}" -f $User, $CredPath) | Write-ValentiaVerboseDebug
    }
    else
    {
        throw 'Credential input had been aborted or empty!! "None pass" is not allowed and make sure input "UserName" and "Password" to be use for valentia!'
    }

    # Cleanup valentia Environment
    Invoke-ValentiaClean
}
