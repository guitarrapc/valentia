#Requires -Version 3.0

param
(
    [parameter(mandatory)]
    [string[]]
    $taskFile = $null
)

# Import-Module PSAWSModule
# Import-Module valentia

# Confirm
$deploygroup = Show-ValentiaPromptForChoice -questions (Show-ValentiaGroup).Name -title ("'{0}' を 実行するグループを選択してください。"　-f $taskFile) -message "アルファベットから対象を選択してね！"

# Free input
if ($deploygroup -eq "InputAny.ps1")
{
    [string[]]$deploygroup = (Read-Host "デプロイグループ対象のIPやホスト名を入力してください。(,区切りで複数入力可能)") -split ","
}

# Run
Write-Host '実行します' -ForegroundColor Cyan

foreach ($task in $taskFile)
{
    valea $deploygroup .\$task -quiet
}