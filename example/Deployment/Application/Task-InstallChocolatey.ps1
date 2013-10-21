task Task-InstallChocolatey -action {

    # installation
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')
    
    # Environment Setip
    $envChocolatey = "%systemdrive%\chocolatey\bin;"
    $envChocolateyRoot = Join-Path (Get-Item ([System.Environment]::SystemDirectory)).Root "chocolatey\bin"
    if (-not($env:Path -like "*$envChocolatey*") -or -not($env:Path -like "*$envChocolateyRoot*"))
    {
        $currentEnvPath = $env:Path
        $newEnvPath = $env:Path + "$envChocolatey"
        [System.Environment]::SetEnvironmentVariable("Path",$newEnvPath,"user")
    }

}