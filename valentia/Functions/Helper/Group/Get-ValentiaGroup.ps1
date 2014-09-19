#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# target

<#
.SYNOPSIS 
Get ipaddress or NetBIOS from DeployGroup File specified

.DESCRIPTION
This cmdlet will read Deploy Group path and set them into array of Deploygroups.

.NOTES
Author: guitarrapc
Created: 18/Jul/2013

.EXAMPLE
target production-hoge.ps1
--------------------------------------------
read production-hoge.ps1 from deploy group branch path.

.EXAMPLE
target production-hoge.ps1 c:\test
--------------------------------------------
read production-hoge.ps1 from c:\test.
#>
function Get-ValentiaGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1, ValueFromPipeline = 1, ValueFromPipelineByPropertyName = 1, HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]$DeployGroups,

        [Parameter(Position = 1, Mandatory = 0, HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [ValidateNotNullOrEmpty()]
        [string]$DeployFolder = (Join-Path $Script:valentia.RootPath ([ValentiaBranchPath]::Deploygroup))
    )

    process
    {
        foreach ($DeployGroup in $DeployGroups)
        {
            # Get valentia.deployextension information
            ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension) | Write-ValentiaVerboseDebug
            $DeployExtension = $valentia.deployextension

            'Read DeployGroup and return $DeployMemebers' | Write-ValentiaVerboseDebug
            Read-ValentiaGroup -DeployGroup $DeployGroup
        }
    }

    begin
    {
        # Get valentiaGroup
        function Read-ValentiaGroup
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Position = 0, Mandatory)]
                [string]
                $DeployGroup
            )

            if ($DeployGroup.EndsWith($DeployExtension)) # if DeployGroup last letter = Extension is same as $DeployExtension
            {
                $DeployGroupPath = Join-Path $DeployFolder $DeployGroup -Resolve

                ("Read DeployGroupPath {0} where letter not contain # inline." -f $DeployGroupPath) | Write-ValentiaVerboseDebug
                return (Select-String -path $DeployGroupPath -Pattern ".*#.*" -notmatch -Encoding $valentia.fileEncode | Select-String -Pattern "\w" -Encoding $valentia.fileEncode).line
            }
            else
            {
                return $DeployGroup
            }
        }
    }
}