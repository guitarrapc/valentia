#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

function Show-ValentiaGroup
{

<#

.SYNOPSIS 
Show valentia deploygroup file (.ps1) list

.DESCRIPTION
This cmdlet will show files (extension = $valentia.deployextension = default is '.ps1') in [ValentiaBranchPath]::Deploygroup folder.

.NOTES
Author: guitarrapc
Created: 29/Oct/2013

.EXAMPLE
Show-ValentiaGroup
--------------------------------------------
show files in $valentia.Root\([ValentiaBranchPath]::Deploygroup) folder.
#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Input branch folder to show.")]
        [ValentiaBranchPath[]]
        $Branches = ([ValentiaBranchPath]::Deploygroup),

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Use if you want to search directory recursibly.")]
        [switch]
        $recurse
     )
 
    $DeployExtension = $valentia.deployextension
    
    foreach ($branch in $Branches)
    {
        if ($branch.Length -eq 0)
        {
            throw '"$Branch" was Null or Empty, input BranchName.'
        }
        else
        {
            ("Creating full path and resolving with '{0}' and '{1}'" -f $valentia.RootPath, ([ValentiaBranchPath]::$branch)) | Write-ValentiaVerboseDebug
            $BranchFolder = Join-Path $valentia.RootPath $branch -Resolve

            # show items
            $param = @{
                Path    = $BranchFolder
                Recurse = if($PSBoundParameters.recurse.IsPresent){$true}else{$false}
            }
            Get-ChildItem @param | where extension -eq $DeployExtension
        }
    }
}