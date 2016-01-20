# Read Me Fast

valentia は PowerShell を用いた Windows におけるdeploymentツールです。
valentia を用いることで遠隔サーバー操作が格段に容易になり、日頃の業務が大きく簡便化されます。

# valentia のインストール方法

valentia のインストールは、2種類用意しています。

### 1. [PowerShellGet](https://www.powershellgallery.com/packages/valentia). から

PowerShell v5 や PackageManagement が入った環境で、以下を実行してください。

```powershell
Install-Module -Name valentia
```


### 2. 'PowerShell' か 'コマンドプロンプト' を開き、 ↓のコマンドを貼り付けてエンターキーを押す

||
|----|
|powershell -NoProfile -ExecutionPolicy unrestricted -Command 'iex ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((irm "https://api.github.com/repos/guitarrapc/valentia/contents/valentia/Tools/RemoteInstall.ps1").Content))).Remove(0,1)'|

## インストールパス

インストール完了後、valentia がユーザーフォルダにインストールされます。

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\Modules
```

# 更新

- [VersionHistory](https://github.com/guitarrapc/valentia/blob/master/VersionHistory.md)


# Special Thanks

valentia は、 [capistrano](https://github.com/capistrano/capistrano) と [psake](https://github.com/psake/psake) の影響を大きく受けています。これらは突出した素晴らしいツールであり、 DevOpsといった自動化に大きく寄与してくれます。特に psake は参考になるコーディング例を示し valentia も参考にしています。他に、 [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) と Get-NetworkInfo[Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/)も、非同期実行に関して参考にさせてもらっています。
