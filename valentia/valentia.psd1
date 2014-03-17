#
# モジュール 'valentia' のモジュール マニフェスト
#
# 生成者: guitarrapc
#
# 生成日: 2014/03/17
#

@{

# このマニフェストに関連付けられているスクリプト モジュール ファイルまたはバイナリ モジュール ファイル。
# RootModule = ''

# このモジュールのバージョン番号です。
ModuleVersion = '0.3.6'

# このモジュールを一意に識別するために使用される ID
GUID = 'f775243e-5ff2-4203-8b5a-44c6449614be'

# このモジュールの作成者
Author = 'guitarrapc'

# このモジュールの会社またはベンダー
CompanyName = 'guitarrapc'

# このモジュールの著作権情報
Copyright = '(c) 2014 guitarrapc. All rights reserved.'

# このモジュールの機能の説明
Description = 'PowerShell Remote deployment library for Windows Servers'

# このモジュールに必要な Windows PowerShell エンジンの最小バージョン
PowerShellVersion = '3.0'

# このモジュールに必要な Windows PowerShell ホストの名前
# PowerShellHostName = ''

# このモジュールに必要な Windows PowerShell ホストの最小バージョン
# PowerShellHostVersion = ''

# このモジュールに必要な Microsoft .NET Framework の最小バージョン
DotNetFrameworkVersion = '4.0'

# このモジュールに必要な共通言語ランタイム (CLR) の最小バージョン
CLRVersion = '4.0.0.0'

# このモジュールに必要なプロセッサ アーキテクチャ (なし、X86、Amd64)
# ProcessorArchitecture = ''

# このモジュールをインポートする前にグローバル環境にインポートされている必要があるモジュール
# RequiredModules = @()

# このモジュールをインポートする前に読み込まれている必要があるアセンブリ
# RequiredAssemblies = @()

# このモジュールをインポートする前に呼び出し元の環境で実行されるスクリプト ファイル (.ps1)。
# ScriptsToProcess = @()

# このモジュールをインポートするときに読み込まれる型ファイル (.ps1xml)
# TypesToProcess = @()

# このモジュールをインポートするときに読み込まれる書式ファイル (.ps1xml)
# FormatsToProcess = @()

# RootModule/ModuleToProcess に指定されているモジュールの入れ子になったモジュールとしてインポートするモジュール
NestedModules = @('valentia.psm1')

# このモジュールからエクスポートする関数
FunctionsToExport = 'ConvertTo-ValentiaTask', 'Edit-ValentiaConfig', 
               'Get-ValentiaCredential', 'Get-ValentiaFileEncoding', 
               'Get-ValentiaGroup', 'Get-ValentiaRebootRequiredStatus', 
               'Get-ValentiaTask', 'Initialize-ValentiaEnvironment', 
               'Invoke-Valentia', 'Invoke-ValentiaAsync', 'Invoke-ValentiaClean', 
               'Invoke-ValentiaCommand', 'Invoke-ValentiaCommandParallel', 
               'Invoke-ValentiaDeployGroupRemark', 
               'Invoke-ValentiaDeployGroupUnremark', 'Invoke-ValentiaDownload', 
               'Invoke-ValentiaParallel', 'Invoke-ValentiaSed', 
               'Invoke-ValentiaSync', 'Invoke-ValentiaUpload', 
               'Invoke-ValentiaUploadList', 'New-ValentiaGroup', 
               'New-ValentiaFolder', 'New-ValentiaDynamicParamMulti', 
               'Ping-ValentiaGroupAsync', 'Set-ValentiaCredential', 
               'Set-ValentiaHostName', 'Set-ValentiaLocation', 'Show-ValentiaConfig', 
               'Show-ValentiaGroup', 'Show-ValentiaPromptForChoice', 
               'Write-ValentiaVerboseDebug'

# このモジュールからエクスポートするコマンドレット
CmdletsToExport = '*'

# このモジュールからエクスポートする変数
VariablesToExport = 'valentia'

# このモジュールからエクスポートするエイリアス
AliasesToExport = 'Task', 'Vale', 'Valep', 'Valea', 'Upload', 'UploadL', 'Sync', 'Download', 'Go', 
               'Clean', 'Reload', 'Target', 'PingAsync', 'Sed', 'ipremark', 'ipunremark', 
               'Cred', 'Rename', 'DynamicParameter', 'Initial'

# このモジュールに同梱されているすべてのモジュールのリスト
# ModuleList = @()

# このモジュールに同梱されているすべてのファイルのリスト
# FileList = @()

# RootModule/ModuleToProcess に指定されているモジュールに渡すプライベート データ
# PrivateData = ''

# このモジュールの HelpInfo URI
# HelpInfoURI = ''

# このモジュールからエクスポートされたコマンドの既定のプレフィックス。既定のプレフィックスをオーバーライドする場合は、Import-Module -Prefix を使用します。
# DefaultCommandPrefix = ''

}

