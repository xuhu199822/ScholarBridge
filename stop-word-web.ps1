$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$pidFile=Join-Path $projectRoot 'data\word-web\server.pid'
if(-not(Test-Path -LiteralPath $pidFile)){Write-Host 'No running sidebar PID recorded.';exit 0}
$serverId=[int](Get-Content -LiteralPath $pidFile)
$server=Get-CimInstance Win32_Process -Filter "ProcessId=$serverId"
$expected=Join-Path $projectRoot 'word-web\server.mjs'
if(-not($server -and $server.CommandLine.Contains($expected) -and $server.Name -eq 'node.exe')){Write-Host 'Recorded server is not running; no process stopped.';exit 0}
$session=Invoke-RestMethod -Uri 'https://localhost:18766/api/session' -TimeoutSec 5
Invoke-RestMethod -Uri 'https://localhost:18766/api/shutdown' -Method Post -Headers @{'X-Scholar-Token'=$session.token} -TimeoutSec 5 | Out-Null
Write-Host 'Word sidebar stopped. Shared input-method translation service preserved.'
