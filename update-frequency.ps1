$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$hostExe=Join-Path $projectRoot 'dist\ScholarBridge.RimeHost.exe'
$shared=Join-Path $projectRoot 'runtime\ime\shared'
$schema=Join-Path $shared 'scholar_pinyin.schema.yaml'
$lua=Join-Path $shared 'lua\scholar_frequency.lua'
$backup=Join-Path $projectRoot ('artifacts\frequency-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
$node=Join-Path $projectRoot 'runtime\node\node.exe'
if(-not (Test-Path -LiteralPath $node)){$node=(Get-Command node -ErrorAction Stop).Source}
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item -LiteralPath $schema -Destination (Join-Path $backup 'scholar_pinyin.schema.yaml')
$hadLua=Test-Path -LiteralPath $lua
if($hadLua){Copy-Item -LiteralPath $lua -Destination (Join-Path $backup 'scholar_frequency.lua')}
& $node (Join-Path $PSScriptRoot 'stop-rime.mjs')
if($LASTEXITCODE -ne 0){throw 'Pinyin service did not stop; no configuration changed.'}
# Allow the acknowledged service to finish flushing its own learning database.
$owned=Get-CimInstance Win32_Process -Filter "Name='ScholarBridge.RimeHost.exe'" | Where-Object {$_.ExecutablePath -eq $hostExe}
foreach($item in $owned){$process=Get-Process -Id $item.ProcessId -ErrorAction SilentlyContinue;if($process -and -not $process.WaitForExit(5000)){throw 'Pinyin service has not exited; no configuration changed.'}}
try{
    Copy-Item -LiteralPath (Join-Path $projectRoot 'ime\data\scholar_pinyin.schema.yaml') -Destination $schema
    New-Item -ItemType Directory -Force (Split-Path -Parent $lua)|Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'ime\data\lua\scholar_frequency.lua') -Destination $lua
    $deploy=Start-Process -FilePath $hostExe -ArgumentList '--deploy' -WindowStyle Hidden -Wait -PassThru
    if($deploy.ExitCode -ne 0){throw 'Updated schema deployment failed.'}
}catch{
    Copy-Item -LiteralPath (Join-Path $backup 'scholar_pinyin.schema.yaml') -Destination $schema
    if($hadLua){Copy-Item -LiteralPath (Join-Path $backup 'scholar_frequency.lua') -Destination $lua}
    $restore=Start-Process -FilePath $hostExe -ArgumentList '--deploy' -WindowStyle Hidden -Wait -PassThru
    Start-Process -FilePath $hostExe -ArgumentList '--serve' -WindowStyle Hidden
    throw
}
Start-Process -FilePath $hostExe -ArgumentList '--serve' -WindowStyle Hidden
Write-Host 'Frequency-first candidates deployed. Existing learning dictionaries and input-method registration preserved.'
