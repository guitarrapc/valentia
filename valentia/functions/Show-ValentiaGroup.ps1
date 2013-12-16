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
 
    Write-Debug "Get valentia.deployextension information"
    Write-Verbose ('Set DeployGroupFile Extension as "$valentia.deployextension" : {0}' -f $valentia.deployextension)
    $DeployExtension = $valentia.deployextension
    
    Write-Debug "Get Branch property name"
    $p = $valentia.BranchFolder | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
    $valentiaBranchFolders = $p | %{ $valentia.BranchFolder.$_}

    Write-Debug ("processing branches is exist or not for '{0}'" -f $Branches)
    foreach ($branch in $Branches)
    {
        Write-Debug ("Checking '{0}' is include '{1}'" -f $branch, "$valentiaBranchFolders")
        if ($branch -in $valentiaBranchFolders)
        {
            Write-Debug ("Checking '{0}' length" -f $branch)
            if ($branch.Length -eq 0)
            {
                throw '"$Branch" was Null or Empty, input BranchName.'
            }
            else
            {
                Write-Debug ("Creating full path and resolving with '{0}' and '1'" -f $valentia.RootPath, $valentia.BranchFolder.$Branch)
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