#Requires -Version 3.0

#-- SymbolicLink Functions --#

<#
.SYNOPSIS 
This function will detect only SymbolicLink items.

.DESCRIPTION
PowerShell SymbolicLink function. Alternative to mklink Symbolic Link.
This function detect where input file fullpath item is file/directory SymbolicLink, then only Ennumerate if it is SymbolicLink.

.NOTES
Author: guitarrapc
Created: 12/Aug/2014

.EXAMPLE
ls d:\ | Get-ValentiaSymbolicLink
--------------------------------------------
Pipeline Input to detect SymbolicLink items.

.EXAMPLE
Get-ValentiaSymbolicLink (ls d:\).FullName
--------------------------------------------
Parameter Input to detect SymbolicLink items.
#>
function Get-ValentiaSymbolicLink
{
    [OutputType([System.IO.DirectoryInfo[]])]
    [cmdletBinding()]
    param
    (
        [parameter(mandatory = $true, Position  = 0, ValueFromPipeline =1, ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String[]]$Path
    )
    
    begin
    {
        $private:ErrorActionPreference = $valentia.preference.ErrorActionPreference.custom

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            Write-Verbose ('File attribute detected as ReparsePoint')
            $fileAttributes = [System.IO.FileAttributes]::Archive, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $attribute = [System.IO.File]::GetAttributes($Path)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
        }
    }

    process
    {
        try
        {
            $Path `
            | %{
                if ($file = IsFile -Path $_)
                {
                    if (IsFileReparsePoint -Path $file.FullName)
                    {
                        # [Valentia.SymbolicLinkGet]::GetSymbolicLinkTarget()
                        # [System.Type]::GetType($typeQualifiedName)::GetSymbolicLinkTarget()
                        $symTarget = [Valentia.CS.SymbolicLink]::GetSymbolicLinkTarget($file.FullName)
                        Add-Member -InputObject $file -MemberType NoteProperty -Name SymbolicPath -Value $symTarget -Force
                        return $file
                    }
                }
                elseif ($directory = IsDirectory -Path $_)
                {
                    if (IsDirectoryReparsePoint -Path $directory.FullName)
                    {
                        # [Valentia.SymbolicLinkGet]::GetSymbolicLinkTarget()
                        # [System.Type]::GetType($typeQualifiedName)::GetSymbolicLinkTarget()
                        $symTarget = [Valentia.CS.SymbolicLink]::GetSymbolicLinkTarget($directory.FullName)
                        Add-Member -InputObject $directory -MemberType NoteProperty -Name SymbolicPath -Value $symTarget -Force
                        return $directory
                    }
                }
            }
        }
        catch
        {
            throw $_
        }
    }    
}