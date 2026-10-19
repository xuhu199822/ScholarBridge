$ErrorActionPreference='Stop'
$word=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
try {
    if($word.Documents.Count -ne 1){throw 'Unexpected document count.'}
    $document=$word.Documents.Item(1)
    if($document.Name -ne '文档1'){throw 'Unexpected document.'}
    $actual=$document.Content.Text.Trim()
    Write-Host ('Actual Word text: '+$actual)
    if($actual -ne 'The compressive strength of the specimen is 35 MPa.'){throw 'Office.js replacement not present in document.'}
    $undone=$document.Undo(1)
    if(-not $undone -or $document.Content.Text.Trim() -ne '试件的抗压强度为 35 MPa。'){throw 'Single undo did not restore original.'}
    'PASS: live Word Office.js sidebar loaded, captured public selection, generated local English, replaced document through UI, verified actual document text, single undo restored original.' | Set-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\word-web-live-test.txt') -Encoding UTF8
    Write-Host 'PASS: live Office.js replacement and single undo.'
} finally {if($document){[Runtime.InteropServices.Marshal]::ReleaseComObject($document)|Out-Null};[Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null}
