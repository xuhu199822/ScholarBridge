$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runtimePath = Join-Path $projectRoot 'runtime\llama'
$modelPath = Join-Path $projectRoot 'runtime\Hy-MT2-1.8B-Q4_K_M.gguf'
$serverPath = Get-ChildItem -LiteralPath $runtimePath -Recurse -Filter 'llama-server.exe' | Select-Object -First 1 -ExpandProperty FullName
if (-not $serverPath -or -not (Test-Path -LiteralPath $modelPath)) { throw 'Run tools/download_local.py first.' }
& $serverPath -m $modelPath --host 127.0.0.1 --port 18765 -c 8192 -np 1 -ngl 0 --alias local-translation --log-disable
exit $LASTEXITCODE
