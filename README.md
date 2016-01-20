# Read Me Fast

Valentia is PowerShell deployment tool for Server-Client model.
This module set will optimize your work for deploy Commands or files to remote servers.

# How to install valentia.

Let's start install valentia.

You have 2 choice to install valentia.

### 1. [PowerShellGet](https://www.powershellgallery.com/packages/valentia).

Run following command with PowerShell v5 or PackageManagement environment.

```powershell
Install-Module -Name valentia
```

### 2. Open PowerShell or Command prompt, paste the text below and press Enter.

||
|----|
|powershell -NoProfile -ExecutionPolicy unrestricted -Command 'iex ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((irm "https://api.github.com/repos/guitarrapc/valentia/contents/valentia/Tools/RemoteInstall.ps1").Content))).Remove(0,1)'|

## Installed Path

After the installation complete, you will find valentia installed into your current user's Module folder.

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\Modules\valentia
```

# Automate Module Import with PowerShell v3

While valentia sat in standard Module Path, you don't need to import manually.
valentia will automatically loaded into PowerShell session.

### Manually import valentia module

If you want to import, just type following in PowerShell.

```PowerShell
Import-Module valentia
```

# Updates

- [VersionHistory](https://github.com/guitarrapc/valentia/blob/master/VersionHistory.md)

# Special Thanks
Valentia inspired from [capistrano](https://github.com/capistrano/capistrano) and [psake](https://github.com/psake/psake). They are fantastic and awesome tools for automation and DevOps. Especially psake showed cool way of coding and valentia followed in many points. Also [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) and [Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/) give me inspire to do asynchronous execution.
