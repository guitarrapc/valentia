#Requires -Version 2.0

# Windows 7 and later is requires.

function Main
{
    [CmdletBinding()]
    Param
    (
        [string]$Modulepath = (GetModulePath),
        
        [bool]$Renew = $false,

        [switch]$Force = $false,

        [switch]$Whatif = $false
    )

    $ErrorActionPreference = "Stop"
    $path = [System.IO.Directory]::GetParent((Split-Path (Resolve-Path -Path $PSCommandPath) -Parent))
    $moduleName = Get-ModuleName -path $path
    $moduleFullPath = Join-Path $modulepath $moduleName

    Write-Verbose ("Checking Module Root Path '{0}' is exist not not." -f $modulepath)
    if(-not(Test-ModulePath -modulepath $modulepath))
    {
        Write-Warning "$modulepath not found. creating module path."
        New-Item -Path $modulepath -ItemType directory -Force > $null
    }

    # Remove Existing
    if($reNew -and (Test-ModulePath -modulepath $moduleFullPath))
    {
        Write-Warning ("'{0}' already exist. Removing Existing modules." -f $moduleFullPath)
        Remove-Item -Path $moduleFullPath -Recurse -Force
    }

    try
    {
        # Copy Module
        Write-Host ("Copying module '{0}' to Module path '{1}'." -f $moduleName, $moduleFullPath) -ForegroundColor Cyan
        Copy-ItemEX -path $path -destination $moduleFullPath -Targets * -Recurse -Force 
        exit 0
    }
    catch
    {
        exit 1
    }
}

function GetModulePath
{
    $ModulePath = $env:PSModulePath -split ";" | where {$_ -like ("{0}*" -f [environment]::GetFolderPath("MyDocuments"))}
    if (($ModulePath | measure).count -eq 1){ return $ModulePath }
    if (($ModulePath | measure).count -eq 0)
    {
        $answer = Read-Host -Prompt "PSModulePath detected as not include Documents path. Please input path to install valentia."
        if (-not (Test-Path $answer)){ throw New-Object New-Object System.IO.FileNotFoundException ("Specified Path not found exception!!", $answer) }
        return $answer
    }

    if (($ModulePath | measure).count -gt 1)
    {
        $param = @{
            title = "PSModulePath contains more than 2 Documents directory."
            message = "Please select which PSmodulePath to install valentia."
            questions = $ModulePath
        }
        return Show-PromptForChoice @param
    }
}

Function Test-ModulePath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, mandatory = $true)]
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
        [Parameter(Position = 0, mandatory = $true)]
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
        [parameter(mandatory = $true, Position  = 0, ValueFromPipeline = 1, ValueFromPipelineByPropertyName =1)]
        [alias('PSParentPath')]
        [string]$Path,

        [parameter(mandatory = $true, Position  = 1, ValueFromPipelineByPropertyName =1)]
        [string]$Destination,

        [parameter(mandatory = $false, Position  = 2, ValueFromPipelineByPropertyName =1)]
        [string[]]$Targets,

        [parameter(mandatory = $false, Position  = 3, ValueFromPipelineByPropertyName =1)]
        [string[]]$Excludes,

        [parameter(mandatory = $false, Position  = 4, ValueFromPipelineByPropertyName =1)]
        [Switch]$Recurse,

        [parameter(mandatory = $false, Position  = 5)]
        [switch]$Force,

        [parameter(mandatory = $false, Position  = 6)]
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

Main -Renew $true -Force