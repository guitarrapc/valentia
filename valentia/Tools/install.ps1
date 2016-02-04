#Requires -Version 2.0
function Main
{
    [CmdletBinding()]
    Param
    (
        [string]$Modulepath
    )

    $ErrorActionPreference = "Stop"
    $path = [System.IO.Directory]::GetParent((Split-Path (Resolve-Path -Path $PSCommandPath) -Parent))
    $moduleName = Get-ModuleName -path $path
    $moduleFullPath = Join-Path $Modulepath $moduleName

    Write-Verbose ("Checking Module Root Path '{0}' is exist not not." -f $modulepath)
    if(-not(Test-ModulePath -modulepath $modulepath))
    {
        Write-Warning "$modulepath not found. creating module path."
        New-Item -Path $modulepath -ItemType directory -Force > $null
    }

    try
    {
        Write-Verbose ("Checking Module Path '{0}' is exist not not." -f $moduleFullPath)
        if(Test-ModulePath -modulepath $moduleFullPath)
        {
            Write-Warning ("'{0}' already exist. Escape from creating module Directory." -f $moduleFullPath)
            Remove-Item -Path $moduleFullPath -Recurse -Force
        }

        # Copy Module
        Write-Host ("Copying module '{0}' to Module path '{1}'." -f $moduleName, $moduleFullPath) -ForegroundColor Cyan
        Copy-Item -path $path -destination $moduleFullPath -Recurse -Force

        # Import Module
        Write-Host ("Importing Module '{0}'" -f $moduleName) -ForegroundColor cyan
        Import-Module -Name $moduleName
    }
    catch
    {
        exit 1
    }
    exit 0
}

Function Test-ModulePath
{
    [OutputType([bool])]
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
    [OutputType([string])]
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

function Test-ElavateOrNot
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
}

if (! (Test-ElavateOrNot))
{
    Write-Host -Object "管理者で起動してください" -ForegroundColor Red;
    exit 1;
}

$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules"
Main -Modulepath $modulePath