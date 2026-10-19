$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
foreach ($arch in @('x64','x86')) {
    $source = Join-Path $projectRoot ('dist\ime-next\' + $arch + '\ScholarBridge.Tip.dll')
    $target = Join-Path $projectRoot ('dist\ime\' + $arch + '\ScholarBridge.Tip.dll')
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw ('Missing staged binary: ' + $source) }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw ('Missing installed binary: ' + $target) }
}
foreach ($arch in @('x64','x86')) {
    $source = Join-Path $projectRoot ('dist\ime-next\' + $arch + '\ScholarBridge.Tip.dll')
    $target = Join-Path $projectRoot ('dist\ime\' + $arch + '\ScholarBridge.Tip.dll')
    $backup = $target + '.before-update-' + $stamp
    $expected = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $expected) {
        Write-Host ($arch + ': already updated.')
        continue
    }
    # Rename the old image rather than overwrite a DLL mapped by an open app.
    # Existing processes keep their loaded version until they exit normally.
    Move-Item -LiteralPath $target -Destination $backup
    try {
        Copy-Item -LiteralPath $source -Destination $target
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $expected) { throw 'Binary hash mismatch.' }
    } catch {
        if (Test-Path -LiteralPath $target) {
            Move-Item -LiteralPath $target -Destination ($target + '.failed-' + $stamp)
        }
        Move-Item -LiteralPath $backup -Destination $target
        throw
    }
    Write-Host ($arch + ': updated; previous DLL retained at ' + $backup)
}
Write-Host 'Save documents and fully exit/reopen applications using ScholarBridge to load the update. Registration and default input method were not changed.'
