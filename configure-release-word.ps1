$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
try{
    & (Join-Path $PSScriptRoot 'setup-word-web.ps1')
    if($LASTEXITCODE -and $LASTEXITCODE -ne 0){throw 'Word registration failed.'}
    & (Join-Path $PSScriptRoot 'start-word-web.ps1')
    if($LASTEXITCODE -and $LASTEXITCODE -ne 0){throw 'Word service start failed.'}
    Write-Host 'Word configured. Save documents, fully quit Word and reopen it. Open Home > Add-ins > Developer Add-ins > ScholarBridge.'
    exit 0
}catch{Write-Host ('Word configuration failed: '+$_.Exception.Message);exit 1}
