#Requires -Version 3.0

#-- Deploy Folder/File Module Functions --#

function Invoke-ValentiaSed
{

<#
.SYNOPSIS 
PowerShell Sed alternate function

.DESCRIPTION
This cmdlet replace string in the file as like as sed on linux

.NOTES
Author: guitarrapc
Created: 04/Oct/2013

.EXAMPLE
Invoke-ValentiaSed -path D:\Deploygroup\*.ps1 -searchPattern "^10.0.0.10$" -replaceWith "#10.0.0.10" -overwrite
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and replace file. (like sed -f "s/^10.0.0.10$/#10.0.0.10" -i)

.EXAMPLE
Invoke-ValentiaSed -path D:\Deploygroup\*.ps1 -searchPattern "^#10.0.0.10$" -replaceWith "10.0.0.10"
--------------------------------------------
replace regex ^10.0.0.10$ with # 10.0.0.10 and not replace file.
#>

    [CmdletBinding()]
    param
    (
        [parameter(
            position = 0,
            mandatory,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $path,

        [parameter(
            position = 1,
            mandatory,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $searchPattern,

        [parameter(
            position = 2,
            mandatory,
            ValueFromPipeline = 1,
            ValueFromPipelineByPropertyName = 1)]
        [string]
        $replaceWith,

        [parameter(
            position = 3,
            mandatory = 0)]
        [ValidateSet("Ascii", "BigEndianUnicode", "Byte", "Default","Oem", "String", "Unicode", "Unknown", "UTF32", "UTF7", "UTF8")]
        [string]
        $encoding = $valentia.fileEncode,

        [parameter(
            position = 4,
            mandatory = 0)]
        [switch]
        $overWrite
    )

    $read = Select-String -Path $path -Pattern $searchPattern -Encoding $encoding

    $read.path `
        | sort -Unique `
        | %{
            Write-Warning ("Executing string replace for {0}" -f $path)
                
            Write-Verbose "Get file information"
            $path = $_
            $extention = [System.IO.Path]::GetExtension($path)

            Write-Verbose "define tmp file"
            $tmpextension = "$extention" + "______"
            $tmppath = [System.IO.Path]::ChangeExtension($path,$tmpextension)
                               
            if ($overWrite)
            {
                Write-Verbose ("execute replace string {0} with {1} for file {2} and output to {3}" -f $searchPattern, $replaceWith, $path, $tmppath)
                Get-Content -Path $path `
                    | %{$_ -replace $searchPattern,$replaceWith} `
                    | Out-File -FilePath $tmppath -Encoding $valentia.fileEncode -Force -Append

                Write-Verbose ("remove original file {0}" -f $path, $tmppath)
                Remove-Item -Path $path -Force

                Write-Verbose ("rename tmp file {0} to original file {1}" -f $tmppath, $path)
                Rename-Item -Path $tmppath -NewName ([System.IO.Path]::ChangeExtension($tmppath,$extention))
            }
            else
            {
                Write-Verbose ("execute replace string {0} with {1} for file {2}" -f $searchPattern, $replaceWith, $path)
                Get-Content -Path $path -Encoding $encoding `
                    | %{$_ -replace $searchPattern,$replaceWith}
            }    
        }
}