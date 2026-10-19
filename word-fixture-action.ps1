param([ValidateSet('Select','Change','CheckStale','Caret')] [string]$Action='Select')
$ErrorActionPreference='Stop'
$word=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
try {
    if($word.Documents.Count -ne 1){throw 'Unexpected document count; no changes.'}
    $document=$word.Documents.Item(1)
    if($document.Name -ne '文档1'){throw 'Unexpected document; no changes.'}
    $text=$document.Content.Text.Trim()
    if($text -ne '试件的抗压强度为 35 MPa。' -and $text -ne '试件的抗压强度为 36 MPa。'){throw 'Not the exact public fixture; no changes.'}
    if($Action -eq 'Select'){$document.Range(0,$document.Content.End-1).Select()}
    if($Action -eq 'Caret'){$document.Range($document.Content.End-1,$document.Content.End-1).Select()}
    if($Action -eq 'Change'){$document.Content.Text='试件的抗压强度为 36 MPa。'}
    if($Action -eq 'CheckStale'){
        if($text -ne '试件的抗压强度为 36 MPa。'){throw 'Stale test did not preserve edited source.'}
        if(-not $document.Undo(1) -or $document.Content.Text.Trim() -ne '试件的抗压强度为 35 MPa。'){throw 'Fixture restoration failed.'}
        Add-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\word-web-live-test.txt') -Value 'PASS: after translation the document changed from 35 to 36 MPa; UI apply refused stale translation and preserved edited text; test edit undone.' -Encoding UTF8
    }
    Write-Host ('Fixture action passed: '+$Action)
} finally {if($document){[Runtime.InteropServices.Marshal]::ReleaseComObject($document)|Out-Null};[Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null}
