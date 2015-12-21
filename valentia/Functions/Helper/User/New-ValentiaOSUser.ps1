#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

<#
.SYNOPSIS 
Create New Local User for Deployment

.DESCRIPTION
Deployment will use deploy user account credential to avoid any change for administartor.
You must add all this user credential for each clients.

# User Flag Property Samples. You should combinate these 0x00zz if required.
#
#  &H0001    Run LogOn Script　
#  0X0001    ADS_UF_SCRIPT 
#
#  &H0002    Account Disable
#  0X0002    ADS_UF_ACCOUNTDISABLE
#
#  &H0008    Account requires Home Directory
#  0X0008    ADS_UF_HOMEDIR_REQUIRED
#
#  &H0010    Account Lockout
#  0X0010    ADS_UF_LOCKOUT
#
#  &H0020    No Password reqyured for account
#  0X0020    ADS_UF_PASSWD_NOTREQD
#
#  &H0040    No change Password
#  0X0040    ADS_UF_PASSWD_CANT_CHANGE
#
#  &H0080    Allow Encypted Text Password
#  0X0080    ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED
#
#  0X0100    ADS_UF_TEMP_DUPLICATE_ACCOUNT
#  0X0200    ADS_UF_NORMAL_ACCOUNT
#  0X0800    ADS_UF_INTERDOMAIN_TRUST_ACCOUNT
#  0X1000    ADS_UF_WORKSTATION_TRUST_ACCOUNT
#  0X2000    ADS_UF_SERVER_TRUST_ACCOUNT
#
#  &H10000   Password infinit
#  0X10000   ADS_UF_DONT_EXPIRE_PASSWD
#
#  0X20000   ADS_UF_MNS_LOGON_ACCOUNT
#
#  &H40000   Smart Card Required
#  0X40000   ADS_UF_SMARTCARD_REQUIRED
#
#  0X80000   ADS_UF_TRUSTED_FOR_DELEGATION
#  0X100000  ADS_UF_NOT_DELEGATED
#  0x200000  ADS_UF_USE_DES_KEY_ONLY
#
#  0x400000  ADS_UF_DONT_REQUIRE_PREAUTH
#
#  &H800000  Password expired
#  0x800000  ADS_UF_PASSWORD_EXPIRED
#
#  0x1000000 ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaOSUser
--------------------------------------------
Recommend - Secure Input.
secure prompt will up and mask your PASSWORD input as *****.

.EXAMPLE
New-valentiaOSUser -Password "1231231qawerqwe87$%"
--------------------------------------------
NOT-Recommend - Unsecure Input
Visible prompt will up and non-mask your PASSWORD input as *****.
#>
function New-ValentiaOSUser
{
    [CmdletBinding()]
    param
    (
        [parameter(position  = 0, mandatory = $false, HelpMessage = "PSCredential for New OS User setup.")]
        [PSCredential]$credential = (Get-Credential -Credential $valentia.users.deployUser),

        [parameter(position  = 1, mandatory = $false, HelpMessage = "User account belonging UserGroup.")]
        [string]$Group = $valentia.group.Name,

        [parameter(position  = 2, mandatory = $false, HelpMessage = "User flag bit to set.")]
        [string]$UserFlag = $valentia.group.userFlag
    )

    process
    {
        if ($IsUserExist)
        {
            Set-UserPassword @paramUser
        }
        else
        {
            New-User @paramUser
        }

        $Domain= Get-DomainName
        $paramUserFlag = @{
            targetUser = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0}/{1}/{2}" -f $Domain, $HostPC, $user))
            UserFlag   = $UserFlag
        }
        Set-UserFlag @paramUserFlag
        
        if ((Get-UserAndGroup @paramUserAndGroup).Groups -ne $Group)
        {
            Add-UserToUserGroup @paramGroup
        }
    }

    end
    {
        Get-UserAndGroup @paramUserAndGroup
    }

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
        Set-StrictMode -Version latest

        $HostPC = [System.Environment]::MachineName
        $user = $credential.UserName
        $DirectoryComputer = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0},computer" -f $HostPC))
        $IsUserExist = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount='true'" | where Name -eq $user

        $paramUser = @{
            user       = $user
            HostPC     = $HostPC
            Credential = $credential
        }

        $paramGroup = @{
            Group  = $Group
            HostPC = $HostPC
            user   = $user
        }

        $paramUserAndGroup = @{
            DirectoryComputer = $DirectoryComputer
            user              = $user
        }

        function Get-DomainName
        {
            if ((Get-WMIObject Win32_ComputerSystem).PartOfDomain)
            {
                $dn = (Get-CimInstance -ClassName win32_computersystem).Domain
                return (Get-CimInstance -ClassName Win32_NTDomain | where DNSForestName -eq $dn).DomainName
            }
            else
            {
                return (Get-CimInstance -ClassName win32_computersystem).Domain
            }
        }

        function New-User ($user, $HostPC, $credential)
        {
            ("User '{0}' not exist, start creating user." -f $user) | Write-ValentiaVerboseDebug
            $NewUser = $DirectoryComputer.Create("user", $user)
            $NewUser.SetPassword(($credential.GetNetworkCredential().password))
            $NewUser.SetInfo()
        }

        function Set-UserPassword ($user, $HostPC, $credential)
        {
            ("User '{0}' already exist, start reset password." -f $user) | Write-ValentiaVerboseDebug
            $SetUser = New-Object System.DirectoryServices.DirectoryEntry(("WinNT://{0}/{1}" -f $HostPC, $user))
            $SetUser.psbase.invoke('SetPassword', $credential.GetNetworkCredential().Password)
        }

        function Set-UserFlag ($targetUser, $UserFlag)
        {
            "Set userflag to define account as bor '{0}'" -f $UserFlag | Write-ValentiaVerboseDebug
            $userFlags = $targetUser.Get("UserFlags")
            $userFlags = $userFlags -bor $UserFlag 
            $targetUser.Put("UserFlags", $userFlags)
            $targetUser.SetInfo()
        }

        function Add-UserToUserGroup ($Group, $HostPC, $user)
        {
            ("Assign User to UserGroup '{0}'" -f $Group) | Write-ValentiaVerboseDebug
            $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
            $DirectoryGroup.Add(("WinNT://{0}/{1}" -f $HostPC, $user))
        }

        function Get-UserAndGroup ($DirectoryComputer, $user)
        {
            $DirectoryComputer.Children `
            | where SchemaClassName -eq 'user' `
            | where Name -eq $user `
            | %{ 
                $groups = $_.Groups() | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
                $_ | %{
                    [PSCustomObject]@{
                        UserName = $_.Name
                        Groups   = $groups
                    }
                }
            }
        }
    }
}
