# Read Me Fast
valentia は PowerShell を用いた Windows におけるdeploymentツールです。
valentia を用いることで遠隔サーバー操作が格段に容易になり、日頃の業務が大きく簡便化されます。


# Special Thanks
valentia は、 [capistrano](https://github.com/capistrano/capistrano) と [psake](https://github.com/psake/psake) の影響を大きく受けています。これらは突出した素晴らしいツールであり、 DevOpsといった自動化に大きく寄与してくれます。特に psake は参考になるコーディング例を示し valentia も参考にしています。他に、 [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) と Get-NetworkInfo[Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/)も、非同期実行に関して参考にさせてもらっています。


# Latest Change

- version : 0.3.7
	
	[ author : guitarrapc ]
	
	[ Mar 17, 2014 ]
	
	* fix number of maxRunSpacePool. Now Concurrency is more efficient than previous release.
	* Added -quiet switch to Ping-ValentiaGroup function. You can suppress host display with this switch.
	* Added Set-ValentiaWSManMaxProcessesPerShell for Initialize-ValentiaEnvironment. Now more number of process will run.
	* Added Set-ValentiaCredential. This will store your credential in Windows Credential Manager.
	* New-ValentiaCredential is now deprecated. Valentia Credential will no longer keep your credential in SecureString File format. Please use Set-ValentiaCredential to manage your credential.
	* Test-ValentiaConnection is now deprecated. Use Ping-ValentiaGroup for test connection.
	* Invoke-ValentiaParallel is now deprecated. As Workflow is not useful in many deployemnt cases, valentia no longer support workflow.
	* As Workflow ristrection is taken away, you can use full PowerShell code. (Since Workflow blocks some cmdlet like Write-Host to use in InlineScript, but Workflow will never use in valentia.)

# 対象OS PowerShell バージョン

|OS|PowerShell|
|----|----|
|Windows 7 SP1  |V3.0 and higher|
|Windows 8      |V3.0 and higher|
|Windows 8.1    |V4.0 and higher|
|Windows 2012   |V3.0 and higher|
|Windows 2012 R2|V4.0 and higher|

#### NOTE: 全ファンクションは Windows Server 2012 x64 English で確認しています。


# 事前準備

- valentiaにおけるファイル転送のため、valentiaは 以下が準備されている必要があります。

|#|概要|NOTE|
|----|----|----|
|1.| "FastCopy" を フォルダ同期に利用しています。( FastCopyx64 を "C:\Program Files\FastCopy" にインストールしてください。) |[FastCopy をダウンロードしますか? ここをクリックへ HP に移動します。](http://ipmsg.org/tools/fastcopy.html)|
|2.| PowerShell スクリプトが実行できるポリシーになっていることを確認してください。 実行できるポリシーに変更するには以下のコマンドをPowerShellで管理者として実行します。|```Set-ExecutionPolicy RemoteSigned```|


# 簡単インストール

- valentia のインストールを行ってみましょう！'PowerShell' か 'コマンドプロンプト' を開き、 ↓のコマンドを貼り付けてエンターキーを押すだけです、簡単。

||
|----|
|**powershell -NoProfile -ExecutionPolicy unrestricted -Command 'iex ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((irm "https://api.github.com/repos/guitarrapc/valentia/contents/valentia/Tools/RemoteInstall.ps1").Content))).Remove(0,1)'**|


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
|Function    |ConvertTo-ValentiaTask             |valentia|  
|Function    |Edit-ValentiaConfig                |valentia|  
|Function    |Get-ValentiaCredential             |valentia|  
|Function    |Get-ValentiaFileEncoding           |valentia|  
|Function    |Get-ValentiaGroup                  |valentia|  
|Function    |Get-ValentiaRebootRequiredStatus   |valentia|  
|Function    |Get-ValentiaTask                   |valentia|  
|Function    |Initialize-ValentiaEnvironment     |valentia|  
|Function    |Invoke-Valentia                    |valentia|  
|Function    |Invoke-ValentiaAsync               |valentia|  
|Function    |Invoke-ValentiaClean               |valentia|  
|Function    |Invoke-ValentiaCommand             |valentia|  
|Function    |Invoke-ValentiaDeployGroupRemark   |valentia|  
|Function    |Invoke-ValentiaDeployGroupUnremark |valentia|  
|Function    |Invoke-ValentiaDownload            |valentia|  
|Function    |Invoke-ValentiaSed                 |valentia|  
|Function    |Invoke-ValentiaSync                |valentia|  
|Function    |Invoke-ValentiaUpload              |valentia|  
|Function    |Invoke-ValentiaUploadList          |valentia|  
|Function    |New-ValentiaDynamicParamMulti      |valentia|  
|Function    |New-ValentiaFolder                 |valentia|  
|Function    |New-ValentiaGroup                  |valentia|  
|Function    |Ping-ValentiaGroupAsync            |valentia|  
|Function    |Set-ValentiaCredential             |valentia|  
|Function    |Set-ValentiaHostName               |valentia|  
|Function    |Set-ValentiaLocation               |valentia|  
|Function    |Show-ValentiaConfig                |valentia|  
|Function    |Show-ValentiaGroup                 |valentia|  
|Function    |Show-ValentiaPromptForChoice       |valentia|  
|Filter      |Write-ValentiaVerboseDebug         |valentia|  

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
|Alias|IPRemark|Invoke-valentiaDeployGroupRemark|Valentia|
|Alias|IPUnremark|Invoke-ValentiaDeployGroupUnremark|Valentia|
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


# Execute deploy Commands

After you satup Server/Clients, Credential amd DeproyGroups you can start execution.


## 1. vale : Back ground job execution.

> **vale** is Alias of ```Invoke-Valentia```. This will execute Command to deploy group as back ground job.
> vale is the standard way of valentia Command execution to the host, and quite fast in many cases. (Invoke-Valentia will run like Asynchros.)

You have 2 choice executing command to host.

|#|Run|Expression|
|----|----|----|
|1.|ScriptBlock|```vale Deploygroup {ScriptBlock}```|
|2.|Task File|```vale DeployGroup .\Taskfile.ps1```|


## 2. valea : Asynchronous RunSpace Command invokation.

> **valea** is Alias of ```Invoke-ValentiaAsync```. This will execute Command to deploy group as RunSpacePooling.
> valea is the asynchronous way of valentia Command execution to the host, and quite fast in most of the cases.

You have 2 choice executing command to host.

|#|Run|Expression|
|----|----|----|
|1.|ScriptBlock|```valea Deploygroup {ScriptBlock}```|
|2.|Task File|```valea DeployGroup .\Taskfile.ps1```|


# Execute File transfer Commands

### 1. upload : Single File Upload from Server to Clients

> **upload** is Alias of ```Invoke-ValentiaUpload```. You can upload file to client.
> This function wrapps BITs Transfer inside and you can use option of BITS Transfer.

#### NOTE: The files using to upload must set in C:\Deployment\Upload at Server side.

You have 2 choice executing command to host.

ex ) Upload file c:\deployment\upload\upload.txt to Remote Client C:\ for DeployGroup new is.

|#|Run|Expression|
|----|----|----|
|1.|Synchronous|```upload -SourceFile "hoge.txt" -DestinationFolder c:\ -DeployGroup new```|
|2.|Asynchronous|```upload -SourceFile "hoge.txt" -DestinationFolder c:\ -DeployGroup new -Async```|

### 2. uploadL : Files in List Upload from Server to Clients

> **uploadL** is Alias of ```Invoke-ValentiaUploadList```. You can upload multiple files listed in file.
> This function wrapps BITs Transfer inside and you can use option of BITS Transfer.

#### NOTE: The files using to upload must set in C:\Deployment\Upload at Server side.

- List File format should like this.

```
Source, Destination
C:\Deployment\Upload\DownLoad.txt,\\10.0.4.100\C$
C:\Deployment\Upload\hogehoge.txt,\\10.0.4.100\C$
```

> 1st top line is an "Header" for Source, Destination.
> 2nd line is SourceFile fullpath and Destination folder full path to transfer.
> Keep Deleimiter as ",".

ex ) Upload files listed in c:\deployment\upload\list.txt to Remote Client C:\ for DeployGroup new is.

|#|Run|Expression|
|----|----|----|
|1.|Synchronous|```UploadL -ListFile list.txt -DestinationFolder c:\ -DeployGroup new```|
|2.|Asynchronous|```UploadL -ListFile list.txt -DestinationFolder c:\ -DeployGroup new -Async```|

### 3. sync : Sync Server Folder and Files with Clients (DIFF mode)

> **sync** is Alias of ```Invoke-ValentiaSync```. You can Synchronise DeployServer folder and Clients Folder.
> Parent will be DeployServer, it means clietns folder will be changed to sync as like as DeployServer.
> This function wrapps FastCopy.exe inside and you need install FastCopy.exe inadvance.

ex ) sync folder C:\Requirements to Remote Client folder "C:\hoge hoge" for DeployGroup new is.

|#|Run|Expression|
|----|----|----|
|1.|Synchronous|```sync -SourceFolder C:\Requirements -DestinationFolder "c:\hoge hoge" -DeployGroup new```|
|2.|Asynchronous|Not yet ready.|


# 環境設定コマンド

valentiaによるdeploymentを実行するまえに、サーバーとクラインとで PSRemoting が動作するように設定する必要があります。

### 1. Initialize-ValentiaEnvironment : サーバーセットアップ

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


### 2. Initialize-ValentiaEnvironment -Client : Setup Clients

- This command will let your Client for valentia remoting.

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


- Once ran this command, You will got prompt for secret password of "OS User" (in default is ec2-user).

```PowerShell
Initialize-ValentiaEnvironment -Client -TrustedHosts "*"
```

- you can omit ```-TrustedHosts "*"``` as it were default

> - NOTE: If you sat Server and Client "SAME USER and SAME PASSWORD" then credential will be escaped.
> 
> - This means, if you ran Initialize-ValentiaServer and Initialize-ValentiaClient, then ec2-user will be used and can be escape credential input.
> 
> - Because of Parallel commands using workflow, (Domain separation), credential escape was required.
> 
> - The other command can retrieve and use Credential, so other user credential will also valid for them.


- Wanna setup without OS User setup? then add -NoOSUser switch.

```PowerShell
Initialize-ValentiaEnvironment -Client -TrustedHosts "*" -NoOSUser
```


### 3. Set-ValentiaCredential : Set Credential into Windows Credential Manager

- This function will store your credential to authorize PSRemoting into Windows Credential Manager.

> - If you ran Initialize-ValentiaServer without -NoSavePass switch, then you can skip this section.
> - User name for the credential will be used as define in config file.

```PowerShell
New-ValentiaCredential
```

> NOTE: Once you execute command, you will got prompt to save secure strings of user.


### 4. Get-ValentiaCredential :Read Credential from Windows Credential Manager

- This function will read your credential from Windows Credential Manager, and return PSCredential Type.

```PowerShell
Get-ValentiaCredential
```

### 5. Initialize-ValentiaGroup : Create New deploygroup file

> - To execute deployment command to multiple hosts, you don't need to input hosts everytime. Just list them up in file.
> - The file you specified will be output in following path.

```
C:\Deployment\Deploygroup\ *****.ps1
```

- Deploy Group file just required to be split by `r`n.
- SAMPLE deployGroup input

```
10.0.0.100
10.0.0.101
# 10.0.0.101 <= this line will be remarked as not started with decimal
```

- You can create deploy group file in only one command. Of cource there are several way to create deploygroup file.
- You can make file with excel,notepad or powershell utils here.

```PowerShell
New-ValentiaGroup -DeployClients array[] -FileName FILENAME.ps1
```

- SAMPLE CODE:

```PowerShell
New-ValentiaGroup -DeployClients "10.0.0.1","10.0.0.2" -FileName sample.ps1
```

- This will make sample.ps1 in C:\Deployment\Deploy_group\ with 2 hosts ("10.0.0.1","10.0.0.2") written.

- When using DeployGroup, just set file name without Extensions.

ex) if you sat file name as "new.ps1" then use it by "new".

### 6. Invoke-valentiaDeployGroupRemark : Remark ipaddress for deploygroup file inside deploygroup

- There would be many time to remark some deploy target inside deploygroup file. This is easy work but boring to check which file contains target deploy ip.

```
C:\Deployment\Deploygroup\**\**\.....*****.ps1
```

- SAMPLE deployGroup input

```
10.0.0.100
10.0.0.101
10.0.0.102 <= if you want to remark this line for all the files inside deploygroup folder.
```

- Just type as like this.

```PowerShell
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.102 -overWrite -Verbose
```

- This will change PowerShell

```
10.0.0.100
10.0.0.101
#10.0.0.102
```

- if you just want to check how affect and don't want to replace file, then remove -overwrite switch.

```PowerShell
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.102 -Verbose
```
 

### 7. Invoke-valentiaDeployGroupUnremark : Unremark ipaddress for deploygroup file inside deploygroup

- if you remark ipaddresses in deploygroup file, then you want to unremark it:) This function will ease you unremark target ipaddresses and check how change.


```
C:\Deployment\Deploygroup\**\**\.....*****.ps1
```

- SAMPLE deployGroup input

```
10.0.0.100
10.0.0.101
#10.0.0.102 <= if you want to unremark this line for all the files inside deploygroup folder.
```

- Just type as like this.

```PowerShell
Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.102 -overWrite -Verbose
```

- This will change PowerShell

```
10.0.0.100
10.0.0.101
10.0.0.102
```

- if you just want to check how affect and don't want to replace file, then remove -overwrite switch.

```PowerShell
Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.102 -Verbose
```


# Task for Commandset

### Summary of Task

- You can make task file To execute many commands.
- Write task in file with below format and save it in BranchFolders you want to work.

> Note: BranchFolder will be C:\Deployment "application", "Image", "SWF", "SWF-Image", "Utils". (Created by Initialize-ValentiaServer)

``` PowerShell
Task taskname {
	Commandset you want to run1
	Commandset you want to run2
}
```

- After you made task, you should move to BranchFolder you saved task.

### Convert existing .ps1 to task and setup task.

- It's easy to convert normal .ps1 to task. Task file format is as below.

```PowerShell
task taskname -Action {
	PowerShell Commands you want to run
}
```

- If you have .ps1 like this code.

```PowerShell
Get-ChildItem
```


- Then task will be like this.

```PowerShell
task taskname -Action {
	Get-ChildItem
}
```

- You can use almost all functions and variables set. Please check vale and valep section about a detail of some functions cannot use in task.

> Note:
> 
> * valentia functions get stored credential before running task, therefore you don't need to create/write credentials in your script.
> * In other word, do not try to get another credential in you script. Especially in "valep" .
