#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# target
function Get-ValentiaGroup
{

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

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]
        $DeployGroups,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup)
    )


    # Get valentiaGroup
    function Read-ValentiaGroup
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Position = 0,Mandatory)]
            [string]
            $DeployGroup
        )

        if ($DeployGroup.EndsWith($DeployExtension)) # if DeployGroup last letter = Extension is same as $DeployExtension
        {
            ("Creating Deploy Path with DeployFolder [{0}] and DeployGroup [{1}] ." -f $DeployFolder, $DeployGroup) | Write-ValentiaVerboseDebug
            $DeployGroupPath = Join-Path $DeployFolder $DeployGroup

            ("Check DeployGroupPath {0}" -f $DeployGroupPath) | Write-ValentiaVerboseDebug
            if(Test-Path $DeployGroupPath)
            {
                # Obtain IP only by selecting leter start from decimal
                ("Read DeployGroupPath {0} where letter not contain # inline." -f $DeployGroupPath) | Write-ValentiaVerboseDebug
                return (Select-String -path $DeployGroupPath -Pattern ".*#.*" -notmatch -Encoding $valentia.fileEncode | Select-String -Pattern "\w" -Encoding $valentia.fileEncode).line
            }
            else
            {
                $errorDetail = [PSCustomObject]@{
                    ErrorMessageDetail = ("DeployGroup '{0}' not found in DeployFolder path '{1}'." -f $DeployGroup, $DeployFolder)
                    SuccessStatus = $false
                }

                throw $errorDetail.ErrorMessageDetail
            }
        }
        else
        {
            if (-not [string]::IsNullOrWhiteSpace($DeployGroup))
            {
                return $DeployGroup
            }
            else
            {
                throw ("DeployGroup '{0}' was white space. Cancel execution." -f $DeployGroup)
            }
        }
    }
    

    # Get valentia.deployextension information
    ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension) | Write-ValentiaVerboseDebug
    $DeployExtension = $valentia.deployextension

    switch ($DeployGroups.Length)
    {
        0 { throw '"$DeployGroups" was Null or Empty, input DeployGroup.'}
        1 { Write-Verbose ("DeployGroups length was 1" -f $DeployGroups.Length)
            # Parse DeplotGroup from [string[]] to [String]
            [string]$DeployGroup = $DeployGroups

            'Read DeployGroup and return $DeployMemebers' | Write-ValentiaVerboseDebug
            return Read-ValentiaGroup -DeployGroup $DeployGroup
        }
        # more than 2
        default {("DeployGroups length default" -f $DeployGroups.Length) | Write-ValentiaVerboseDebug
            foreach ($DeployGroup in $DeployGroups)
            {
                'Read DeployGroup and return $DeployMemebers' | Write-ValentiaVerboseDebug
                Read-ValentiaGroup -DeployGroup $DeployGroup
            }
        }
    }
}