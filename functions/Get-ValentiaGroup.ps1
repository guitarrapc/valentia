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
            Mandatory,
            HelpMessage = "Input target of deploy clients as [DeployGroup filename you sat at deploygroup Folder] or [ipaddress].")]
        [string[]]
        $DeployGroups,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Input DeployGroup Folder path if changed from default.")]
        [string]
        $DeployFolder = (Join-Path $Script:valentia.RootPath $Script:valentia.BranchFolder.DeployGroup)
    )


    # Get valentiaGroup
    function Resolve-ValentiaGroup{

        param(
            [Parameter(Position = 0,Mandatory)]
            [string]
            $DeployGroup
        )

        if ($DeployGroup.EndsWith($DeployExtension)) # if DeployGroup last letter is same as $DeployExtension
        {
            $DeployFile = $DeployGroup

            Write-Verbose ("Creating Deploy Path with DeployFolder [{0}] and DeployGroup [{1}] ." -f $DeployFolder, $DeployFile)
            $DeployGroupPath = Join-Path $DeployFolder $DeployFile

            Write-Verbose ("Check DeployGroupPath {0}" -f $DeployGroupPath)
            if(Test-Path $DeployGroupPath)
            {
                # Obtain IP only by selecting leter start from decimal
                Write-Verbose ("Read DeployGroupPath {0} where letter not contain # inline." -f $DeployGroupPath)
                Write-Verbose 'code : Select-String -path $DeployGroupPath -Pattern "".*#.*"" -notmatch -Encoding $valentia.fileEncode | Select-String -Pattern ""\w"" -Encoding utf8 | select -ExpandProperty line'
                $Readlines = Select-String -path $DeployGroupPath -Pattern ".*#.*" -notmatch -Encoding $valentia.fileEncode | Select-String -Pattern "\w" -Encoding $valentia.fileEncode | select -ExpandProperty line
                return $Readlines
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
        elseif (Test-Connection -ComputerName $DeployGroup -Count 1 -Quiet) # if deploygroup not have extension $valentia.deployextension, try test-connection
        {
            return $DeployGroup
        }
        else
        {
            if ([string]::IsNullOrWhiteSpace($DeployGroups))
            {
                throw ("DeployGroups '{0}' was white space. Cancel execution." -f $DeployGroups)
            }
            else
            {
                throw ("Could not resolve connection with DeployGroups '{0}'. Cancel execution." -f $DeployGroups)
            }
        }
    }
    

    # Initialize DeployMembers variable
    $DeployMembers = @()


    # Get valentia.deployextension information
    Write-Verbose ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension)
    $DeployExtension = $valentia.deployextension
    $extensionlength = $DeployExtension.length


    switch ($DeployGroups.Length)
    {
        0 {throw '"$DeployGroups" was Null or Empty, input DeployGroup.'}
        1 {
            # Parse DeplotGroup from [string[]] to [String]
            [string]$DeployGroup = $DeployGroups

            # Resolve DeployGroup is filename or IPAddress/Hostname and return $DeployMemebers
            $Deploymembers += Resolve-ValentiaGroup -DeployGroup $DeployGroup}

        # more than 2
        default {
            foreach ($DeployGroup in $DeployGroups)
            {
                # Parse DeplotGroup from [string[]] to [String]
                [string]$DeployGroup = $DeployGroup

                # Resolve DeployGroup is filename or IPAddress/Hostname and return $DeployMemebers
                $Deploymembers += Resolve-ValentiaGroup -DeployGroup $DeployGroup
            }
        }
    }

    return $DeployMembers
}
