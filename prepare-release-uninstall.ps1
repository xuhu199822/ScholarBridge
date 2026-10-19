$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
try{
    $desktop=Join-Path $projectRoot 'dist\ScholarBridge.exe'
    $active=Get-CimInstance Win32_Process -Filter "Name='ScholarBridge.exe'" | Where-Object {$_.ExecutablePath -eq $desktop -and $_.CommandLine -notmatch '--ime-broker'}
    if($active){throw 'Exit ScholarBridge from its tray menu before uninstalling.'}
    if(Test-Path -LiteralPath (Join-Path $projectRoot 'data\word-web\tls.json')){
        & (Join-Path $PSScriptRoot 'stop-word-web.ps1')
        & (Join-Path $PSScriptRoot 'setup-word-web.ps1') -Uninstall
    }
    # Do not contact another installation's SID-wide broker or terminate user applications.
    $broker=Get-CimInstance Win32_Process -Filter "Name='ScholarBridge.exe'" | Where-Object {$_.ExecutablePath -eq $desktop -and $_.CommandLine -match '--ime-broker'}
    if($broker){
        & (Join-Path $projectRoot 'runtime\node\node.exe') (Join-Path $PSScriptRoot 'stop-translation-broker.mjs')
        if($LASTEXITCODE -ne 0){throw 'Translation broker did not stop safely.'}
    }
    exit 0
}catch{Write-Error $_;exit 1}
