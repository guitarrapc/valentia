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
        $ErrorActionPreference = $valentia.errorPreference

        # Check -HostUsage parameter is null or emptry
        if ($NoSetHostName -eq $false)
        {
            if ([string]::IsNullOrEmpty($HostUsage))
            {
                throw "HostUsage parameter was null or empty. Set HostUsage is required to Set HostName."
            }
        }

        # Check Elevated or not
        "checking is this user elevated or not." | Write-ValentiaVerboseDebug
        if(-not(Test-ValentiaPowerShellElevated))
        {
            throw "To run this Cmdlet on UAC 'Windows Vista, 7, 8, Windows Server 2008, 2008 R2, 2012 and later versions of Windows' must start an elevated PowerShell console."
        }
        else
        {
            "Current session is already elevated, continue setup environment." | Write-ValentiaVerboseDebug
        }

    }

    process
    {
        "setup ScriptFile Reading" | Write-ValentiaVerboseDebug
        Set-ExecutionPolicy RemoteSigned -Force

        # Add Firewall Policy
        if ([System.Environment]::OSVersion.Version -ge (New-Object 'Version' 6.1.0.0))
        {
            "Enble WindowsPowerShell Remoting Firewall Rule" | Write-ValentiaVerboseDebug
            New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985

            "Set FireWall Status from Public to Private." | Write-ValentiaVerboseDebug
            Set-NetConnectionProfile -NetworkCategory Private
        }
        else
        {
            Write-Warning "Your computer detected  lowere than 'Windows 8' or 'Windows Server 2012'. Skip setting Firewall rule and Network location."
        }

        if (-not($SkipEnablePSRemoting))
        {
            "setup PSRemoting" | Write-ValentiaVerboseDebug
            Enable-PSRemoting -Force
        }

        "Add $TrustedHosts hosts to trustedhosts" | Write-ValentiaVerboseDebug
        Enable-WsManTrustedHosts -TrustedHosts $TrustedHosts

        "Configure WSMan MaxShellsPerUser to prevent error 'The WS-Management service cannot process the request. This user is allowed a maximum number of xx concurrent shells, which has been exceeded.'" | Write-ValentiaVerboseDebug
        # default 25 change to 100
        Set-ValentiaWsManMaxShellsPerUser -ShellsPerUser 100

        "Configure WSMan MaxMBPerUser to prevent huge memory consumption crach PowerShell issue." | Write-ValentiaVerboseDebug
        # default 1024 change to 0 means unlimited
        Set-ValentiaWsManMaxMemoryPerShellMB -MaxMemoryPerShellMB 0

        "Configure WSMan MaxProccessesPerShell to improve performance" | Write-ValentiaVerboseDebug
        # default 100 change to 0 means unlimited
        Set-ValentiaWsManMaxProccessesPerShell -MaxProccessesPerShell 0

        # Restart WinRM to change take effect
        Write-Verbose "Restart-Service WinRM -PassThru"
        Restart-Service WinRM -PassThru

        "Disable Enhanced Security for Internet Explorer" | Write-ValentiaVerboseDebug
        Disable-ValentiaEnhancedIESecutiry

        "Add valentia connection user" | Write-ValentiaVerboseDebug
        if ($NoOSUser)
        {
            "NoOSUser switch was enabled, skipping create OSUser." | Write-ValentiaVerboseDebug
        }
        else
        {
            New-ValentiaOSUser
        }

        "Create PowerShell ModulePath" | Write-ValentiaVerboseDebug
        $users = $valentia.users
        if ($users -is [System.Management.Automation.PSCustomObject])
        {
            $pname = $users | Get-Member -MemberType Properties | ForEach-Object{ $_.Name }

            foreach ($p in $pname)
            {
                $PSModulePath = "C:\Users\$($Users.$p)\Documents\WindowsPowerShell\Modules"
                if (-not(Test-Path $PSModulePath))
                {
                    "Create Module path" | Write-ValentiaVerboseDebug
                    New-Item -Path $PSModulePath -ItemType Directory -Force
                }
                else
                {
                    ("{0} already exist. Nothing had changed. `n" -f $PSModulePath) | Write-ValentiaVerboseDebug
                }
            }
        }

        if ($Server)
        {
            "Create Deploy Folder" | Write-ValentiaVerboseDebug
            New-ValentiaFolder
            
            if ($NoPassSave)
            {
                "NoPassSave switch was enabled, skipping Create/Revise secure password file." | Write-ValentiaVerboseDebug
            }
            else
            {
                "Create Deploy user credential .pass" | Write-ValentiaVerboseDebug
                Set-ValentiaCredential
            }
        }
        
        "Checking for HostName Status is follow rule and set if not correct." | Write-ValentiaVerboseDebug
        if ($NoSetHostName)
        {
            "NoSetHostName switch was enabled, skipping Set HostName." | Write-ValentiaVerboseDebug
        }
        else
        {
            Set-ValentiaHostName -HostUsage $HostUsage
        }
        
        "Checking for Reboot Status, if pending then prompt for reboot confirmation." | Write-ValentiaVerboseDebug
        if(Get-ValentiaRebootRequiredStatus)
        {
            if ($NoReboot)
            {
                'NoReboot switch was enabled, skipping reboot.' | Write-ValentiaVerboseDebug
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
