#Requires -Version 3.0

#-- Prerequisite OS Setting Module Functions --#

function New-ValentiaOSUser
{

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

    [CmdletBinding(DefaultParameterSetName = 'Secret')]
    param
    (
        [parameter(
            mandatory　= 0,
            HelpMessage = "User account Name.")]
        $Users = $valentia.users.deployuser,

        [parameter(
            mandatory = 0,
            ParameterSetName = 'Secret',
            HelpMessage = "User account Password.")]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]
        $SecuredPassword,

        [parameter(
            mandatory = 0,
            ParameterSetName = 'Plain',
            HelpMessage = "User account Password.")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Password,

        [parameter(
            mandatory = 0,
            HelpMessage = "User account belonging UserGroup.")]
        [string]
        $Group = $valentia.group
    )

    begin
    {
        $HostPC = [System.Environment]::MachineName
        $DirectoryComputer = New-Object System.DirectoryServices.DirectoryEntry("WinNT://" + $HostPC + ",computer")
        $ExistingUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount='true'"

        if ($Password)
        {
            $SecretPassword = $Password | ConvertTo-SecureString -AsPlainText -Force
        }
        elseif ($SecuredPassword)
        {
            $SecretPassword = $SecuredPassword
        }
        else
        {
            $SecretPassword = Read-Host -AsSecureString -Prompt ("Type your OS User password for '{0}'" -f $($users -join ","))
        }
    }

    process
    {
        
        Write-Verbose "Checking type of users variables to retrieve property"
        if ($Users -is [System.Management.Automation.PSCustomObject])
        {
            Write-Verbose ("Get properties for Parameter '{0}'." -f $Users)
            $pname = $Users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            Write-Verbose ("Loop each Users in {0}" -f $Users)
            foreach ($p in $pname){
                if ($users.$p -notin $ExistingUsers.Name)
                {
                    # Create User
                    Write-Verbose ("{0} not exist, start creating user." -f $Users.$p)
                    $newuser = $DirectoryComputer.Create("user", $Users.$p)
                    $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                    $newuser.SetInfo()

                    # Get Account UserFlag to set
                    $userFlags = $newuser.Get("UserFlags")

                    #UserFlag for password (ex. infinity & No change Password)
                    Write-Verbose "Define user flag to define account"
                    $userFlags = $userFlags -bor 0X10040

                    Write-Verbose "Put user flag to define account"
                    $newuser.Put("UserFlags", $userFlags)

                    Write-Verbose "Set user flag to define account"
                    $newuser.SetInfo()

                    #Assign Group for this user
                    Write-Verbose ("Assign User to UserGroup {0}" -f $UserGroup)
                    $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                    $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users.$p)
                }
                else
                {
                    Write-Verbose ("UserName {0} already exist. Nothing had changed." -f $Users.$p)
                }
            }
        }
        elseif($Users -is [System.String])
        {
            Write-Verbose ("Execute with only a user defined in {0}" -f $users)
            if ($users -notin $ExistingUsers.Name)
            {
                # Create User
                Write-Verbose ("{0} not exist, start creating user." -f $users)
                $newuser = $DirectoryComputer.Create("user", $Users)
                $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                $newuser.SetInfo()

                # Get Account UserFlag to set
                $userFlags = $newuser.Get("UserFlags")

                #UserFlag for password (ex. infinity & No change Password)
                Write-Verbose "Define user flag to define account"
                $userFlags = $userFlags -bor 0X10040

                Write-Verbose "Put user flag to define account"
                $newuser.Put("UserFlags", $userFlags)

                Write-Verbose "Set user flag to define account"
                $newuser.SetInfo()

                #Assign Group for this user
                Write-Verbose ("Assign User to UserGroup {0}" -f $UserGroup)
                $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users)
            }
        }
        else
        {
            throw ("Users must passed as string or custom define in {0}" -f $valentia.defaultconfigurationfile)
        }
    }

    end
    {
    }
}
