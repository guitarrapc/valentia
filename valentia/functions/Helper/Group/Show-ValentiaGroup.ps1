#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

function Show-ValentiaGroup
{

<#

.SYNOPSIS 
Show valentia deploygroup file (.ps1) list

.DESCRIPTION
This cmdlet will show files (extension = $valentia.deployextension = default is '.ps1') in $valentia.Root\$valentia.BranchFolder.Deploygroup folder.

.NOTES
Author: guitarrapc
Created: 29/Oct/2013

.EXAMPLE
Show-ValentiaGroup
--------------------------------------------
show files in $valentia.Root\$valentia.BranchFolder.Deploygroup folder.

.EXAMPLE
Show-ValentiaGroup -Branch Application
--------------------------------------------
show files in $valentia.Root\$valentia.BranchFolder.Application folder.

.EXAMPLE
Show-ValentiaGroup -Branch Application -Recurse
--------------------------------------------
show files in $valentia.Root\$valentia.BranchFolder.Application folder recursibly.
#>

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0,
            HelpMessage = "Input branch folder to show.")]
        [string[]]
        $Branches = $valentia.BranchFolder.Deploygroup,

        [Parameter(
            Position = 1,
            Mandatory = 0,
            HelpMessage = "Use if you want to search directory recursibly.")]
        [switch]
        $recurse
     )
 
    ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension) | Write-ValentiaVerboseDebug
    $DeployExtension = $valentia.deployextension
    
    "Get Branch property name" | Write-ValentiaVerboseDebug
    $p = $valentia.BranchFolder | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    $valentiaBranchFolders = $p | %{ $valentia.BranchFolder.$_}

    ("processing branches is exist or not for '{0}'" -f $Branches) | Write-ValentiaVerboseDebug
    foreach ($branch in $Branches)
    {
        ("Checking '{0}' is include '{1}'" -f $branch, "$valentiaBranchFolders") | Write-ValentiaVerboseDebug
        if ($branch -in $valentiaBranchFolders)
        {
            ("Checking '{0}' length" -f $branch) | Write-ValentiaVerboseDebug
            if ($branch.Length -eq 0)
            {
                throw '"$Branch" was Null or Empty, input BranchName.'
            }
            else
            {
                ("Creating full path and resolving with '{0}' and '1'" -f $valentia.RootPath, $valentia.BranchFolder.$Branch) | Write-ValentiaVerboseDebug
                $BranchFolder = Join-Path $valentia.RootPath $valentia.BranchFolder.$Branch -Resolve

                # show items
                if ($PSBoundParameters.recurse.IsPresent)
                {
                    Get-ChildItem -Path $BranchFolder -Recurse | where extension -eq $DeployExtension
                }
                else
                {
                    Get-ChildItem -Path $BranchFolder | where extension -eq $DeployExtension
                }
            }
        }
        else
        {
            Write-Error ("Branch folder '{0}' not found from {1}" -f $branch, "$valentiaBranchFolders")
        }
    }
}