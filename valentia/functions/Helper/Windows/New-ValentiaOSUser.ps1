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
            $SecretPassword = (Get-Credential -UserName $users -Message "Type your valentia execusion user password").Password
        }
    }

    process
    {
        
        "Checking type of users variables to retrieve property" | Write-ValentiaVerboseDebug
        if ($Users -is [System.Management.Automation.PSCustomObject])
        {
            ("Get properties for Parameter '{0}'." -f $Users) | Write-ValentiaVerboseDebug
            $pname = $Users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            ("Foreach each Users in {0}" -f $Users) | Write-ValentiaVerboseDebug
            foreach ($p in $pname)
            {
                if ($users.$p -notin $ExistingUsers.Name)
                {
                    # Create User
                    ("{0} not exist, start creating user." -f $Users.$p) | Write-ValentiaVerboseDebug
                    $newuser = $DirectoryComputer.Create("user", $Users.$p)
                    $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                    $newuser.SetInfo()

                    # Get Account UserFlag to set
                    $userFlags = $newuser.Get("UserFlags")

                    #UserFlag for password (ex. infinity & No change Password)
                    "Define user flag to define account" | Write-ValentiaVerboseDebug
                    $userFlags = $userFlags -bor 0X10040

                    "Put user flag to define account" | Write-ValentiaVerboseDebug
                    $newuser.Put("UserFlags", $userFlags)

                    "Set user flag to define account" | Write-ValentiaVerboseDebug
                    $newuser.SetInfo()

                    #Assign Group for this user
                    ("Assign User to UserGroup {0}" -f $UserGroup) | Write-ValentiaVerboseDebug
                    $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                    $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users.$p)
                }
                else
                {
                    ("UserName {0} already exist. Nothing had changed." -f $Users.$p) | Write-ValentiaVerboseDebug
                }
            }
        }
        elseif($Users -is [System.String])
        {
            ("Execute with only a user defined in {0}" -f $users) | Write-ValentiaVerboseDebug
            if ($users -notin $ExistingUsers.Name)
            {
                # Create User
                ("{0} not exist, start creating user." -f $users) | Write-ValentiaVerboseDebug
                $newuser = $DirectoryComputer.Create("user", $Users)
                $newuser.SetPassword([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecretPassword)))
                $newuser.SetInfo()

                # Get Account UserFlag to set
                $userFlags = $newuser.Get("UserFlags")

                #UserFlag for password (ex. infinity & No change Password)
                "Define user flag to define account" | Write-ValentiaVerboseDebug
                $userFlags = $userFlags -bor 0X10040

                "Put user flag to define account" | Write-ValentiaVerboseDebug
                $newuser.Put("UserFlags", $userFlags)

                "Set user flag to define account" | Write-ValentiaVerboseDebug
                $newuser.SetInfo()

                #Assign Group for this user
                ("Assign User to UserGroup {0}" -f $UserGroup) | Write-ValentiaVerboseDebug
                $DirectoryGroup = $DirectoryComputer.GetObject("group", $Group)
                $DirectoryGroup.Add("WinNT://" + $HostPC + "/" + $Users)
            }
        }
        else
        {
            throw ("Users must passed as string or custom define in {0}" -f $valentia.defaultconfigurationfile)
        }
    }
}
