# Read Me Fast
valentia は PowerShell を用いた Windows におけるdeploymentツールです。
valentia を用いることで遠隔サーバー操作が格段に容易になり、日頃の業務が大きく簡便化されます。


# Special Thanks
valentia は、 Capistrano ( LinuxにおけるRuby 製のデプロイツール) と psake ( PowerShell製のビルドツール ) の影響を大きく受けています。.
これらは突出した素晴らしいツールであり、 DevOpsといった自動化に大きく寄与してくれます。
特に psake は参考になるコーディング例を示し valentia も参考にしています。

他には [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) と Get-NetworkInfo[Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/)も、非同期実行に関して参考にさせてもらっています。



# Latest Change

## Version 0.3.x

- version : 0.3.4
	
	[ author : guitarrapc ]
	
	[ Fev 4, 2013 ]
	
	* Remove non use function Get-ValentiaModuleReload
	* Added function ```ConvertTo-ValentiaTask```. Now you can convert your powershell script to valentia task easier. 
	* Added function ```Show-ValentiaPromptForChoice```. Now you can show prompt easier.
	* Added function ```Get-ValentiaFileEncoding```. Now you can detect file encoding easier.
	* Added function ```Ping-ValentiaGroupAsync```. You can ping to the host ultra fast and test connections.
	* Added function ```Test-ValentiaGroupConnection```. You can filter result of ```Ping-ValentiaGroupAsync``` for demanded status.
	* Added function ```New-ValentiaDynamicParamMulti```. Now you can create Dynamic parameter easier.
	* Enhanced for [issue #47](https://github.com/guitarrapc/valentia/issues/47). Could not enable PSRemoting on AWS Windows Server is now solved. Added Firewall detection for ```Initialize-ValentiaEnvironment```.
	* fix issue : [Edit-valentaiaconfig ISE -NoProfile](https://github.com/guitarrapc/valentia/commit/31bd1a48382a5a59fea90fd87b9d8eff144a3c6a#commitcomment-4621590)
	* fix [issue #36](https://github.com/guitarrapc/valentia/issues/36) : Now installer keep directory structure for module.
	* fix issue [#42](https://github.com/guitarrapc/valentia/issues/42) : Now ```Invoke-ValentiaDownload``` as desired.
	* fix issue [#46](Show-ValentiaGroup Recurse switch defined as parameter) : now Show-ValentiaGroup -Recurse works as desired.
	* Change valentia Development from PowerShell ISE to Visual Studio 2013 with [PowerShell Tools for Visual Studio](http://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597)
	* Change CLR Target to 4.0 and OS version.
	* Changed valentia file encoding from default(shift-jis) to UTF8.
	* Change Module Type from Script Module to Manifest Module.
	* Change Password input from Read-Host to Get-Credential. [Issue #48](https://github.com/guitarrapc/valentia/issues/48)
	* Chage Get-ValentiaGroup for [Issue #50](https://github.com/guitarrapc/valentia/issues/50). Now Get-ValentiaGroup never check connection.
	* Changed parameter for $valentia.RunSpacePool. Now Logical Number of Core will be use for this parameter.
	* Enhanced for [issue #28](https://github.com/guitarrapc/valentia/issues/28)Change ```Invoke-ValentiaAsync``` meassage from Warning line to Progress. You can check each host progress when added -Verbose switch.
	* ErrorPreference handling now can control with valentia-config.ps1
	* define help message for all functions.
	* Added ```-quiet``` switch to ```Invoke-Valentia```,```Invoke-valentiaParallel``` and ```Invoke-ValentiaAsync```. Now you can compress messages and only recieve execution result in bool.


# 対象OS PowerShell バージョン

valentia は PowerShell Version 3.0 以降で動作します。
開発は、 Windows 8, Windows 8.1, Windows 2012 で行っています。
サポートしているOSは、以下の通りです。

- Windows 7 ( PowerShell V3.0 以降)
- Windows 8 ( PowerShell V3.0 以降)
- Windows 8.1 (PowerShell V4.0 以降)
- Windows 2012 ( PowerShell V3.0 以降)
- Windows 2012 R2 (PowerShell V4.0 以降)
- 
ノート : 全ファンクションは Windows Server 2012 x64 English で確認しています。


# 事前準備

valentiaにおけるファイル転送のため、valentiaは 以下が準備されている必要があります。

1. 単独/複数ファイル転送のために、BITS Transferを利用しています。 "Windows の機能" から "IIS BITs Transfer" を有効にしてください。
2. "FastCopy" を フォルダ同期に利用しています。( FastCopyx64 を "C:\Program Files\FastCopy" にインストールしてください。) 
	- [FastCopy をダウンロードしますか? ここをクリックへ HP に移動します。](http://ipmsg.org/tools/fastcopy.html)
3. PowerShell スクリプトが実行できるポリシーになっていることを確認してください。 実行できるポリシーに変更するには以下のコマンドをPowerShellで管理者として実行します。
	- ```Set-ExecutionPolicy RemoteSigned```


# 簡単インストール

valentia のインストールを行ってみましょう！'PowerShell' か 'コマンドプロンプト' を開き、 ↓のコマンドを貼り付けてエンターキーを押すだけです、簡単。

||
|----|
|**powershell -NoProfile -ExecutionPolicy unrestricted -Command 'iex ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((irm "https://api.github.com/repos/guitarrapc/valentia/contents/valentia/RemoteInstall.ps1").Content))).Remove(0,1)'**|



インストール完了後、valentia がユーザーフォルダにインストールされます。

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\Modules
```

## カスタムインストール

### ローカルインストール (現在のユーザーのみ)

もし、リモートインストールがダメな環境では、 valentiaを適当なパスにおいて、```install.bat```　を実行してください。
これで、現在のユーザーのモジュールパスにコピーします。 

```PowerShell
$env:USERPROFILE\documents\WindowsPowerShell\Module\
```

### 全ユーザーでvalentia を利用する

もし、valentia を全ユーザーにインストールする場合は、valentiaモジュールフォルダーを以下のパスに配置します。

```
C:\Windows\System32\WindowsPowerShell\v1.0\Modules\valentia
```

# valentia Module のインポート

PowerShell 3.0においては、デフォルトの psmoduleパスに設置されたモジュールは、スクリプト開始前に自動的に読み込まれます。

しかし、自分の好きなパスにモジュールを置いた場合、つまりデフォルトのモジュールパスでない場合、PowerShellは自動的にモジュールを読み込むことができません。 この場合、```valentia.psd1```があるパスでImport-Module コマンドレットを使ってインポートしてください。

```PowerShell
cd "valentia.psd1 を設置したパス"
Import-Module valentia
```

もし"簡単インストール"で紹介した既定のモジュールパスに配置した場合は、手動でモジュールをインポートする必要はありません。ただ、 ```Import-Module valentia``` で $valentia 変数が読み込まれるため、助けになる可能性はあります。

```PowerShell
Import-Module valentia
```

# valentia Functions

インポート後は、以下のコマンドでvalentia ファンクションを確認できます。

```PowerShell
Get-command -module valentia
```

これらのファンクションが表示されるはずです。

|CommandType|Name|ModuleName|
|----|----|----
|Function|ConvertTo-ValentiaTask|valentia|
|Function|Edit-ValentiaConfig|valentia|
|Function|Get-ValentiaCredential|valentia|
|Function|Get-ValentiaFileEncoding|valentia|
|Function|Get-ValentiaGroup|valentia|
|Function|Get-ValentiaRebootRequiredStatus|valentia|
|Function|Get-ValentiaTask|valentia|
|Function|Initialize-ValentiaEnvironment|valentia|
|Function|Invoke-Valentia|valentia|
|Function|Invoke-ValentiaAsync|valentia|
|Function|Invoke-ValentiaClean|valentia|
|Function|Invoke-ValentiaCommand|valentia|
|Function|Invoke-valentiaDeployGroupRemark|valentia|
|Function|Invoke-ValentiaDeployGroupUnremark|valentia|
|Function|Invoke-ValentiaDownload|valentia|
|Function|Invoke-ValentiaParallel|valentia|
|Function|Invoke-ValentiaSync|valentia|
|Function|Invoke-ValentiaUpload|valentia|
|Function|Invoke-ValentiaUploadList|valentia|
|Function|New-ValentiaCredential|valentia|
|Function|New-ValentiaFolder|valentia|
|Function|New-ValentiaGroup|valentia|
|Function|Ping-ValentiaGroupAsync|valentia|
|Function|Set-ValentiaHostName|valentia|
|Function|Set-ValentiaLocation|valentia|
|Function|Show-ValentiaConfig|valentia|
|Function|Show-ValentiaGroup|valentia|
|Function|Show-ValentiaPromptForChoice|valentia|
|Function|Test-ValentiaGroupConnection|valentia|
|Workflow|Invoke-ValentiaCommandParallel|valentia|

各モジュールには利用しやすいようにAliasが設定されています。
Aliasは以下のコマンドで確認できます。


```PowerShell
Get-Alias | where ModuleName -eq "valentia"
```

これによりvalentiaで定義されているalias一覧が表示されます。

|CommandType|Name|ResolveCommandName|ModuleName|
|----|----|----|----|
|Alias|Clean|Invoke-ValentiaClean|Valentia|
|Alias|Cred|Get-ValentiaCredential|Valentia|
|Alias|Download|Invoke-ValentiaDownload|Valentia|
|Alias|Go|Set-ValentiaLocation|Valentia|
|Alias|Initial|Initialize-ValentiaEnvironment|Valentia|
|Alias|ipremark|Invoke-valentiaDeployGroupRemark|Valentia|
|Alias|ipunremark|Invoke-ValentiaDeployGroupUnremark|Valentia|
|Alias|PingAsync|Ping-ValentiaGroupAsync|Valentia|
|Alias|Rename|Set-ValentiaHostName|Valentia|
|Alias|Sync|Invoke-ValentiaSync|Valentia|
|Alias|Target|Get-ValentiaGroup|Valentia|
|Alias|Task|Get-ValentiaTask|Valentia|
|Alias|Upload|Invoke-ValentiaUpload|Valentia|
|Alias|UploadL|Invoke-ValentiaUploadList|Valentia|
|Alias|Vale|Invoke-Valentia|Valentia|
|Alias|Valea|Invoke-ValentiaAsync|Valentia|
|Alias|Valep|Invoke-ValentiaParallel|Valentia|


# 環境設定コマンド

valentiaによるdeploymentを実行するまえに、サーバーとクラインとで PSRemoting が動作するように設定する必要があります。

### 1. ```Initialize-ValentiaEnvironment``` : サーバーセットアップ

このコマンドは、対象のサーバーをデプロイサーバーとして動作するように環境構成します。

	1. Set-ExecutionPolicy (Default : RemoteSigned)
	2. Enable-PSRemoting
	3. Add hosts to trustedHosts  (Default : *)
	4. Set MaxShellsPerUser from 25 to 100
	5. Add PowerShell Remoting Inbound rule to Firewall (Default : TCP 5985)
	6. Disable Enhanced Security for Internet Explorer (Default : True)
	7. Create OS user for Deploy connection. (Default : ec2-user)
	8. Create Windows PowerShell Module Folder for DeployUser (Default : C:\Users\$ec2-user\Documents\WindowsPowerShell\Modules)
	9. Create/Revise Deploy user credential secure file. (Server Only / Default : True)
	10. Create Deploy Folders (Server Only / Default : True)
	11. Set HostName as format (white-$HostUsage-IP)
	12. Get Status for Reboot Status
	
	* Currently remarking Set-NetworkProfile private

Once ran this command, You will got prompt for secret password of "OS User" (in default is ec2-user).

```PowerShell
Initialize-ValentiaEnvironment -Server -TrustedHosts "*"
```

** you can omit ```-Server``` and ```-TrustedHosts "*"``` as it were default **

```PowerShell
Initialize-ValentiaEnvironment
```

When Credential prompt was display input password in masked read line, then OS user (in default ec2-user) will be created and all PSRemote session to all hosts are enabled.
Also trying to save password in secdure stirng in default, input deploy user password again.


** If you want to restrict Trusted Hosts, you can use -TrustedHosts parameter to select. **

ex) restrict to 10.0.0.0
```PowerShell
Initialize-ValentiaServer -TrustedHosts "10.0.0.0"
```

** If you want setup without OS User setup? then add -NoOSUser switch. **
```PowerShell
Initialize-ValentiaEnvironment -Server -TrustedHosts "*" -NoOSUser
```

** ServerOnly : If you want setup without OS User setup and Save Credentail? then add -NoPassSave switch. **
```PowerShell
Initialize-ValentiaEnvironment -Server -TrustedHosts "*" -NoPassSave
```

** Adding ```-Verbose``` switch will ease you check how ファンクション working. **

### 2. ```Initialize-ValentiaEnvironment -Client``` : Setup Clients

This command will let your Client for valentia remoting.

	1. Set-ExecutionPolicy (Default : RemoteSigned)
	2. Enable-PSRemoting
	3. Add hosts to trustedHosts  (Default : *)
	4. Set MaxShellsPerUser from 25 to 100
	5. Add PowerShell Remoting Inbound rule to Firewall (Default : TCP 5985)
	6. Disable Enhanced Security for Internet Explorer (Default : True)
	7. Create OS user for Deploy connection. (Default : ec2-user)
	8. Create Windows PowerShell Module Folder for DeployUser (Default : C:\Users\$ec2-user\Documents\WindowsPowerShell\Modules)
	9. Create Deploy Folders (Server Only / Default : True)
	10. Set HostName as format (white-$HostUsage-IP)
	11. Get Status for Reboot Status


Once ran this command, You will got prompt for secret password of "OS User" (in default is ec2-user).

```PowerShell
Initialize-ValentiaEnvironment -Client -TrustedHosts "*"
```

** you can omit ```-TrustedHosts "*"``` as it were default**

- NOTE: If you sat Server and Client "SAME USER and SAME PASSWORD" then credential will be escaped.
- This means, if you ran Initialize-ValentiaServer and Initialize-ValentiaClient, then ec2-user will be used and can be escape credential input.
- Because of Parallel commands using workflow, (Domain separation), credential escape was required.
- The other command can retrieve and use Credential, so other user credential will also valid for them.


Wanna setup without OS User setup? then add -NoOSUser switch.
```PowerShell
Initialize-ValentiaEnvironment -Client -TrustedHosts "*" -NoOSUser
```

** Adding ```-Verbose``` switch will ease you check how ファンクション working. **

### 3. ```New-ValentiaCredential``` : Create New Credential secure file

Following command will make secure string file to save your credential.
** If you ran Initialize-ValentiaServer without -NoSavePass switch, then you can skip this section. **
** However if you want to revise saved secure Password, then use this Cmdlet to revise save file. **


```PowerShell
New-ValentiaCredential
```

or you can select user for credential.

```PowerShell
New-ValentiaCredential -User hogehoge
```

- NOTE: Once you execute command, you will got prompt to save secure strings of user.
- Default user is sat as ec2-user, it will use if no -user had input.


### 4. ```Initialize-ValentiaGroup``` : Create New deploygroup file

To execute deployment command to multiple hosts, you don't need to input hosts everytime.
Just list them up in file.

The file you specified will be output in following path.
```
C:\Deployment\Deploy_group\ *****.ps1
```

Deploy Group file just required to be split by `r`n.

SAMPLE deployGroup input
```
10.0.0.100
10.0.0.101
# 10.0.0.101 <= this line will be remarked as not started with decimal
```

You can create deploy group file in only one command.
Off cource there are several way to create deploygroup file.
You can make file with excel,notepad or powershell utils here.

```PowerShell
New-ValentiaGroup -DeployClients array[] -FileName FILENAME.ps1
```

SAMPLE CODE:
```PowerShell
New-ValentiaGroup -DeployClients "10.0.0.1","10.0.0.2" -FileName sample.ps1
```

this will make sample.ps1 in C:\Deployment\Deploy_group\ with 2 hosts ("10.0.0.1","10.0.0.2") written.

When using DeployGroup, just set file name without Extensions.
ex) if you sat file name as "new.ps1" then use it by "new".

# Task for Commandset

### Summary of Task

You can make task file To execute many commands.
Write task in file with below format and save it in BranchFolders you want to work.
- Note: BranchFolder will be C:\Deployment "application", "Image", "SWF", "SWF-Image", "Utils". (Created by Initialize-ValentiaServer)

``` PowerShell
Task taskname {
	Commandset you want to run1
	Commandset you want to run2
}
```

After you made task, you should move to BranchFolder you saved task.


### Convert existing .ps1 to task and setup task.

It's easy to convert normal .ps1 to task.
Task file format is as below.

```PowerShell
task taskname -Action{
	PowerShell Commands you want to run
}
```

If you .ps1 have like this code.

```PowerShell
Get-ChildItem
```


Then task will be like this.

```PowerShell
task taskname -Action{
	Get-ChildItem
}
```

You can use almost all cmdlets and variables set.
Please check vale and valep section about a detail of some cmdlets cannot use in task.

- Note:
	* All valentia cmdlets got credential before running task, therefore you don't need to get anymnore credentials in your script.
	* In other word, do not try to get another credential in you script. Especially in "valep" .



# Execute deploy Commands

After you satup Server/Clients, Credential amd DeproyGroups you can start execution.

### 1. ```vale``` : Sequential Single Command execution

This command will execute ScriptBlock to deploy group written in DeployGroup.ps1.
As sequencially running, many hosts will takes x times to complete job.

```PowerShell
vale Deploygroup {ScriptBlock}
```

SAMPLE:
```PowerShell
vale new {Get-ChildItem}
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **

### 2. ```vale``` : Sequential Commandset execution

Just make task for commandset.
```PowerShell
Task taskname {
	Commandset you want to run1
	Commandset you want to run2
}
```

After you made task, you should move to BranchFolder you saved task.
"go" command will ease you move to BranchFolder path where you carete task. 
ex ) application, then

``` PowerShell
go application
```

After you move to BranchFolder run vale command

```PowerShell
vale DeployGroup .\Taskfile.ps1
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **

### 3. ```valep``` : Parallel Single Command execution 

Almost same as vale command, just change command to valep.
It will speed up abpit 3-5 times than sequencial command.

- Note that this isn't asyncroniuous but only parallel.

```PowerShell
valep Deploygroup {ScriptBlock}
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **

### 4. ```valep``` : Parallel Commandset execution

Almost same as valep command, just change command to valep.
It will speed up abpit 3-5 times than sequencial command.

- Note that this isn't asyncroniuous but only parallel.

Just make task for commandset.
```PowerShell
Task taskname {
	Commandset you want to run1
	Commandset you want to run2
}
```

After you made task, you should move to BranchFolder you saved task.
"go" command will ease you move to BranchFolder path where you carete task. 
ex ) application, then
``` PowerShell
go application
```

After you move to BranchFolder run valep command

```PowerShell
valep DeployGroup .\Taskfile.ps1
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **


### 5. ```valea``` : Asynchronous Single Command execution 

Not same as vale and valep command. Because valea will execute asynchrously.
vale is sequential job and will cost host count.
valep is parallel execution similer to valea but is not asynchronous.
valea is multithread asynchronous commad and also can call from C# while valep cannot.

It will speed up O(n) times with host count times than sequencial command.


```PowerShell
valea Deploygroup {ScriptBlock}
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **


### 6. ```valea``` : Asynchronous Commandset execution

Not same as vale and valep command. Because valea will execute asynchrously.
vale is sequential job and will cost host count.
valep is parallel execution similer to valea but is not asynchronous.
valea is multithread asynchronous commad and also can call from C# while valep cannot.

Just make task for commandset.
```PowerShell
Task taskname {
	Commandset you want to run1
	Commandset you want to run2
}
```

After you made task, you should move to BranchFolder you saved task.
"go" command will ease you move to BranchFolder path where you carete task. 
ex ) application, then
``` PowerShell
go application
```

After you move to BranchFolder run valea command

```PowerShell
valea DeployGroup .\Taskfile.ps1
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **


# Execute File transfer Commands

### 1. ```upload``` : Single File Upload from Server to Clients

You can upload file to client with "upload" command.
This wrapps BITs Transfer inside.
- Note: The files using to upload must set in C:\Deployment\Upload at Server side.

ex ) Upload file c:\deployment\upload\upload.txt to Remote Client C:\ for DeployGroup new is.

```Powershell
upload -SourceFile "filename in C:\Deployment\Upload\...." -DestinationFolder c:\ -DeployGroup new
```

you can omit parameter names like this.
```Powershell
upload "upload.txt" c:\ new
```


### 2. ```uploadL``` : Files in List Upload from Server to Clients

You can upload multiple files listed in file with "uploadL" command.
This allow you ease select file manytime in command.

This wrapps BITs Transfer inside.
- Note: The files using to upload must set in C:\Deployment\Upload at Server side.

before use ran this command, you should create list file in C:\Deployment\Upload direcoty.
File format should like this.
```
Source, Destination
C:\Deployment\Upload\DownLoad.txt,\\10.0.4.100\C$
C:\Deployment\Upload\hogehoge.txt,\\10.0.4.100\C$
```

A Top line is Source, Destination header.
After 2nd line is SourceFile fullpath and Destination folder full path to transfer.
Deleimiter must ",".

Now you are ready to transfer list of files with following command.

ex ) Upload files listed in c:\deployment\upload\list.txt to Remote Client C:\ for DeployGroup new is.

```Powershell
UploadL -ListFile list.txt -DestinationFolder c:\ -DeployGroup new
```

Offcource you can omit poarameter names like this.

```Powershell
UploadL list.txt c:\ new
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **


### 3. ```sync``` : Sync Server Folder and Files with Clients (DIFF mode)

You can Synchronise DeployServer folder and Clients Folder.
Parent will be DeployServer, it means clietns folder will be changed to sync as like as DeployServer.

ex ) sync folder C:\Requirements to Remote Client folder "C:\hoge hoge" for DeployGroup new is.
```Powershell
sync -SourceFolder C:\Requirements -DestinationFolder "c:\hoge hoge" -DeployGroup new
```

Offcource you can omit poarameter names like this.

```Powershell
Sync C:\Requirements "c:\hoge hoge" new
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **
