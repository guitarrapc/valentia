#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

<#
.SYNOPSIS 
Create new DeployGroup File written "target PC IP/hostname" for PS-RemoteSession

.DESCRIPTION
This cmdlet will create valentis deploy group file to specify deploy targets.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
New-valentiaGroup -DeployClients "10.0.4.100","10.0.4.101" -FileName new.ps1
--------------------------------------------
write 10.0.4.100 and 10.0.4.101 to create deploy group file as "new.ps1".
#>
function New-ValentiaGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Specify IpAddress or NetBIOS name for deploy target clients.")]
        [string[]]
        $DeployClients,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Input filename to output DeployClients")]
        [string]
        $FileName,

        [Parameter(
            Position = 2,
            Mandatory = 0,
            HelpMessage = "Specify folder path to deploy group. defailt is Deploygroup branchpath")]
        [string]
        $DeployGroupsFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(
            Position = 3,
            Mandatory = 0,
            HelpMessage = "If you want to write into ReadOnly file.")]
        [switch]
        $Force,

        [Parameter(
            Position = 4,
            Mandatory = 0,
            HelpMessage = "If you want to popup confirm message when file created.")]
        [switch]
        $Confirm,

        [Parameter(
            Position = 5,
            Mandatory = 0,
            HelpMessage = "If you want to confiem what will happen.")]
        [switch]
        $WhatIf

    )

    begin
    {
        $ErrorActionPreference = $valentia.errorPreference
        Set-StrictMode -Version latest

        # check FileName is null or empty
        try
        {
            if ([string]::IsNullOrEmpty($FileName))
            {
                throw '"$FileName" was Null or Enpty, input DeployGroup FileName.'
            }
            else
            {
                $DeployPath = Join-Path $DeployGroupsFolder $FileName
            }
        }
        catch
        {
            throw $_
        }

        # set splatting
        $param = @{
            path     = $DeployPath
            Encoding = $valentia.fileEncode
        }

        function Get-Force
        {
            if($WhatIf)
            {
                $DeployClients | Add-Content @param -WhatIf -Force
            }
            else
            {
                $DeployClients | Add-Content @param -Force -PassThru
            }
        }

        function Get-WhatifConfirm
        {
            if($WhatIf)
            {
                $DeployClients | Add-Content @param -Whatif -Confirm
            }
            else
            {
                $DeployClients | Add-Content @param -Confirm -PassThru
            }
        }

        function Get-Whatif
        {
            if($WhatIf)
            {
                $DeployClients | Add-Content @param -Whatif
            }
            else
            {
                $DeployClients | Add-Content @param -PassThru
            }
        }
    }

    process
    {
        if ($force)
        {
            Get-Force
        }
        if ($Confirm)
        {
            Get-WhatifConfirm
        }
        else
        {
            Get-Whatif
        }

    }

    end
    {
        if (Test-Path $DeployPath)
        {
            Get-ChildItem -Path $DeployPath
        }
        else
        {
            Write-Error ("{0} not existing." -f $DeployPath)
        }

        # Cleanup valentia Environment
        Invoke-ValentiaClean
    }
}

