#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

# ipremark
function Invoke-valentiaDeployGroupRemark
{

<#
.SYNOPSIS 
Remark Deploy ip from deploygroup file

.DESCRIPTION
This cmdlet remark deploygroup ipaddresses from $valentia.root\$valentia.branch.deploygroup not to refer the ipaddress

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.10,10.0.0.11 -overWrite -Verbose
--------------------------------------------
replace 10.0.0.10 and 10.0.0.11 with #10.0.0.10 and #10.0.0.11 then replace file. (like sed -f "s/^10.0.0.10$/#10.0.0.10" -i)

Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.10,10.0.0.11 -Verbose
--------------------------------------------
replace 10.0.0.10 and 10.0.0.11 with #10.0.0.10 and #10.0.0.11 (like sed -f "s/^10.0.0.10$/#10.0.0.10")
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
        $remarkIPAddresses,

        [parameter(
            position = 1,
            mandatory = 0)]
        [switch]
        $overWrite,

        [parameter(
            position = 2,
            mandatory = 0)]
        [ValidateSet("Ascii", "BigEndianUnicode", "Byte", "Default","Oem", "String", "Unicode", "Unknown", "UTF32", "UTF7", "UTF8")]
        [string]
        $encoding = $valentia.fileEncode
    )

    Get-ChildItem -Path (Join-Path $valentia.RootPath $valentia.BranchFolder.Deploygroup) -Recurse `
        | where {!$_.PSISContainer } `
        | %{
            foreach ($remarkIPAddress in $remarkIPAddresses)
            {
                if ($overWrite)
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^$remarkIPAddress$" -replaceWith "#$remarkIPAddress" -encoding $encoding -overWrite -Verbose
                }
                else
                {
                    Invoke-ValentiaSed -path $_.FullName -searchPattern "^$remarkIPAddress$" -replaceWith "#$remarkIPAddress" -encoding $encoding -Verbose
                }
            }
        }
}
