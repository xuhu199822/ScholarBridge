$ErrorActionPreference='Stop'
$word=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
try {
    if($word.Documents.Count -ne 1){throw 'Unexpected document count.'}
    $document=$word.Documents.Item(1)
    if($document.Name -ne '文档1' -or $document.Content.Text.Trim() -ne '试件的抗压强度为 35 MPa。'){throw 'Not the public test document.'}
    $fixturePath=Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\WordWebLiveAcceptance.docx'
    if(Test-Path -LiteralPath $fixturePath){throw 'Fixture already exists; no overwrite.'}
    $document.Convert()
    $document.SaveAs2($fixturePath,16)
    $document.Range(0,$document.Content.End-1).Select()
    Write-Host ('Fixture saved; compatibility='+$document.CompatibilityMode)
} finally {if($document){[Runtime.InteropServices.Marshal]::ReleaseComObject($document)|Out-Null};[Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null}
