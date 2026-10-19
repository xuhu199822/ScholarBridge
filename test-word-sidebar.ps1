$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$app = $null
$doc = $null
try {
    $app = New-Object -ComObject Word.Application
    $app.Visible = $false
    $app.DisplayAlerts = 0
    $doc = $app.Documents.Add()
    $doc.Content.Text = [string]::Concat([char]0x6297,[char]0x538B,[char]0x5F3A,[char]0x5EA6,[char]0x4E3A,' 35 MPa.')
    $doc.Content.Select()
    $addin = $app.COMAddIns.Item('ScholarBridge.WordAddin')
    if (-not $addin.Connect) { $addin.Connect = $true }
    $bridge = $addin.Object
    if (-not $bridge) { throw 'Add-in did not publish its COM bridge.' }
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        if ($bridge.PaneCount -gt 0) { break }
        Start-Sleep -Milliseconds 300
    }
    if ($bridge.PaneCount -lt 1) { throw ('No embedded pane. ' + $bridge.Diagnostic) }
    "PASS: Word loaded registered COM add-in and created an embedded custom task pane. PaneCount=$($bridge.PaneCount)" | Set-Content -LiteralPath (Join-Path $projectRoot 'artifacts\word-sidebar-test.txt') -Encoding UTF8
    Get-Content -LiteralPath (Join-Path $projectRoot 'artifacts\word-sidebar-test.txt')
} catch {
    $_.Exception.ToString() | Set-Content -LiteralPath (Join-Path $projectRoot 'artifacts\word-sidebar-test.txt') -Encoding UTF8
    throw
} finally {
    if ($doc) { $doc.Close(0); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc) }
    if ($app) { $app.Quit(0); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($app) }
}
