$ErrorActionPreference='Stop'
$word=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
try {
    if($word.Documents.Count -ne 1){throw 'Unexpected document count; no modification.'}
    $document=$word.Documents.Item(1)
    if($document.Name -ne '文档1' -or $document.Content.Text.Trim().Length -ne 0){throw 'Not the empty test document; no modification.'}
    if($document.CompatibilityMode -lt 15){$document.Convert()}
    $document.Content.Text='试件的抗压强度为 35 MPa。'
    $document.Range(0,$document.Content.End-1).Select()
    Write-Host 'Public test sentence inserted into verified empty test document.'
} finally {
    if($document){[Runtime.InteropServices.Marshal]::ReleaseComObject($document)|Out-Null}
    [Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null
}
