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
        [Parameter(Position  = 0, mandatory = $true, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Specify IpAddress or NetBIOS name for deploy target clients.")]
        [string[]]$DeployClients,

        [Parameter(Position = 1, mandatory = $true, HelpMessage = "Input filename to output DeployClients")]
        [string]$FileName,

        [Parameter(Position = 2, mandatory = $false, HelpMessage = "Specify folder path to deploy group. defailt is Deploygroup branchpath")]
        [string]$DeployGroupsFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup)),

        [Parameter(Position = 3, mandatory = $false, HelpMessage = "If you want to add item to exist file.")]
        [switch]$Add,

        [Parameter(Position = 4, mandatory = $false, HelpMessage = "If you want to popup confirm message when file created.")]
        [switch]$Confirm,

        [Parameter(Position = 5, mandatory = $false, HelpMessage = "If you want to Show file information when operation executed.")]
        [switch]$PassThru
    )

    process
    {
        if($PSBoundParameters.ContainsKey('Add'))
        {
            $DeployClients | Add-Content @param
        }
        else
        {
            $DeployClients | Set-Content @param
        }
    }

    begin
    {
        $ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom
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
            Force    = $true
            Confirm  = $PSBoundParameters.ContainsKey('Confirm')
            PassThru = $PSBoundParameters.ContainsKey('PassThru')
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

