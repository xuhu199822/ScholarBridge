param([ValidateSet('dist','dist-next')][string]$BinaryDirectory='dist-next',[ValidateSet('before','after','heldout')][string]$Label='after')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Add-Type -Path (Join-Path $projectRoot ($BinaryDirectory+'\ScholarBridge.Core.dll'))
$caseFile=if($Label -eq 'heldout'){'tests\domain-heldout.json'}else{'tests\domain-cases.json'}
$cases=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot $caseFile) | ConvertFrom-Json
$settings=New-Object ScholarBridge.Settings
# Fixed public/synthetic cases and default settings only; never read the user's papers or custom glossary.
$rows=@()
$backend=New-Object ScholarBridge.LocalModel
try {
$backend.EnsureReady([Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
foreach($case in $cases){
    $watch=[Diagnostics.Stopwatch]::StartNew()
    try {
        $task=[ScholarBridge.TranslationClient]::Translate($settings,$case.source,$case.mode,$case.context,'',[Threading.CancellationToken]::None)
        $translated=$task.GetAwaiter().GetResult()
        $terms=[ScholarBridge.Quality]::ActiveTerms($settings,$case.mode,'',$case.source)
        $check=[ScholarBridge.Quality]::Check($case.source,$translated,$terms)
        $row=[ordered]@{id=$case.id;domain=$case.mode;source=$case.source;context=$case.context;translation=$translated;errors=@($check.Errors);warnings=@($check.Warnings);review=$case.review;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2)}
    }catch{$row=[ordered]@{id=$case.id;domain=$case.mode;source=$case.source;translation='';errors=@($_.Exception.Message);warnings=@();review=$case.review;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2)}}
    $rows+=[pscustomobject]$row
    $rows | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $projectRoot ('artifacts\domain-eval-'+$Label+'.json'))
    Write-Host ($case.id+' '+$row.seconds+'s; rule errors='+$row.errors.Count)
}
Write-Host 'Completed. Rule checks are not a semantic accuracy score; review all translations against the recorded criteria.'
if(@($rows | Where-Object {-not $_.translation}).Count){throw 'One or more translations failed; inspect the evaluation report.'}
} finally {$backend.Dispose()}
