#Requires -Version 3.0

#-- Running prerequisite Initialize OS Setting Module Functions --#

# Initial

<#
.SYNOPSIS 
Initializing valentia PSRemoting environment for Deploy Server and client.

.DESCRIPTION
Make sure to Run as Admin Priviledge. 
This function will execute followings.

1. Set-ExecutionPolicy (Default : RemoteSigned)
2. Add PowerShell Remoting Inbound rule to Firewall
3. Network Connection Profile Setup
4. Enable-PSRemoting
5. Add hosts to trustedHosts
6. Enable CredSSP for trustedHosts
7. Set WSMan MaxShellsPerUser from 25 to 100
8. Set WSMan MaxMBPerUser unlimited.
9. Set WSMan MaxProccessesPerShell unlimited.
10. Restart Service WinRM
11. Disable Enhanced Security for Internet Explorer
12. Create OS user for Deploy connection.
13. Server Only : Create Deploy Folders
14. Server Only : Create/Revise Deploy user credential secure file.
15. Set HostName for the windows.
16. Get Status for Reboot Status and decide.

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
function Initialize-ValentiaEnvironment
{
    [CmdletBinding(DefaultParameterSetName = "Server")]
    param
    (
        [parameter(ParameterSetName = "Server")]
        [parameter(HelpMessage = "Select this switch to Initialize setup for Deploy Server.")]
        [switch]
        $Server,

        [parameter(ParameterSetName = "Client")]
        [parameter(HelpMessage = "Select this switch to Initialize setup for Deploy Client.")]
        [switch]
        $Client,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(HelpMessage = "Select this switch If you don't want to initialize Deploy User.")]
        [switch]
        $NoOSUser = $false,

        [parameter(ParameterSetName = "Server")]
        [parameter(HelpMessage = "Select this switch If you don't want to Save/Revise password.")]
        [switch]
        $NoPassSave = $false,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(ParameterSetName = "HostName")]
        [Parameter(HelpMessage = "Select this switch If you don't want to Set HostName.")]
        [switch]
        $NoSetHostName = $true,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(ParameterSetName = "HostName")]
        [Parameter(HelpMessage = "set usage for the host.")]
        [string]
        $HostUsage,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(ParameterSetName = "HostName")]
        [parameter(HelpMessage = "Select this switch If you don't want to REboot.")]
        [switch]
        $NoReboot = $true,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(ParameterSetName = "HostName")]
        [parameter(HelpMessage = "Select this switch If you want to Forece Restart without prompt.")]
        [switch]
        $ForceReboot = $false,

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(HelpMessage = "Input Trusted Hosts you want to enable. Default : ""*"" ")]
        [string]
        $TrustedHosts = "*",

        [parameter(ParameterSetName = "Server")]
        [parameter(ParameterSetName = "Client")]
        [parameter(HelpMessage = "Select this switch If you want to skip setup PSRemoting.")]
        [switch]
        $SkipEnablePSRemoting = $false
    )

    process
    {
        if ($PSBoundParameters.Verbose.IsPresent)
        {
            [ordered]@{
                Server               = $Server
                Client               = $Client
                NoOSUser             = $NoOSUser
                NoPassSave           = $NoPassSave
                NoSetHostName        = $NoSetHostName
                HostUsage            = $HostUsage
                NoReboot             = $NoReboot
                ForceReboot          = $ForceReboot
                TrustedHosts         = $TrustedHosts
                SkipEnablePSRemoting = $SkipEnablePSRemoting
            }
        }

        ExecutionPolicy
        FirewallNetWorkProfile
        PSRemotingCredSSP -SkipEnablePSRemoting $SkipEnablePSRemoting -TrustedHosts $TrustedHosts
        WSManConfiguration
        IESettings
        $credential = CredentialCheck -NoOSUser $NoOSUser -NoPassSave $NoPassSave
        OSUserSetup -NoOSUser $NoOSUser -credential $credential
        ServerSetup -server $Server -credential $credential
        HostnameSetup -NoSetHostName $NoSetHostName -HostUsage $HostUsage
        RebootCheck -NoReboot $NoReboot -ForceReboot $ForceReboot
    }
    
    end
    {
        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference

        if(-not(Test-ValentiaPowerShellElevated))
        {
            throw "Your PowerShell Console is not elevated! Must start PowerShell as an elevated to run this function because of UAC."
        }
        else
        {
            "Current session is already elevated, continue setup environment." | Write-ValentiaVerboseDebug
        }

        if ($NoSetHostName -eq $false)
        {
            if ([string]::IsNullOrEmpty($HostUsage))
            {
                throw "HostUsage parameter was null or empty. Set HostUsage is required to Set HostName."
            }
        }

        function ExecutionPolicy
        {
            Write-Host "Configuring ExecutionPolicy." -ForegroundColor Cyan
            "Set ExecutionPolicy to '{0}' only if execution policy is restricted." -f $valentia.ExecutionPolicy | Write-ValentiaVerboseDebug
            $executionPolicy = Get-ExecutionPolicy
            if ($executionPolicy -eq "Restricted")
            {
                Set-ExecutionPolicy $valentia.ExecutionPolicy -Force
            }
        }

        function FirewallNetWorkProfile
        {
            Write-Host "Configuring Firewall to accept PowerShell Remoting." -ForegroundColor Cyan
            if ([System.Environment]::OSVersion.Version -ge (New-Object 'Version' 6.1.0.0))
            {
                "Enable WindowsPowerShell Remoting Firewall Rule." | Write-ValentiaVerboseDebug
                New-ValentiaPSRemotingFirewallRule -PSRemotePort 5985

                "Set FireWall Status from Public to Private." | Write-ValentiaVerboseDebug
                if ((Get-NetConnectionProfile).NetworkCategory -ne "DomainAuthenticated")
                {
                    Set-NetConnectionProfile -NetworkCategory Private
                }
            }
            else
            {
                Write-Warning ("Your OS Version detected as '{0}', which is lower than 'Windows 8' or 'Windows Server 2012'. Skip setting Firewall rule and Network location." -f [System.Environment]::OSVersion.Version)
            }
        }

        function PSRemotingCredSSP ($SkipEnablePSRemoting, $TrustedHosts)
        {
            Write-Host "Enabling PSRemoting and CredSSP" -ForegroundColor Cyan
            if (-not($SkipEnablePSRemoting))
            {
                "Setup PSRemoting" | Write-ValentiaVerboseDebug
                Enable-PSRemoting -Force

                "Add $TrustedHosts hosts to trustedhosts" | Write-ValentiaVerboseDebug
                Enable-ValentiaWsManTrustedHosts -TrustedHosts $TrustedHosts

                "Enable CredSSP for $TrustedHosts" | Write-ValentiaVerboseDebug
                Enable-ValentiaWsManCredSSP -TrustedHosts $TrustedHosts
                
                Get-WSManCredSSP
            }
        
        }

        function WSManConfiguration
        {
            Write-Host "Configure WSMan parameter." -ForegroundColor Cyan
            Set-ValetntiaWSManConfiguration
        }

        function IESettings
        {
            Write-Host "Disable Enganced Security for Ineternet Explorer." -ForegroundColor Cyan
            "Disable Enhanced Security for Internet Explorer" | Write-ValentiaVerboseDebug
            Disable-ValentiaEnhancedIESecutiry
        }

        function CredentialCheck ($NoOSUser, $NoPassSave)
        {
            if ((-not $NoOSUser) -or (-not $NoPassSave))
            {
                Write-Host "Obtain PSCredential to set Credential information." -ForegroundColor Cyan
                return (Get-Credential -Credential $valentia.users.deployUser)
            }
        }

        function OSUserSetup ($NoOSUser, $credential)
        {
            Write-Host "Adding Deploy User." -ForegroundColor Cyan
            if ($NoOSUser)
            {
                "NoOSUser switch was enabled, skipping create OSUser." | Write-ValentiaVerboseDebug
            }
            else
            {
                "Add valentia connection user" | Write-ValentiaVerboseDebug
                New-ValentiaOSUser -Credential $credential
            }
        }

        function ServerSetup ($server, $credential)
        {
            if ($Server)
            {
                "Add valentia DeployFolder." | Write-ValentiaVerboseDebug
                "Create Deploy Folder" | Write-ValentiaVerboseDebug
                New-ValentiaFolder
            
                "Set Valentia credential in Windows Credential Manager." | Write-ValentiaVerboseDebug
                if ($NoPassSave)
                {
                    "NoPassSave switch was enabled, skipping Create/Revise secure password file." | Write-ValentiaVerboseDebug
                }
                else
                {
                    "Create Deploy user credential .pass" | Write-ValentiaVerboseDebug
                    Set-ValentiaCredential -Credential $credential
                }
            }
        }

        function HostnameSetup ($NoSetHostName, $HostUsage)
        {
            "Check HostName configuration." | Write-ValentiaVerboseDebug
            if ($NoSetHostName)
            {
                "NoSetHostName switch was enabled, skipping Set HostName." | Write-ValentiaVerboseDebug
            }
            else
            {
                "Update HostName." | Write-ValentiaVerboseDebug
                Set-ValentiaHostName -HostUsage $HostUsage
            }
        }

        function RebootCheck ($NoReboot, $ForceReboot)
        {
            "Check Reboot status." | Write-ValentiaVerboseDebug
            if(Get-ValentiaRebootRequiredStatus)
            {
                if ($NoReboot)
                {
                    'NoReboot switch was enabled, skipping reboot.' | Write-ValentiaVerboseDebug
                }
                elseif ($ForceReboot)
                {
                    "Start Restart Force." | Write-ValentiaVerboseDebug
                    Restart-Computer -Force
                }
                else
                {
                    "Start Restart with confirmation." | Write-ValentiaVerboseDebug
                    Restart-Computer -Force -Confirm
                }
            }
        }
    }
}
