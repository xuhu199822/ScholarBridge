$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Add-Type -Path (Join-Path $projectRoot 'dist-next\ScholarBridge.Core.dll')
$cases=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'tests\domain-cases.json') | ConvertFrom-Json
$case=$cases | Where-Object {$_.id -eq 'cs-03'}
$settings=New-Object ScholarBridge.Settings
$backend=New-Object ScholarBridge.LocalModel
try {
    $backend.EnsureReady([Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
    $protected=New-Object ScholarBridge.ProtectedText($case.source)
    $prompt=[ScholarBridge.TranslationClient]::Prompt($protected.Text,$case.mode,$case.context,[ScholarBridge.Quality]::ActiveTerms($settings,$case.mode,'',$case.source))
    $body=@{model=$settings.Model;messages=@(@{role='user';content=$prompt});temperature=0.1;max_tokens=2400;stream=$false} | ConvertTo-Json -Depth 6
    $result=Invoke-RestMethod -Uri $settings.Endpoint -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 180
    # Only the fixed synthetic code sample, never a user's document.
    Write-Output $result.choices[0].message.content
} finally {$backend.Dispose()}
