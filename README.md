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

- version : 0.3.2
	
	[ author : guitarrapc ]
	
	[ Nov 3, 2013 ]
	
	* Split all valentia functions to each .ps1, now valentia can manage each of function more easier.
	* Added function ```Show-ValentiaGroup```. Want to check deploygroup files in deploygroup branch folder
	* fix issue 19 : Host message show as object[] when upload, and upload list item was multiple.
	* fix issue 20 : Can not execute Initialize-ValentiaEnvironment with not Server OS.
	* fix issue 21 : New-ValentiaFolder could not create branch folder as configured.
	* fix issue 22 : Result compress result as Format-Table when ScriptBlock or Task output as format-table.

	
# Valid OS and PowerShell Verstion

valentia works with PowerShell Version 3.0 and higher.
I'm developing with Windows 8, Windows 8.1 and Windows 2012.
Supporting Operating System are...

- Windows 7 (with PowerShell V3.0 and higher)
- Windows 8 (with PowerShell V3.0 and higher)
- Windows 8.1 (with PowerShell V4.0 and higher)
- Windows 2012 (with PowerShell V3.0 and higher)
- Windows 2012 R2 (with PowerShell V4.0 and higher)

note : all functions are confirmed with Windows Server 2012 x64 English environment.


# Prerequisite

You need to install followings to use valentia file transfer.

1. Enable "IIS BITs Transfer" for single and List file transfer from "Windows Program and freature"
2. Install "FastCopy" to Sync Folders. (please intstall FastCopyx64 to "C:\Program Files\FastCopy")
	- [Download FastCopy? click here to go HP.](http://ipmsg.org/tools/fastcopy.html)
3. Make sure you can execute PowerShell Script with Execution Policy. To enable Execution Policy then run following command with Admin elevated PowerShell.
	- ```Set-ExecutionPolicy RemoteSigned```

# Install valentia module

To use valentia module, please set valentia folder to 

```PowerShell
%homepath%\documents\WindowsPowerShell\Module\
```

Valentia written with standard module so you don't need to install it but just required to sat valentia folder into module path or custom path.

You can install valentia with ```run install.bat```. This bat file will copy valentia to module path ```env:USERPROFILE\Documents\WindowsPowerShell\Modules```

Or if you want to use valentia with all user, then set valentia module folder to:

```PowerShell
C:\Windows\System32\WindowsPowerShell\v1.0\Modules\valentia
```

Else place anywhere you want.

# Import valentia module

In PowerShell V3.0, all modules located in default psmodulepath will be automatically loaded.

if you sat module in custom path, then use Import-Module Cmdlet.

```PowerShell
cd "move to custom path you sat valentia"
Import-Module valentia
```

If you sat valentia in standard psmodule path described in "Install valentia", you don't need manually import module, but you can do it.

```PowerShell
Import-Module valentia
```

or check detail with following.

```PowerShell
Import-Module valentia -Verbose
```

# valentia Cmdlets

You can see valentia Cmdlets by following command.

```PowerShell
Get-command -module valentia
```

Following Cmdlets will be shown.

```PowerShell
CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        Get-ValentiaCredential                             valentia
Function        Get-ValentiaGroup                                  valentia
Function        Get-ValentiaModuleReload                           valentia
Function        Get-ValentiaRebootRequiredStatus                   valentia
Function        Get-ValentiaTask                                   valentia
Function        Initialize-valentiaEnvironment                     valentia
Function        Invoke-Valentia                                    valentia
Function        Invoke-ValentiaAsync                               valentia
Function        Invoke-ValentiaClean                               valentia
Function        Invoke-ValentiaCommand                             valentia
Function        Invoke-valentiaDeployGroupRemark                   valentia
Function        Invoke-valentiaDeployGroupUnremark                 valentia
Function        Invoke-ValentiaDownload                            valentia
Function        Invoke-ValentiaParallel                            valentia
Function        Invoke-ValentiaSync                                valentia
Function        Invoke-ValentiaUpload                              valentia
Function        Invoke-ValentiaUploadList                          valentia
Function        New-ValentiaCredential                             valentia
Function        New-ValentiaFolder                                 valentia
Function        New-ValentiaGroup                                  valentia
Function        Set-ValentiaHostName                               valentia
Function        Set-ValentiaLocation                               valentia
Function        Show-ValentiaGroup                                 valentia
Workflow        Invoke-ValentiaCommandParallel                     valentia
```

All Cmdlets have alias to lket you use easily.
You can find them as like this.


```PowerShell
Get-Alias | where ModuleName -eq "valentia"
```

This show alias defined in valentia

```PowerShell
CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Alias           Clean -> Invoke-ValentiaClean                      valentia
Alias           Cred -> Get-ValentiaCredential                     valentia
Alias           Download -> Invoke-ValentiaDownload                valentia
Alias           Go -> Set-ValentiaLocation                         valentia
Alias           Initial -> Initialize-valentiaEnvironment          valentia
Alias           ipremark -> Invoke-valentiaDeployGroupRemark       valentia
Alias           ipunremark -> Invoke-valentiaDeployGroupUnremark   valentia
Alias           Reload -> Get-ValentiaModuleReload                 valentia
Alias           Rename -> Set-ValentiaHostName                     valentia
Alias           Sync -> Invoke-ValentiaSync                        valentia
Alias           Target -> Get-ValentiaGroup                        valentia
Alias           Task -> Get-ValentiaTask                           valentia
Alias           Upload -> Invoke-ValentiaUpload                    valentia
Alias           UploadL -> Invoke-ValentiaUploadList               valentia
Alias           Vale -> Invoke-Valentia                            valentia
Alias           Valea -> Invoke-ValentiaAsync                      valentia
Alias           Valep -> Invoke-ValentiaParallel                   valentia
```


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
