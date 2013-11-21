# Read Me Fast
Valentia is PowerShell deployment tool for Server-Client model.
This module set will optimize your work for deploy Commands or files to remote servers.


# Special Thanks
Valentia inspired from capistrano ( a Ruby deployment tool for Linux) and psake ( a PowerShell build tool).
They are fantastic and awesome tools for automation and DevOps.
Especially psake showed cool way of coding and valentia followed in many points.

Also [psasync](http://newsqlblog.com/category/powershell/powershell-concurrency/) and [Get-NetworkInfo](http://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/) give me inspire to do asynchronous execution.


# Latest Change

## Version 0.3.x

- version : 0.3.3
	
	[ author : guitarrapc ]
	
	[ Nov 15, 2013 ]
	
	* 
	* Added function ```Show-ValentiaConfig```. Now you can check valentia-config.ps1 within console.
	* Added function ```Edit-ValentiaConfig```. Now you can edit valentia-config.ps1 with PowerShell ISE.
	* fix issue 31 : valentia cmdlet will stop with error when trying to run more then 2 whithin same console
	* Enhanced issue 32 : Now you can modify Runspace Pool Size within valentia-config.ps1 


# Basic

## Valid OS and PowerShell Verstion

valentia works with PowerShell Version 3.0 and higher.

|OS|PowerShell Version|
|:----:|:----:|
|Windows 7 |3.0 and higher|
|Windows 8 |3.0 and higher|
|Windows 8.1 |4.0 and higher|
|Windows 2008R2 |3.0 and higher|
|Windows 2012 |3.0 and higher|
|Windows 2012 R2|4.0 and higher|

note : all functions are confirmed with Windows Server 2012 x64 English environment.

### Development Environment

I'm develop Valentia with following environemt.

|OS|PowerShell Version|
|:----:|:----:|
|Windows 8 |3.0 and higher|
|Windows 8.1 |4.0 and higher|
|Windows 2012 |3.0 and higher|

## Prerequisite

Please consider followings before using valentia.

1. Allow ```PowerShell Execution Policy```
2. Set Network Profile not in public.
3. Install Tools using in valentia

#### 1. PowerShell Execution Policy

You can define your PowerShell Commands into scripts which can use in Valentia. However PowerShell default execution Policy don't trust scripts, it is required change Execution Policy from ```Restricted``` to any other. Then you can load PowerShell Scripts using Valentia Task Keyword.

To enable loading your custom PowerShell Scripts, execute following command with Admin elevated PowerShell console.

```PowerShell
Set-ExecutionPolicy RemoteSigned
```

- The default Execution policy of "PowerShell V4 on Windows Server 2012 R2" is ```RemoteSigned```.

#### 2. Network Profile

Valentia is Deployment library with PowerShell. The base of remote connection between Server and Client is PowerShell Remoting. It means you need to enable PSRemoting to use valentia.

Please run following commands to check you network adaptor profile.
```PowerShell
Get-NetConnectionProfile
```
If you find any Network Adaptor showing as **Public** then ```Enable-PSRemoting -Force``` will fail.

To change all the Network adaptor which NetworkCategory from ```Public``` to ```Private``` then run following command with Admin elevated PowerShell 

```PowerShell
Get-NetConnectionProfile | where NetworkCategory -eq "Public" | Set-NetConnectionProfile -NetworkCa
tegory Private
```

#### 3. Tools 

The following tools are used in Valentia. You can ignore them if you don't Valentia Cmdlet which depend on tools.

|Tool|using Valentia Cmdlet|Description|URI|
|:----:|:----:|:----:|:----:|
|Bits Transfer|```Invoke-ValentiaUpload``` & ```Invoke-ValentiaUploadList```|Using for Single and List file transfer. Enable "IIS BITs Transfer" from "Windows Program and freature"|<a href="http://msdn.microsoft.com/en-us/library/bb968799(v=vs.85).aspx" title="Background Intelligent Transfer Service">Background Intelligent Transfer Service</a>|
|FastCopy|```Invoke-ValentiaSync```|Please intstall FastCopyx64 to "C:\Program Files\FastCopy" or configure path to fastcopy.exe with ```valentia-config.ps1```|[Download FastCopy? click here to go HP.](http://ipmsg.org/tools/fastcopy.html)|

# Install valentia module

To use valentia module, please set valentia folder to PowerShell module path. Normally user module path is defined in Environment variables ```PATH``` as ```%homepath%\documents\WindowsPowerShell\Module\```

## 1. Valentia Installation

Valentia written with standard module, thus the only thing required is "set valentia folder into module path or custom path".

#### Using Valentia with Current User only

You can install valentia with running ```install.bat```. This bat file will copy Valentia to user Module Path.

|Module Scope|Copying Module Path|
|:----:|:----:|
|Current User only|```env:USERPROFILE\Documents\WindowsPowerShell\Modules\Valentia```|

#### Using Valentia with All Users

If you you want to use valentia with all users in your machine, then set valentia module folder to Machine Module Path.

if you are using x64 Windows and want to use Valentia with PowerShell x86 then Module path is under SysWOW64.

|Module Scope|Copying Module Path|
|:----:|:----:|
|All Users|```C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Valentia```|
|All Users (x86 for 64bit OS)|```C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Valentia```|

#### Custom Path

If you don't want copy Valentia to any module path but using your custom path, then set Valentia anywhere you want.

|Module Scope|Copying Module Path Sample|
|:----:|:----:|
|Anywhere|```D:\CustomPowerShell\Valentia```|

## 2. Import valentia module

### If you set Valentia in Default PowerShell Module Path

In PowerShell V3.0, all modules located in Module Path will be automatically loaded. You don't need to use ```Import-Modue Valentia``` in this case. Normally default Module Path is defined in Environment variables "PATH".

|Module Scope|Default Module Path|
|:----:|:----:|
|Current user Module Path|env:USERPROFILE\Documents\WindowsPowerShell\Modules|
|Machine level Module Path|C:\Windows\System32\WindowsPowerShell\v1.0\Modules\valentia|
|Machie level (x86 for 64bit OS)|```C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Valentia```|

Valentia Module will automatically import when calling Valentia functions. However if you want to check $valentia variables before running Valentia Cmdlet, then ```Import-Module``` is required.

```PowerShell
Import-Module valentia
```

### If you set Valentia in Custom Path

if you sat module in custom path, then it is required using Import-Module Cmdlet to Import valentia in your PowerShell session.

```PowerShell
cd PathToValentia # the path you set valentia.psm1
Import-Module valentia
```

### Reload initial valentia settings into current PowreShell Session

You can reload Module into current session anytime with following command.

```PowerShell
Import-Module valentia -Force -Verbose
```

# Check Valentia Cmdlets and Alias

After Valentia had sat in Module Path or Imported, you can use Valentia!!

## 1. Valentia Cmdlets

You can check all Valentia Cmdlets by running command.

```PowerShell
Get-command -module valentia
```

Following Cmdlets will be shown.

|CommandType |Name|ModuleName|
|:----|:----|:----|
|Function|    ConvertTo-ValentiaTask|             valentia|
|Function|    Edit-ValentiaConfig|                valentia|
|Function|    Get-ValentiaCredential|             valentia|
|Function|    Get-ValentiaFileEncoding|           valentiav
|Function|    Get-ValentiaGroup|                  valentia|
|Function|    Get-ValentiaRebootRequiredStatus|   valentia|
|Function|    Get-ValentiaTask|                   valentia|
|Function|    Initialize-ValentiaEnvironment|     valentia|
|Function|    Invoke-Valentia|                    valentia|
|Function|    Invoke-ValentiaAsync|               valentia|
|Function|    Invoke-ValentiaClean|               valentia|
|Function|    Invoke-ValentiaCommand|             valentia|
|Function|    Invoke-valentiaDeployGroupRemark|   valentia|
|Function|    Invoke-valentiaDeployGroupUnremark| valentia|
|Function|    Invoke-ValentiaDownload|            valentia|
|Function|    Invoke-ValentiaParallel|            valentia|
|Function|    Invoke-ValentiaSync|                valentia|
|Function|    Invoke-ValentiaUpload|              valentia|
|Function|    Invoke-ValentiaUploadList|          valentia|
|Function|    New-ValentiaCredential|             valentia|
|Function|    New-ValentiaFolder|                 valentia|
|Function|    New-ValentiaGroup|                  valentia|
|Function|    Set-ValentiaHostName|               valentia|
|Function|    Set-ValentiaLocation|               valentia|
|Function|    Show-ValentiaConfig|                valentia|
|Function|   Show-ValentiaGroup|                 valentia|
|Function|    Show-ValentiaPromptForChoice|       valentia|
|Workflow|    Invoke-ValentiaCommandParallel|     valentia|


## 2. Valentia Alias

All Cmdlets have alias to let you use easily.
You can find them as like this.

```PowerShell
Get-Alias | where ModuleName -eq "valentia"
```

Following Alias->Cmdlets will be shown.


|CommandType |DisplayName|ModuleName|
|:----|:----|:----|
|Alias|Clean -> Invoke-ValentiaClean|valentia
|Alias|Cred -> Get-ValentiaCredential|valentia
|Alias|Download -> Invoke-ValentiaDownload|valentia
|Alias|Go -> Set-ValentiaLocation|valentia
|Alias|Initial -> Initialize-ValentiaEnvironment|valentia
|Alias|ipremark -> Invoke-valentiaDeployGroupRemark|valentia
|Alias|ipunremark -> Invoke-valentiaDeployGroupUnremark|valentia
|Alias|Rename -> Set-ValentiaHostName|valentia
|Alias|Sync -> Invoke-ValentiaSync|valentia
|Alias|Target -> Get-ValentiaGroup|valentia
|Alias|Task -> Get-ValentiaTask|valentia
|Alias|Upload -> Invoke-ValentiaUpload|valentia
|Alias|UploadL -> Invoke-ValentiaUploadList|valentia
|Alias|Vale -> Invoke-Valentia|valentia
|Alias|Valea -> Invoke-ValentiaAsync|valentia
|Alias|Valep -> Invoke-ValentiaParallel|valentia

# Environment Setup Commands

Before you start valentia deployment, you should setup both Server and Clients to work PSRemote Connection.

### 1. ```Initialize-ValentiaEnvironment``` : Setup Server

This command will let your Server for valentia remoting.

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

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **

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

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **

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
C:\Deployment\Deploygroup\ *****.ps1
```

Deploy Group file just required to be split by `r`n.

SAMPLE deployGroup input
```
10.0.0.100
10.0.0.101
# 10.0.0.101 <= this line will be remarked as not started with decimal
```

You can create deploy group file in only one command.
Of cource there are several way to create deploygroup file.
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

### 5. ```Invoke-valentiaDeployGroupRemark``` : Remark ipaddress for deploygroup file inside deploygroup

There would be many time to remark some deploy target inside deploygroup file.
This is easy work but boring to check which file contains target deploy ip.

This cmdlet will ease you remark target ipaddresses and check how change.


The cmdlet will search recursible inside deploygroup.

```
C:\Deployment\Deploygroup\**\**\.....*****.ps1
```

SAMPLE deployGroup input
```
10.0.0.100
10.0.0.101
10.0.0.102 <= if you want to remark this line for all the files inside deploygroup folder.
```

Just type as like this.

```PowerShell
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.102 -overWrite -Verbose
```

This will change PowerShell
```
10.0.0.100
10.0.0.101
#10.0.0.102
```

if you just want to check how affect and don't want to replace file, then remove -overwrite switch.

```PowerShell
Invoke-valentiaDeployGroupRemark -remarkIPAddresses 10.0.0.102 -Verbose
```
 

### 6. ```Invoke-valentiaDeployGroupUnremark``` : Unremark ipaddress for deploygroup file inside deploygroup

if you remark ipaddresses in deploygroup file, then you want to unremark it:)
This cmdlet will ease you unremark target ipaddresses and check how change.


The cmdlet will search recursible inside deploygroup.

```
C:\Deployment\Deploygroup\**\**\.....*****.ps1
```

SAMPLE deployGroup input
```
10.0.0.100
10.0.0.101
#10.0.0.102 <= if you want to unremark this line for all the files inside deploygroup folder.
```

Just type as like this.

```PowerShell
Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.102 -overWrite -Verbose
```

This will change PowerShell
```
10.0.0.100
10.0.0.101
10.0.0.102
```

if you just want to check how affect and don't want to replace file, then remove -overwrite switch.

```PowerShell
Invoke-valentiaDeployGroupUnremark -remarkIPAddresses 10.0.0.102 -Verbose
```


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

Of cource you can omit parameter names like this.

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

Of cource you can omit parameter names like this.

```Powershell
Sync C:\Requirements "c:\hoge hoge" new
```

** Adding ```-Verbose``` switch will ease you check how cmdlet working. **
