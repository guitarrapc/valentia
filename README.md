# Read Me Fast
Valentia is PowerShell deployment tool for Server-Client model.
This module set will optimize your work for deploy Commands or files to remote servers.


# Special Thanks
Valentia inspired from [capistrano](https://github.com/capistrano/capistrano) and [psake](https://github.com/psake/psake). They are fantastic and awesome tools for automation and DevOps. Especially psake showed cool way of coding and valentia followed in many points. Also [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) and [Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/) give me inspire to do asynchronous execution.


# Latest Change

- version : 0.3.6
	
	[ author : guitarrapc ]
	
	[ Feb 13, 2013 ]
	
	* fix issue #56 : Now Invoke-ValentiaAsync runs quiet fast almost same as Invoke-Valentia.

	
# Valid OS and PowerShell Verstion

|OS|PowerShell|
|----|----|
|Windows 7 SP1  |PowerShell V3.0 and higher|
|Windows 8      |PowerShell V3.0 and higher|
|Windows 8.1    |PowerShell V4.0 and higher|
|Windows 2012   |PowerShell V3.0 and higher|
|Windows 2012 R2|PowerShell V4.0 and higher|

#### NOTE: All functions are confirmed with Windows Server 2012 x64 English environment.


# Prerequisite

- You need to install followings to use valentia file transfer.

|#|Description|Note|
|----|----|----|
|1. |Install "FastCopy" to Sync Folders. (please intstall FastCopyx64 to "C:\Program Files\FastCopy")|[Download FastCopy?](http://ipmsg.org/tools/fastcopy.html)|
|2. |Make sure you can execute PowerShell Script with Execution Policy. To enable Execution Policy then run following command with Admin elevated PowerShell.|```Set-ExecutionPolicy RemoteSigned```|


# Easy Install !!

- Let's start install valentia now, Open PowerShell or Command prompt, paste the text below and press Enter.

||
|----|
|**powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((irm 'https://api.github.com/repos/guitarrapc/valentia/contents/valentia/RemoteInstall.ps1').Content))).Remove(0,1)"**|

After the installation complete, you will find valentia installed into your user's Module folder.

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\Modules
```

## Custom Install

### Local Installation for user
 
- If Remote installation are not allowed in your environment, set valentia in any path then you can install valentia localy with run ```install.bat```,  this bat file copy valentia to user module path 

```PowerShell
$env:USERPROFILE\Documents\WindowsPowerShell\Modules
```

### Use valentia for all users.

- In case you want to use valentia with all users, then set valentia module folder to:

```
C:\Windows\System32\WindowsPowerShell\v1.0\Modules\valentia
```

## Import valentia module

- In PowerShell V3.0, all modules located in default Module Path will be automatically search and loaded before starting script.

- If you sat module into custom path, means not default Module Path, PowerShell will not automatically load yout module. In this case, please use Import-Module cmdlet in where ```valentia.psd1``` locating.

```PowerShell
cd "move to custom path you sat valentia.psd1"
Import-Module valentia
```

- While valentia sat in standard Module Path, described in "Easy Install", you don't need to import manually. However ```Import-Module valentia``` will import $valentia variables, and it will be help you some.

```PowerShell
Import-Module valentia
```

# valentia functions

- You can see valentia functions by following command.

```PowerShell
Get-command -module valentia
```

- Following functions will be shown.

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

# valentia Alias

- valentia functions have Alias to let you use it easir, you can find them as like this.

```PowerShell
Get-Alias | where ModuleName -eq "valentia"
```

- This show alias defined in valentia

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


## 2. valep : PowerShell WorkFlow InlineScript exection.

> **valep** is Alias of ```Invoke-ValentiaParallel```. This will execute Command to deploy group as PowreShell WorkFlow.
> This function have limitation of PSWorkflow as it can only execute 5 commands at once, next 5 will execute when previous set was completed.
> However if command execute in same PSHost process then valep can be fastest way of execution. It means if valep use same session as previous.

You have 2 choice executing command to host.

|#|Run|Expression|
|----|----|----|
|1.|ScriptBlock|```valep Deploygroup {ScriptBlock}```|
|2.|Task File|```valep DeployGroup .\Taskfile.ps1```|

#### NOTE: You can not call ```valep``` from C# calling valentia. This is limitation of PSWorkflow.


## 3. valea : Asynchronous RunSpace Command invokation.

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


# Environment Setup Commands

- Before you start valentia deployment, you should setup both Server and Clients to work PSRemote Connection.

### 1. Initialize-ValentiaEnvironment : Setup Server

- This command will let your Server for valentia remoting.

```text
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
```
	
- Once ran this command, You will got prompt for secret password of "OS User" (in default is ec2-user).

```PowerShell
Initialize-ValentiaEnvironment -Server -TrustedHosts "*"
```

- you can omit ```-Server``` and ```-TrustedHosts "*"``` as it were default 

```PowerShell
Initialize-ValentiaEnvironment
```

- When Credential prompt was display input password in masked read line, then OS user (in default ec2-user) will be created and all PSRemote session to all hosts are enabled.
- Also trying to save password in secdure stirng in default, input deploy user password again.


- If you want to restrict Trusted Hosts, you can use -TrustedHosts parameter to select. 

ex) restrict to 10.0.0.0
```PowerShell
Initialize-ValentiaServer -TrustedHosts "10.0.0.0"
```

- If you want setup without OS User setup? then add -NoOSUser switch. 

```PowerShell
Initialize-ValentiaEnvironment -Server -TrustedHosts "*" -NoOSUser
```

- ServerOnly : If you want setup without OS User setup and Save Credentail? then add -NoPassSave switch.

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


### 3. New-ValentiaCredential : Create New Credential secure file

- Following command will make secure string file to save your credential.

> If you ran Initialize-ValentiaServer without -NoSavePass switch, then you can skip this section.
> 
> However if you want to revise saved secure Password, then use this function to revise save file.


```PowerShell
New-ValentiaCredential
```

- or you can select user for credential.

```PowerShell
New-ValentiaCredential -User hogehoge
```

> NOTE: Once you execute command, you will got prompt to save secure strings of user.
> 
> Default user is sat as ec2-user, it will use if no -user had input.


### 4. Initialize-ValentiaGroup : Create New deploygroup file

- To execute deployment command to multiple hosts, you don't need to input hosts everytime. Just list them up in file.
- The file you specified will be output in following path.

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

### 5. Invoke-valentiaDeployGroupRemark : Remark ipaddress for deploygroup file inside deploygroup

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
 

### 6. Invoke-valentiaDeployGroupUnremark : Unremark ipaddress for deploygroup file inside deploygroup

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
