$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Run with Windows PowerShell 5.1.' }
$projectRoot = Split-Path -Parent $PSScriptRoot
$languages = Get-WinUserLanguageList
$scholar = '0804:{C37D362D-F520-4466-B399-97E6F3208521}{7419958F-C2C1-46B0-A085-D5560C092D52}'
if (-not ($languages.InputMethodTips -contains $scholar)) { throw 'ScholarBridge is absent from the saved user list; no changes made.' }
function Snapshot($list) {
    @($list | ForEach-Object { [ordered]@{LanguageTag=$_.LanguageTag;InputMethodTips=@($_.InputMethodTips);Handwriting=$_.Handwriting;Spellchecking=$_.Spellchecking} }) | ConvertTo-Json -Depth 5 -Compress
}
$before = Snapshot $languages
$defaultBefore = Get-WinDefaultInputMethodOverride | ConvertTo-Json -Compress
$backup = Join-Path $projectRoot ('artifacts\input-list-before-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.clixml')
$languages | Export-Clixml -LiteralPath $backup
Set-WinUserLanguageList -LanguageList $languages -Force
$after = Snapshot (Get-WinUserLanguageList)
$defaultAfter = Get-WinDefaultInputMethodOverride | ConvertTo-Json -Compress
if ($before -ne $after -or $defaultBefore -ne $defaultAfter) { throw ('Language settings changed unexpectedly; inspect backup: ' + $backup) }
Write-Host 'Existing user language list reapplied; language order, input method order and default override unchanged.'
& (Join-Path $PSScriptRoot 'refresh-input-settings.ps1')
