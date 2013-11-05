#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# ipunremark
function Invoke-valentiaDeployGroupUnremark
{

<#

.SYNOPSIS 
Unremark Deploy ip from deploygroup file

.DESCRIPTION
This cmdlet unremark deploygroup ipaddresses from $valentia.root\$valentia.branch.deploygroup to refer the ipaddress.

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -overWrite -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 then replace file (like sed -f "s/^#10.0.0.10$/10.0.0.10" -i)

Invoke-valentiaDeployGroupUnremark -unremarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose
--------------------------------------------
replace #10.0.0.10 and #10.0.0.11 with 10.0.0.10 and 10.0.0.11 (like sed -f "s/^#10.0.0.10$/10.0.0.10")

#>

    [CmdletBinding()]
    param
    (
        [parameter(
            position = 0,
            mandatory = 1,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string[]]
        $unremarkIPAddresses,

        [parameter(
            position = 1,
            mandatory = 0)]
        [switch]
        $overWrite
    )

    Get-ChildItem -Path (Join-Path $valentia.RootPath $valentia.BranchFolder.Deploygroup) -Recurse `
        | where {!$_.PSISContainer } `
        | %{
            foreach ($unremarkIPAddress in $unremarkIPAddresses)
            {
                if ($overWrite)
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -overWrite -Verbose
                }
                else
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^#$unremarkIPAddress$" -replaceWith "$unremarkIPAddress" -Verbose
                }
            }
        }
}
