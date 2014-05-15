#Requires -Version 2.0

# Windows 7 and later is requires.
function Main
{
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Position = 0,
            Mandatory = 0)]
        [string]
        $path = (Split-Path (Resolve-Path -Path $pwd) -Parent),

        [Parameter(
            Position = 1,
            Mandatory = 0)]
        [string]
        $modulepath = ($env:PSModulePath -split ";" | where {$_ -like ("{0}*" -f [environment]::GetFolderPath("MyDocuments"))}),

        [Parameter(
            Position = 2,
            Mandatory = 0)]
        [bool]
        $reNew = $false
    )

    if(-not(Test-ModulePath -modulepath $modulepath))
    {
        Write-Warning "$modulepath not found. creating module path."
        New-ModulePath -modulepath $modulepath
    }

    $moduleName = Get-ModuleName -path $path
    $dir = Join-Path $modulepath $moduleName
    Write-Verbose ("Checking Module Path '{0}' is exist not not." -f $dir)
    if($reNew -and (Test-ModulePath -modulepath $dir))
    {
        Write-Warning ("'{0}' already exist. Escape from creating module Directory." -f $dir)
        Remove-ModulePath -path $dir -Verbose
    }

    if ($moduleName)
    {
        Write-Host ("Copying module '{0}' to Module path '{1}'." -f $moduleName, "$modulepath") -ForegroundColor Cyan
    }
    else
    {
        Write-Host ("Copying scripts in '{0}' to Module path '{1}'." -f $path , "$modulepath") -ForegroundColor Green
    }
    
    $destinationtfolder = Copy-Module -path $path -destination $modulepath
    Write-Host ("Module have been copied to PowerShell Module path '{0}'" -f $destinationtfolder) -ForegroundColor Green

    Test-ImportModule -ModuleName $moduleName
    Write-Host ("Imported Module '{0}'" -f $moduleName) -ForegroundColor Green
    $moduleVariable = (Get-Variable -Name $moduleName).Value
    $originalDefaultConfigPath = Join-Path $moduleVariable.modulePath $moduleVariable.defaultconfiguration.original -Resolve
    Set-DefaultConfig -defaultConfigPath $originalDefaultConfigPath -ExportConfigDir $moduleVariable.defaultconfiguration.dir
    Remove-OriginalDefaultConfig -defaultConfigPath $originalDefaultConfigPath
}

Function Get-OperatingSystemVersion
{
    [System.Environment]::OSVersion.Version
}

Function Test-ModulePath
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1)]
        [string]
        $modulepath        
    )
 
    Write-Verbose "Checking Module Home."
    if ((Get-OperatingSystemVersion) -ge 6.1)
    {
        Write-Verbose "Your operating system is later then Windows 7 / Windows Server 2008 R2. Continue evaluation."
        return Test-Path -Path $modulepath
    }
}

Function New-ModulePath
{

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1)]
        [string]
        $modulepath
    )

    if ((Get-OperatingSystemVersion) -ge 6.1)
    {         
        Write-Verbose "Creating Module Home at $modulepath"
        New-Item -Path $modulepath -ItemType directory > $null
    }
}

Function Get-ModuleName
{

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1)]
        [string]
        $path
    )

    if (Test-Path $path)
    {
        $moduleName = ((Get-ChildItem $path | where {$_.Extension -eq ".psm1"})).BaseName
        return $moduleName
    }
}

Function Remove-ModulePath
{

    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = 1)]
        [string]
        $path
    )

    if (Test-Path $path)
    {
        Remove-Item -Path $path -Recurse -Force
    }
}

Function Copy-Module
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory,
            position = 0)]
        [validateScript({Test-Path $_})]
        [string]
        $path,

        [parameter(
            mandatory,
            position = 1)]
        [validateScript({(Get-Item $_).PSIsContainer -eq $true})]
        [string]
        $destination
    )

    if(Test-Path $path)
    {
        $rootpath = Get-Item $path
        
        Get-ChildItem -Path $path `
        | %{

            # Define target directory path for each directory
            if ($_.Directory.Name -ne $rootpath.Name)
            {
                $script:droot = Join-Path $destination $rootpath.Name
                $script:ddirectory = Join-Path $droot $_.Directory.Name
            }
            else
            {
                $script:ddirectory = Join-Path $destination $_.Directory.Name
            }

            # Check target directory path is already exist or not
            if(-not(Test-Path $ddirectory))
            {
                Write-Verbose "Creating $ddirectory"
                $script:ddirectorypath = New-Item -Path $ddirectory -ItemType Directory -Force
            }
            else
            {
                $script:ddirectorypath = Get-Item -Path $ddirectory
            }

            # Copy Items to target directory
            try
            {
                $script:dpath = Join-Path $ddirectorypath $_.Name

                Write-Host ("Copying '{0}' to {1}" -f $_.FullName, $dpath) -ForegroundColor Cyan
                Copy-Item -Path $_.FullName -Destination $ddirectorypath -Force -Recurse -ErrorAction Stop
            }
            catch
            {
                Write-Error $_
            }
        }

        # return copied destination path
        return $droot
    }
    else
    {
        throw "{0} not found exception!" -f $path
    }
}

Function Test-ImportModule
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory,
            position = 0)]
        [string]
        $ModuleName
    )

    if(Get-Module -ListAvailable | where Name -eq $moduleName)
    {
        Import-Module (Join-Path (Join-Path $modulepath $moduleName) ("{0}.psd1" -f $moduleName)) -PassThru -Force
    }
}

Function Set-DefaultConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory,
            position = 0)]
        [validateScript({Test-Path $_})]
        [string]
        $defaultConfigPath,

        [parameter(
            mandatory,
            position = 1)]
        [string]
        $ExportConfigDir
    )

    if(Test-Path $defaultConfigPath)
    {
        if (-not (Test-Path $ExportConfigDir))
        {
            New-Item -Path $ExportConfigDir -ItemType Directory -Force > $null
        }
        
        $configName = Split-Path $defaultConfigPath -Leaf
        $configPath = Join-Path $ExportConfigDir $configName
        if (-not(Test-Path $configPath))
        {
            Write-Host ("Default configuration file created in '{0}'" -f $configPath) -ForegroundColor Green
            Get-Content $defaultConfigPath -Raw | Out-File -FilePath $configPath -Encoding $moduleVariable.fileEncode -Force
        }
        else
        {
            Write-Warning ("Configuration file already exist in '{0}'. Skip creating configuration file." -f $configPath)
        }
    }
}

Function Remove-OriginalDefaultConfig
{
    [CmdletBinding()]
    param
    (
        [parameter(
            mandatory,
            position = 0)]
        [validateScript({Test-Path $_})]
        [string]
        $defaultConfigPath
    )

    if(Test-Path $defaultConfigPath)
    {
        Remove-Item -Path (Split-Path $defaultConfigPath -Parent) -Force -Recurse
    }
}

. Main -reNew $true