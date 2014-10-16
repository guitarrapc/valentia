#Requires -Version 2.0

# Windows 7 and later is requires.
function Main
{
    [CmdletBinding()]
    Param
    (
        [string]$Modulepath = ($env:PSModulePath -split ";" | where {$_ -like ("{0}*" -f [environment]::GetFolderPath("MyDocuments"))}),

        [switch]$Force = $false,

        [switch]$Whatif = $false
    )

    end
    {
        # Test Module is same or not
        if (Test-ModuleVersion -Modulename $moduleName -modulePath $moduleFullPath -NugetModulePath $path){ return }
        
        # Remove Current Module
        if (Test-Path $moduleFullPath)
        {
            Write-Warning ("'{0}' already exist. Removing current module." -f $moduleFullPath)
            Remove-Item -Path $moduleFullPath -Recurse -Force
        }

        try
        {
            # Copy Module
            Write-Host ("Copying module '{0}' to Module path '{1}'." -f $moduleName, $moduleFullPath) -ForegroundColor Cyan
            Copy-ItemEX -path $path -destination $moduleFullPath -Targets * -Recurse -Force 

            # Import Module
            Write-Host ("Importing Module '{0}'" -f $moduleName) -ForegroundColor cyan
            Import-ModuleEX -ModuleName $moduleName

            # GetModuleVariable
            $moduleVariable = (Get-Variable -Name $moduleName).Value
            
            # Set configuration File
            $originalConfigPath = Join-Path $moduleVariable.originalconfig.root $moduleVariable.originalconfig.file -Resolve
            Set-DefaultConfig -defaultConfigPath $originalConfigPath -ExportConfigDir $moduleVariable.appdataconfig.root -ExportConfigFile $moduleVariable.appdataconfig.file -force:$force
            Move-OriginalDefaultConfig -defaultConfigPath $originalConfigPath -ExportConfigDir $moduleVariable.appdataconfig.backup
        }
        catch
        {
            throw $_
        }
    }

    begin
    {
        $ErrorActionPreference = "Stop"

        # For Nuget
        $parent = [System.IO.Directory]::GetParent((Split-Path (Resolve-Path -Path $PSCommandPath) -Parent))
        $child  = $parent.name.split(".")[0]
        $path = Join-Path $parent $child

        # Original
        # $path = [System.IO.Directory]::GetParent((Split-Path (Resolve-Path -Path $PSCommandPath) -Parent))
        
        $moduleName = Get-ModuleName -path $path
        $moduleFullPath = Join-Path $modulepath $moduleName

        Write-Verbose ("Checking Module Root Path '{0}' is exist not not." -f $modulepath)
        if(-not(Test-ModulePath -modulepath $modulepath))
        {
            Write-Warning "$modulepath not found. creating module path."
            New-Item -Path $modulepath -ItemType directory -Force > $null
        }
    }
}

Function Test-ModulePath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1)]
        [string]$modulepath        
    )
 
    Write-Verbose "Checking Module Home."
    if (([System.Environment]::OSVersion.Version) -ge 6.1)
    {
        Write-Verbose "Your operating system is later then Windows 7 / Windows Server 2008 R2. Continue evaluation."
        return Test-Path -Path $modulepath
    }
    else
    {
        throw "Operation System not higher enough exception!! Make sure you are runnning Windows 7 / Windows Server 2008 R2 or Higher."
    }
}

Function Get-ModuleName
{

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = 1)]
        [string]$path
    )

    if (Test-Path $path)
    {
        $moduleName = ((Get-ChildItem $path | where {$_.Extension -eq ".psm1"})).BaseName
        if ($null -eq $moduleName)
        {
            throw "Module file .psm1 not existing in path '{0}' exception!!" -f $path
        }
        return $moduleName
    }
    else
    {
        throw "Path '{0}' not existing exception!!" -f $path
    }
}


function Copy-ItemEX
{
    param
    (
        [parameter(Mandatory = 1, Position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName =1)]
        [alias('PSParentPath')]
        [string]$Path,

        [parameter(Mandatory = 1, Position  = 1, ValueFromPipelineByPropertyName =1)]
        [string]$Destination,

        [parameter(Mandatory = 0, Position  = 2, ValueFromPipelineByPropertyName =1)]
        [string[]]$Targets,

        [parameter(Mandatory = 0, Position  = 3, ValueFromPipelineByPropertyName =1)]
        [string[]]$Excludes,

        [parameter(Mandatory = 0, Position  = 4, ValueFromPipelineByPropertyName =1)]
        [Switch]$Recurse,

        [parameter(Mandatory = 0, Position  = 5)]
        [switch]$Force,

        [parameter(Mandatory = 0, Position  = 6)]
        [switch]$WhatIf
    )

    process
    {
        # Test Path
        if (-not (Test-Path $Path)){throw 'Path not found Exception!!'}

        # Get Filter Item Path as List<Tuple<string>,<string>,<string>>
        $filterPath = GetTargetsFiles -Path $Path -Targets $Targets -Recurse:$isRecurse -Force:$Force

        # Remove Exclude Item from Filter Item
        $excludePath = GetExcludeFiles -Path $filterPath -Excludes $Excludes

        # Execute Copy, confirmation and WhatIf can be use.
        CopyItemEX  -Path $excludePath -RootPath $Path -Destination $Destination -Force:$isForce -WhatIf:$isWhatIf
    }

    begin
    {
        $isRecurse = $PSBoundParameters.ContainsKey('Recurse')
        $isForce = $PSBoundParameters.ContainsKey('Force')
        $isWhatIf = $PSBoundParameters.ContainsKey('WhatIf')

        function GetTargetsFiles
        {
            [CmdletBinding()]
            param
            (
                [string]$Path,

                [string[]]$Targets,

                [bool]$Recurse,

                [bool]$Force
            )

            # fullName, DirectoryName, Name
            $list = New-Object 'System.Collections.Generic.List[Tuple[string,string,string]]'
            $base = Get-ChildItem $Path -Recurse:$Recurse -Force:$Force

            if (($Targets | measure).count -ne 0)
            {
                foreach($target in $Targets)
                {
                    $base `
                    | where Name -like $target `
                    | %{
                        if ($_ -is [System.IO.FileInfo])
                        {
                            $tuple = New-Object 'System.Tuple[[string], [string], [string]]' ($_.FullName, $_.DirectoryName, $_.Name)
                        }
                        elseif ($_ -is [System.IO.DirectoryInfo])
                        {
                            $tuple = New-Object 'System.Tuple[[string], [string], [string]]' ($_.FullName, $_.PSParentPath, $_.Name)
                        }
                        else
                        {
                            throw "Type '{0}' not imprement Exception!!" -f $_.GetType().FullName
                        }
                        $list.Add($tuple)
                    }
                }
            }
            else
            {
                $base `
                | %{
                    if ($_ -is [System.IO.FileInfo])
                    {
                        $tuple = New-Object 'System.Tuple[[string], [string], [string]]' ($_.FullName, $_.DirectoryName, $_.Name)
                    }
                    elseif ($_ -is [System.IO.DirectoryInfo])
                    {
                        $tuple = New-Object 'System.Tuple[[string], [string], [string]]' ($_.FullName, $_.PSParentPath, $_.Name)
                    }
                    else
                    {
                        throw "Type '{0}' not imprement Exception!!" -f $_.GetType().FullName
                    }
                    $list.Add($tuple)
                }
            }
            
            return $list
        }

        function GetExcludeFiles
        {
            param
            (
                [System.Collections.Generic.List[Tuple[string,string,string]]]$Path,

                [string[]]$Excludes
            )

            if (($Excludes | measure).count -ne 0)
            {
                Foreach ($exclude in $Excludes)
                {
                    # name not like $exclude
                    $Path | where Item3 -notlike $exclude
                }
            }
            else
            {
                $Path
            }

        }

        function CopyItemEX
        {
            [cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
            param
            (
                [System.Collections.Generic.List[Tuple[string,string,string]]]$Path,

                [string]$RootPath,

                [string]$Destination,

                [bool]$Force
            )

            begin
            {
                # remove default bound "Force"
                $PSBoundParameters.Remove('Force') > $null
            }

            process
            {
                # convert to regex format
                $root = $RootPath.Replace('Microsoft.PowerShell.Core\FileSystem::','').Replace('\', '\\')

                $Path `
                | %{
                    # create destination DirectoryName
                    $directoryName = Join-Path $Destination ($_.Item2 -split $root | select -Last 1)
                    [PSCustomObject]@{
                        Path = $_.Item1
                        DirectoryName = $directoryName
                        Destination = Join-Path $directoryName $_.Item3
                    }} `
                | where {$Force -or $PSCmdlet.ShouldProcess($_.Path, ('Copy Item to {0}' -f $_.Destination))} `
                | %{
                    Write-Verbose ("Copying '{0}' to '{1}'." -f $_.Path, $_.Destination)
                    New-Item -Path $_.DirectoryName -ItemType Directory -Force > $null
                    Copy-Item -Path $_.Path -Destination $_.Destination -Force
                }
            }
        }
    }
}

Function Import-ModuleEX
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position = 0)]
        [string]$ModuleName
    )

    if(Get-Module -ListAvailable | where Name -eq $moduleName)
    {
        Import-Module (Join-Path (Join-Path $modulepath $moduleName) ("{0}.psd1" -f $moduleName)) -PassThru -Force
    }
}

function Test-ModuleVersion ([string]$Modulename, [string]$modulePath, [string]$NugetModulePath)
{
    $modulePSD1 = Join-Path $modulePath "$Modulename.psd1"
    $nugetPSD1 = Join-Path $NugetModulePath "$Modulename.psd1"

    Write-Host "Checking current Module : $modulePSD1" -ForegroundColor Green
    if (-not (Test-Path $modulePSD1)){ return $false }

    Write-Host "Checking Nuget Module : $nugetPSD1" -ForegroundColor Green
    if (-not (Test-Path $nugetPSD1)){ return $false }

    $currentModule = Test-ModuleManifest -Path $modulePSD1
    $newModule = Test-ModuleManifest -Path $nugetPSD1

    Write-Host ("Current Module Version : {0}, NuGet Module Version : {1}" -f $currentModule.Version, $newModule.Version) -ForegroundColor Green
    return $currentModule.Version -eq $newModule.Version
}

Function Set-DefaultConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position = 0)]
        [validateScript({Test-Path $_})]
        [string]$defaultConfigPath,

        [parameter(mandatory = 1, position = 1)]
        [string]$ExportConfigDir,

        [parameter(mandatory = 1, position = 2)]
        [string]$ExportConfigFile,

        [switch]$force
    )

    if(Test-Path $defaultConfigPath)
    {
        if (-not (Test-Path $ExportConfigDir))
        {
            New-Item -Path $ExportConfigDir -ItemType Directory -Force > $null
        }
        
        $configPath = Join-Path $ExportConfigDir $ExportConfigFile
                
        if (-not(Test-Path $configPath))
        {
            Write-Host ("Default configuration file created in '{0}'" -f $configPath) -ForegroundColor Green
            Get-Content $defaultConfigPath -Raw | Out-File -FilePath $configPath -Encoding $moduleVariable.fileEncode -Force
        }
        elseif ($force)
        {
            Write-Host ("Default configuration file overwrite in '{0}'" -f $configPath) -ForegroundColor Green
            Rename-Item -Path $configPath -NewName ("{0}_{1}" -f (Get-Date).ToString("yyyyMMdd_HHmmss"), $ExportConfigFile)
            Get-Content $defaultConfigPath -Raw | Out-File -FilePath $configPath -Encoding $moduleVariable.fileEncode -Force
        }
        else
        {
            Write-Warning ("Configuration file already exist in '{0}'. Skip creating configuration file." -f $configPath)
        }
    }
}

Function Move-OriginalDefaultConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory = 1, position = 0)]
        [validateScript({Test-Path $_})]
        [string]$defaultConfigPath,

        [parameter(mandatory = 1, position = 1)]
        [string]$ExportConfigDir
    )

    if(Test-Path $defaultConfigPath)
    {
        if (Test-Path $ExportConfigDir)
        {
            Get-ChildItem $ExportConfigDir | Remove-Item -Force -Recurse
        }
        Move-Item -Path (Split-Path $defaultConfigPath -Parent) -Destination $ExportConfigDir -Force
    }
}

Main -Force