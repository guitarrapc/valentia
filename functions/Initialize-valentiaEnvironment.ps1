#Requires -Version 3.0

#-- Running prerequisite Initialize OS Setting Module Functions --#

# Initial
function Initialize-ValentiaEnvironment
{

<#

.SYNOPSIS 
Initializing valentia PSRemoting environment for Deploy Server and client.

.DESCRIPTION
Run as Admin Priviledge. 

Set-ExecutionPolicy (Default : RemoteSigned)
Enable-PSRemoting
Add hosts to trustedHosts  (Default : *)
Set MaxShellsPerUser from 25 to 100
Add PowerShell Remoting Inbound rule to Firewall (Default : TCP 5985)
Disable Enhanced Security for Internet Explorer (Default : True)
Create OS user for Deploy connection. (Default : ec2-user)
Create Windows PowerShell Module Folder for DeployUser (Default : $home\Documents\WindowsPowerShell\Modules)
Create/Revise Deploy user credential secure file. (Server Only / Default : True)
Create Deploy Folders (Server Only / Default : True)
Set HostName as format (white-$HostUsage-IP)
Get Status for Reboot Status


.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
Initialize-valentiaEnvironment -Server
--------------------------------------------
Setup Server Environment

.EXAMPLE
Setup Client Environment
--------------------------------------------
Initialize-valentiaEnvironment -Client

.EXAMPLE
Initialize-valentiaEnvironment -Client -NoOSUser
--------------------------------------------
Setup Client Environment and Skip Deploy OSUser creattion

.EXAMPLE
Setup Server Environment withour OSUser and Credential file revise
--------------------------------------------
read production-hoge.ps1 from c:\test.

#>

    [CmdletBinding(DefaultParameterSetName = "Server")]
    param
    (
        [parameter(
            HelpMessage = "Select this switch If you don't want to initialize Deploy User.")]
        [switch]
        $NoOSUser = $false,

        [parameter(
            ParameterSetName = "Server",
            HelpMessage = "Select this switch If you don't want to Save/Revise password.")]
        [switch]
        $NoPassSave = $false,

        [parameter(
            ParameterSetName = "Server",
            HelpMessage = "Select this switch to Initialize setup for Deploy Server.")]
        [switch]
        $Server,

        [parameter(
            ParameterSetName = "Client",
            HelpMessage = "Select this switch to Initialize setup for Deploy Client.")]
        [switch]
        $Client,

        [Parameter(
            HelpMessage = "Select this switch If you don't want to Set HostName.")]
        [switch]
        $NoSetHostName = $false,

        [Parameter(
            HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [parameter(
            HelpMessage = "Select this switch If you don't want to REboot.")]
        [switch]
        $NoReboot = $false,

        [parameter(
        HelpMessage = "Select this switch If you want to Forece Restart without prompt.")]
        [switch]
        $ForceReboot = $false,

        [parameter(
            HelpMessage = "Input Trusted Hosts you want to enable. Default : ""*"" ")]
        [string]
        $TrustedHosts = "*",

        [parameter(
        HelpMessage = "Select this switch If you want to skip setup PSRemoting.")]
        [switch]
        $SkipEnablePSRemoting = $false

    )

    begin
    {
        # Check -HostUsage parameter is null or emptry
        if ($NoSetHostName -eq $false)
        {
            if ([string]::IsNullOrEmpty($HostUsage))
            {
                throw "HostUsage parameter was null or empty. Set HostUsage is required to Set HostName."
            }
        }

        # Check Elevated or not
        Write-Verbose "checking is this user elevated or not."
        Write-Verbose "Command : Test-ValentiaPowerShellElevated"
        if(-not(Test-ValentiaPowerShellElevated))
        {
	        throw "To run this Cmdlet on UAC 'Windows Vista, 7, 8, Windows Server 2008, 2008 R2, 2012 and later versions of Windows' must start an elevated PowerShell console."
        }
        else
        {
            Write-Verbose "Current session is already elevated, continue setup environment."
        }

    }

    process
    {
        # setup ScriptFile Reading
        Write-Verbose "Command : Set-ExecutionPolicy RemoteSigned -Force"
        Set-ExecutionPolicy RemoteSigned -Force -ErrorAction Stop

        if (-not($SkipEnablePSRemoting))
        {
            # setup PSRemoting
            Write-Verbose "Command : Enable-PSRemoting -Force"
            Enable-PSRemoting -Force -ErrorAction Stop
        }

        # Add $TrustedHosts hosts to trustedhosts
        Write-Verbose "Command : Enable-WsManTrustedHosts -TrustedHosts $TrustedHosts"
        Enable-WsManTrustedHosts -TrustedHosts $TrustedHosts -ErrorAction Stop

        # Configure WSMan MaxShellsPerUser to prevent error "The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded."
        # default 25 change to 100
        Write-Verbose "Command : Set-WsManMaxShellsPerUser -ShellsPerUser 100"
        Set-WsManMaxShellsPerUser -ShellsPerUser 100 -ErrorAction Stop

        # Enble WindowsPowerShell Remoting Firewall Rule
        Write-Verbose "Command : New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985"
        New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985

        # Set FireWall Status from Public to Private (not use for a while with EC2 on AWS)
        Write-Verbose "Command : Set-NetConnectionProfile -NetworkCategory Private"
        Set-NetConnectionProfile -NetworkCategory Private

        # Disable Enhanced Security for Internet Explorer
        Write-Verbose "Command : Disable-ValentiaEnhancedIESecutiry"
        Disable-ValentiaEnhancedIESecutiry

        # Add ec2-user 
        if ($NoOSUser)
        {
            Write-Verbose "NoOSUser switch was enabled, skipping create OSUser."
        }
        else
        {
            Write-Verbose "Command : New-ValentiaOSUser"
            New-ValentiaOSUser
        }



        # Create PowerShell ModulePath
        Write-Verbose "Create PowerShell ModulePath for deploy user."

        $users = $valentia.users
        if ($users -is [System.Management.Automation.PSCustomObject])
        {
            Write-Verbose ("Get properties for Parameter '{0}'." -f $users)
            $pname = $users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            Write-Verbose ("Loop each Users in {0}" -f $Users)
            foreach ($p in $pname)
            {

                Write-Verbose "Get Path for WindowsPowerShell modules"
                $PSModulePath = "C:\Users\$($Users.$p)\Documents\WindowsPowerShell\Modules"

                if (-not(Test-Path $PSModulePath))
                {
                    Write-Verbose "Create Module path"
                    New-Item -Path $PSModulePath -ItemType Directory -Force
                }
                else
                {
                    Write-Verbose ("{0} already exist. Nothing had changed. `n" -f $PSModulePath)
                }

            }
        }




        # Only if $Server swtich was passed. (Default $true, Only disabled when $client switch was passed.)
        if ($Server)
        {
            # Create Deploy Folder
            Write-Verbose "Command : New-ValentiaFolder"
            New-ValentiaFolder


            # Create Deploy user credential $user.pass
            Write-Verbose "Checking for Deploy User Credential secure credentail creation."
            if ($NoPassSave)
            {
                Write-Verbose "NoPassSave switch was enabled, skipping Create/Revise secure password file."
            }
            else
            {
                Write-Verbose "Create Deploy user credential .pass"
                Write-Verbose "Command : New-ValentiaCredential"
                New-ValentiaCredential
            }
        }



        # Set Host Computer Name (Checking if server name is same as current or not)
        Write-Verbose "Checking for HostName Status is follow rule and set if not correct."
        if ($NoSetHostName)
        {
            Write-Verbose "NoSetHostName switch was enabled, skipping Set HostName."
        }
        else
        {
            Write-Verbose "Command : Set-ValentiaHostName -HostUsage $HostUsage"
            Set-ValentiaHostName -HostUsage $HostUsage
        }


        # Checking for Reboot Status, if pending then prompt for reboot confirmation.
        Write-Verbose "Command : if ($NoReboot){Write-Verbose 'NoReboot switch was enabled, skipping reboot.'}elseif ($ForceReboot){Restart-Computer -Force}else{Restart-Computer -Force -Confirm}"
        if(Get-ValentiaRebootRequiredStatus)
        {
            if ($NoReboot)
            {
                Write-Verbose 'NoReboot switch was enabled, skipping reboot.'
            }
            elseif ($ForceReboot)
            {
                Restart-Computer -Force
            }
            else
            {
                Restart-Computer -Force -Confirm
            }
        }

    }
    
    end
    {
        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}
