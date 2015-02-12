# Version History
This indicate Version History for valentia.

# Update detail

## Version 0.4.x
====

- version : 0.4.12
	
	[ author : guitarrapc ]
	
	[ Feb 12, 2015 ]
	
	#### Enhancement
	* Now Get-ValentiaSymbolicLink returns SymbolicLink Target Path.

- version : 0.4.11
	
	[ author : guitarrapc ]
	
	[ Dec 11, 2015 ]
	
	#### Enhancement
	* Added WorkingDirectory support for ```Set-ValentiaScheduledTask```
	* Added Verbose Stream support for ```Get/Set/Test-ValentiaACL```

	#### Unremarkable change
	* Hide loaded path from valentia.ps1 
	
- version : 0.4.10
	
	[ author : guitarrapc ]
	
	[ Nov 28, 2014 ]
	
	#### Enhancement
	* ```-Strict``` parameter([bool]) was added to support UserName strict Checking.

	#### Bug fix
	* fix Bug for Get/Set/Test-ValetniaACL. Now ACL detect collect.

	#### Unremarkable change
	* Installer update. 

- version : 0.4.9
	
	[ author : guitarrapc ]
	
	[ Oct 17, 2014 ]
	
	#### Bug fix
	* fix UseSSL = $true in Config not working
	* fix Windows Version check for Firewall Cmdlet in ```New-ValentiaPSRemotingFirewallRule```

----

- version : 0.4.8
	
	[ author : guitarrapc ]
	
	[ Oct 16, 2014 ]
	
	#### Enhancement
	* [Issue #72](https://github.com/guitarrapc/valentia/issues/72) : Added ```-UseSSL``` switch to ```Invoke-Valentia``` and ```Invoke-ValentiaAsync``` functions. This allows you to use Valentia in Microsoft Azure Environment.

	#### Bug fix
	* psd1 was not correct as it expose unnessesary variables and functions. Now these are capsulled.
	* Fix Nuget Init.ps1 always install valentia when opbing project  

	#### Unremarkable change
	* Fix ```-Quiet``` switch check 

----

- version : 0.4.7
	
	[ author : guitarrapc ]
	
	[ Oct 9, 2014 ]
	
	#### Enhancement
	* Added ```Set-ValentiaSymbolicLink``` functionality to create SynbolicLink against None Exist Path.
	* Added ```Reset-ValentiaConfig``` to reload config.
	* Added ```Backup-ValentiaConfig``` to Backup current configuration.
	* Added ACL functions ```Get-ValentiaACL```,  ```Set-ValentiaACL```, ```Test-ValentiaACL```. This enable you to control NTFS ACL.
	* [Issue #67](https://github.com/guitarrapc/valentia/issues/67) Enhanced for Multiple Task Scheduler settings.
	* ```Set-ValentiaScheduledTask``` now not mandatory for Credential parameter in some situations.
	* ```Set-ValentiaScheduledTask``` now supports **Compatibility**, **Force** and **ExecutionTimeLimit** parameters.
	* Added ```Remove-ValentiaScheduledTask``` to remove ScheduledTask.
	* Added [Onlinehelp](https://github.com/guitarrapc/valentia/wiki/TaskScheduler-Automation) for ```Set-ValentiaScheduledTask``` to 
	*  Support ```-Recurse``` parameter for ```Invoke-ValentiaDeployGroupRemark```. Now you can choose path and only effect it, means not deep inside the path.
	*  Added ```Added Enable-ValentiaScheduledTaskLogSetting```, ```Disable-ValentiaScheduledTaskLogSetting``` to control ScheduledTask Log.
	* Speedup Importing Module. Now all functions are included in single file, it only takes 1sec to import. (Previously 10sec)
	* Speedup Installer for Module.

	#### Bug fix
	* Fix ```Invoke-ValentiaAsync``` had memory leak since v0.4.3 had been fixed.
	* Fix ```Set-ValentiaScheduledTask``` Task Path not working.
	* Fix ```Initialize-ValentiaEnvironment``` validation

	#### Unremarkable change
	* Folder Structure Capitalize (no effect)
	* Added Internal utility functions. 
	* Divide Type to each ps1
	* Re-factor Code.

----

- version : 0.4.6
	
	[ author : guitarrapc ]
	
	[ Aug 12, 2014 ]
	
	#### Enhancement
	* Added SymbolicLink Functions without using mklink. ```Get-ValentiaSymbolicLink```, ```Remove-ValentiaSymbolicLink```, ```Set-ValentiaSymbolicLink``` is now available.
	* Added TaskScheduler functions. Now you can create TaskScheduler easily by passing Hashtable style.

	#### Breaking Changes
	* Change TaskParameter from String[] to hashtable for ```Invoke-Valentia``` and ```Invoke-ValentiaAsync```.
		* This cause breaking change to use local variable in valentia  scriptblock.
		* Before : $args[0]
		* After  : $args[0].Values

----

- version : 0.4.5
	
	[ author : guitarrapc ]
	
	[ Aug 1, 2014 ]
	
	#### Enhancement
	* Added Credential Parameter for ```Invoke-ValentiaDownload```, ```Invoke-Valentia```, ```Invoke-ValentiaAsync```, ```Invoke-ValentiaSync```, ```Invoke-ValentiaUpload```, ```Invoke-ValentiaUploadList```

	#### Changes
	* Now ```Invoke-Valentia``` and ```Invoke-ValentiaAsync``` Prereqisite action is sharing.

	#### Bug fix
	* Fix ```Invoke-ValentiaAsync``` had memory leak since v0.4.3 had been fixed.

----

- version : 0.4.3
	
	[ author : guitarrapc ]
	
	[ Jul 31, 2014 ]
	
	#### Enhancement
	* Initialize-ValentiaEnvironment now supports Credential parameter
	* Replace Bits Transfer to HttpClient for RemoteInstallation.
	* Added Password Encrypt / Decrypt through Certificate pfx/cert
	* Added Elevated check for CertStoreLocation "LocalMachine"
	* Added Get-ValentiaComputerName functions to get/set current ComputerName  
	* Added Watch-ValentiaPingAsyncReplyStatus
	* Add Get-ValentiaHostEntryAsync to Retrieve DNS to IPAddress Entry
	* Add $valentia.Result to preserve last command result.
	* Support for ErrorActionPreference. Now default is Continue for Invoke-Valentia and Invoke-ValentiaAsync. You can set as Stop by -ErrorAction Stop.
	* Now you can filter each host result by ``` $valentia.Result.Where{$_.Success -eq $true} 
	* You can see progress for Invoke-ValentiaAsync in log file until execution finished.

	#### Changes
	* Remove unused command for public output function
	* installer change
	* change Set-ValentiaComputerName to Rename-ValentiaComputerName
	* Re-factor Code

	#### Bug fix
	* Now Result will show Correct Json format as {host : HostName ; value : Value}. Previously it was Hostname : Value.

----

- version : 0.4.0
	
	[ author : guitarrapc ]
	
	[ May 16, 2014 ]
	
	#### Enhancement
	* Get-ValentiaGroup now supports Pipeline input.
	* Now valentia OS User Initialization can control userflag in valentia-config.ps1
	* Now valentia supports ActiveDirectory User authentication when create Local User in domain joined server.
	* Enhanced [#60](https://github.com/guitarrapc/valentia/issues/60), now valentia config will move to %AppData%\valentia.
	* Now CredSSP is supported. Change Authentication mode in valentia-config.ps1. Default is default.$valentia.Authentication
	* Added Certificate import/export/show functions. ```Export-ValentiaCertificate.ps1```, ```Import-ValentiaCertificate.ps1``` and ```Show-ValentiaCerticate```
	* PFX is supported as well as Cert.
	* Set-RestictionMode support in ```Initialize-ValentiaEnvironemt```
	* Support DynamicParam for Initial Value and Type with ```New-ValentiaDynamicParamMulti```
	* Add NuGet package support.
	
	#### Changes
	* BranchPath now change to enum. Now you can call by [ValentiaBranchPath]
	* valentia functions now move into valentia\functions\ with role of functions.
	* Now installer will not overwrite exsiting configuration.
	* Move Installer path from root to valentia\Tools
	* Now FastCopy path is change to chocolatey installation path.

	#### Bug fix
	* Correct some error messages
	* fix installer issue.
	* change Firewall rule name to Windows Standard

----

## Version 0.3.x
====

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
	 
----

- version : 0.3.6
	
	[ author : guitarrapc ]
	
	[ Feb 13, 2014 ]
	
	* fix issue #56 : Now Invoke-ValentiaAsync runs quiet fast almost same as Invoke-Valentia.

----

- version : 0.3.5
	
	[ author : guitarrapc ]
	
	[ Feb 13, 2014 ]
	
	* fix issue #54 : Invoke-Valentia waiting for job finish before passing next command to jobs.
	* tune RunSpacePool configutaion #55 : Check preferred number of RunSpaces to execute most efficiently
	* enhanced issue #52 : change Ping-ValentiaGroupAsync from PSEventJob to System.Threading.Tasks.task

----

- version : 0.3.4
	
	[ author : guitarrapc ]
	
	[ Fev 4, 2014 ]
	
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

----

- version : 0.3.3
	
	[ author : guitarrapc ]
	
	[ Nov 15, 2013 ]
	
	* Added function ```Show-ValentiaConfig```. Now you can check valentia-config.ps1 within console.
	* Added function ```Edit-ValentiaConfig```. Now you can edit valentia-config.ps1 with PowerShell ISE.
	* fix issue 31 : valentia cmdlet will stop with error when trying to run more then 2 whithin same console
	* Enhanced issue 32 : Now you can modify Runspace Pool Size within valentia-config.ps1 

----

- version : 0.3.2
	
	[ author : guitarrapc ]
	
	[ Nov 3, 2013 ]
	
	* Split all valentia functions to each .ps1, now valentia can manage each of function more easier.
	* Added function ```Show-ValentiaGroup```. Want to check deploygroup files in deploygroup branch folder
	* fix issue 19 : Host message show as object[] when upload, and upload list item was multiple.
	* fix issue 20 : Can not execute Initialize-ValentiaEnvironment with not Server OS.
	* fix issue 21 : New-ValentiaFolder could not create branch folder as configured.
	* fix issue 22 : Result compress result as Format-Table when ScriptBlock or Task output as format-table.

----

- version : 0.3.1
	
	[ author : guitarrapc ]
	
	[ Oct 4, 2013 ]
	
	* Added TaskParameter parameter for Invoke-Valentia, Invoke-ValentiaParallel, Invoke-ValentiaAsync. Now you can use $args[0] ...[x] to pass variables into task when execute valentia command. 
	* Added Invoke-valentiaDeployGroupRemark, Invoke-valentiaDeployGroupUnremark to ease you remark, mark deploy group ipaddresses in one command.
	* Exmaple for Invoke-valentiaDeployGroupRemark, Invoke-valentiaDeployGroupUnremark is added to README.
	* fix link to fastcopy.
	* fix Get-ValentiaGroup parameter of deployfolder was mandatory. It supposed to be not mandatory.
	* fix some messages on Write-Verbose and Write-Warning. 
	* little configuration for valentia-config.ps1

----

- version : 0.3.0
	
	[ author : guitarrapc ]
	
	[ Sep 24, 2013 ]
	
	* Open to public
	* Get-ValentiaGroup now supports multiple input, previously only 1 input was allowed. Now you can type like valea 192.168.0.1,192.168.0.2 {hostname}
	* Now Invoke-ValentiaDownload had added to copy item from clients to server
	* Minor Change valep error variable from array to list (will do for valea and vale)

----

## Version 0.2.x
====

- version : 0.2.8
	
	[ author : guitarrapc ]
	
	[ July 29, 2013 ]
	
	* Changed New-ValentiaCredential to save credential from c:\Deployment\bin\$valentia.User to c:\Deployment\bin\CurrentUser\$valentia.User
	* Get-ValentiaCredential also changed to read credential from c:\Deployment\bin\$valentia.User to c:\Deployment\bin\CurrentUser\$valentia.User 
	* With this change you can use valentia with multiple user like, administrator and user.
	* - Note you should create credential for each user who want to use valentia.
	* - Recommend to put valentia at C:\Users\Administrator\Documents\WindowsPowerShell\Modules to avoid saving to each user's module path.

----

- version : 0.2.7
	
	[ author : guitarrapc ]
	
	[ July 24, 2013 ]
	
	* Added -Force switch for Invoke-ValentiaDownload
	* As Bits-Transfer cmdlets could stopped with target file had already handled by other process, force switch will ignore handle and copy.
	* 1. -Force cmdlet using not Bits-Transfer but Copu-Item -Force with credential smb and cim

----

- version : 0.2.6
	
	[ author : guitarrapc ]
	
	[ July 24, 2013 ]
	
	* Added $valentia.deployextention vatiable.
	* 1. now you can assign your required extention for deploygroup file. (default .ps1)
	* Changed Get-ValentiaGroup function.
	* 1. Now this function can read string passed as IPAddress or HostName, and deploygroup file name.
	* 2. Now DeployGroup must pass extention with. (previously you can omit extention, but now fullname is required.)
	* 3. Now each functions DeployGroup parameter is changed from [string] to [string[]]

----

- version : 0.2.5
	
	[ author : guitarrapc ]
	
	[ July 22, 2013 ]
	
	* Added Dispose Runspace for Invoke-ValentiaResult function
	* Added Close RunSpace before dispose for Invoke-ValentiaResult function
	* Remove Json fix as C# could not read

----

- version : 0.2.4
	
	[ author : guitarrapc ]
	
	[ July 22, 2013 ]
	
	* Fixt Invoke-ValentiaDownload and Invoke-ValentiaUpload to retrive correct status when sending as Async.
	* Fix Invoke-ValentiaUpload, now it can send multiple files.

----

- version : 0.2.3
	
	[ author : guitarrapc ]
	
	[ July 19, 2013 ]
	
	* Added Invoke-ValentiaDownload (Alis : Download) function. Now you can download specific file, or Directory from -SourcePath to -DesctinationPath
	* Destination Path will create DeployMemer foler
	* Correct miss type in Invoke-ValentiaUpload function

----

- version : 0.2.2
	
	[ author : guitarrapc ]
	
	[ July 16, 2013 ]
	
	* Change Pool size for valea from 100 to 10.
	* Added Warning Messages.
	* Add functions

----

- version : 0.2.1
	
	[ author : guitarrapc ]
	
	[ July 15, 2013 ]
	
	* Added Switch to uploadL, now uploading files to each host (Not Sync Folder) is brilliantly inroved performance. 
	* 10host for 4 files was :
	* 1. 22 x 4 sec with upload
	* 2. 22 sec with uploadL
	* 3. 05 sec with uploadL -Async
	* Added Deploy task and others on example
	* Change deploy bat execution from vale to valea
	
----

- version : 0.2.0
	
	[ author : guitarrapc ]
	
	[ July 14, 2013 ]
	
	* Added Invoke-ValentiaAsync function series. Now Valentia can execute task to remote Asynchronously. (MultiThread)
	* You can execute Invoke-ValentiaAsync with valea alias.
	* Now we have 3 execution cmdlet, 
	* 1. vale (sequencial job execution. will be x time with number of hosts. Can use with C# and PowerShell.exe)
	* 2. valep (Parallel concurrent workflow execution. Slitly fast but Cannot use with C#. You can use with PowerShell.exe)
	* 3. valea (Asynchronous concurrent multiThread execution. Slitly fast and ca use with C# and PowerShell.exe)
	* Added catch error with Sync function.
	* Added obtain dllProductversion with vale, valep and valea when loading task file. (will not execute with scriptblock.)
	* Added obtain result with vale, valep, valea amd Sync.
	* Added dllProductVersionDetail with Logout.
	* Added help syntax into some functions.

----

## Version 0.1.x
====

- version : 0.1.7
	
	[ author : guitarrapc ]
	
	[ July 05, 2013 ]
	
	* Added Log output for Sync, upload, uploadl cmdlet.
	* Added Error catch place and move result section from catch to finally
	* fix bug in upload
	* fix bug in uploadL
	* fix bug in Sync

----

- version : 0.1.6
	
	[ author : guitarrapc ]
	
	[ July 04, 2013 ]
	
	* Added Log output for vale command about command detail.
	* Change Host Display Order for valep and vale. Now you can check each copmmand result inside warning and error line. It will ease you check what is the host for result.
	* valep output error derails in tmppath (default : "C:\Windows\Temp\valeptmp.log") for temporary and be deleted at end of valep. log format is compress Json.
	* Now Valentia.Context issue of remaining past time command variables are corrected. clean function (Get-ValentiaClean) sat at end of each valentia cmdlet. This will execute $valentia.context.Clear().
	* Now SuccessStatus and ErrorMessageDetail variables are included into $valentia.context.taskkey @{}. This allow valentia variables keep in clean.

----

- version : 0.1.5
	
	[ author : guitarrapc ]
	
	[ July 04, 2013 ]
	
	* Added Log output for valep command about command detail.
	* Added Exception for Task read.
	* Now Log format is fixed.

----

- version : 0.1.4
	
	[ author : guitarrapc ]
	
	[ July 04, 2013 ]
	
	* Added Log out put for valep command.
	* Added log folder create for New-DeproyGroup.
	* Added NoReboot, ForceReboot switch to Initialize-ValentiaEnvironment for reboot action without prompt.
	* Added function to change WSMan default ShellsPerUser from 25 to 100, but not dramatically changed limit of PowerShell Remote Session threadhold.
	* Now Concurrency limit issue will be taken care. The issue was powershell remote session could not establish when concurrency session is 25 or more.
		Added Get-WSManInstance check for valep to retrieve current connection is neary limit or not.
		Threadhold is 25 and checkin at greater equal 22. if 22 or more than restart target host WinRM service to reset concurrency.
	* Changed ValentiaCommandParallel to output result.
	* Changed Get-ValentiaGroup to output Result.
	* Replace all Write-Host with other Write cmdlet. Now you can call valentia cmdlets from workflow, or C# or any other processes through PowerShell runspace.

----

- version : 0.1.3
	
	[ author : guitarrapc ]
	
	[ June 27, 2013 ]
	
	* Added Set-ValentiaHostName function to set Server Hostname.
	* Added Get-ValentiaRebootRequiredStatus to get Reboot pending status
	* Added Set-ValentiaHostName and Get-ValentiaRebootRequiredStatus to Initialize-ValentiaEnvironment function
	* Disable Get-ValentiaClean on End of Set-ValentiaOSUser function

----

- version : 0.1.2
	
	[ author : guitarrapc ]
	
	[ June 26, 2013 ]
	
	* Added Disable-ValentiaEnhancedIESecutiry function and run in Initialize-ValentiaEnvironment.
	* Now Enhanced Security for InternetExplorer will be disabled in initial setup. (This required to download files)
	* Correct -Server swtich for Initialize-ValentiaEnvironment.
	* Now secure pass file will be created/save when running Initialize-ValentiaEnvironment. (Only for Server switch not for Client.)
	* Add explanation in ReadMeFast for Initialize-ValentiaEnvironment new swtich "-NoPassSave".
	* Devide Readme and VersionHistory. Now only latest changes will be written in Readme, and all history will keep in VersionHistory.

----

- version : 0.1.1
	
	[ author : guitarrapc ]
	
	[ June 25, 2013 ]
	
	* In publish stage
	* fix credential issue for valep. Previously valep could not use credential. Now you can authorize with credential you sat with New-ValentiaCredential cmdlets.
	* fix uploadL to run with each deploygroup.
	* Public cmdlet Get-ValentiaGroup are changed from private.
	* Added elevated check function as Test-Elevated.
	* Added New-ValentiaPSRemotingFirewallRule Cmdlet to enable PowerShell Remote Connection Port.
	* Nomore Initialize-ValentiaServer and Initialize-ValentiaClient but changed to Initialize-ValentiaEnvironment.
	   (Initialize-ValentiaEnvironment can choose "-Server" or "-Client" settings with switch. Also  you can skip deploy OS user setup by "-NoOSUser" switch.)

-----

- version : 0.1.0

	[ author : guitarrapc ]
	
	[ June 24, 2013 ]
	
	* Initial release.
	* Not in publish stage.