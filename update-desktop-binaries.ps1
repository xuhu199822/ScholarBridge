$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
foreach($name in @('ScholarBridge.Core.dll','ScholarBridge.exe')){
    $source=Join-Path $projectRoot ('dist-next\'+$name)
    if(-not (Test-Path -LiteralPath $source -PathType Leaf)){throw ('Missing tested binary: '+$source)}
}
foreach($name in @('ScholarBridge.Core.dll','ScholarBridge.exe')){
    $source=Join-Path $projectRoot ('dist-next\'+$name)
    $target=Join-Path $projectRoot ('dist\'+$name)
    $expected=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $expected){continue}
    $backup=$target+'.before-update-'+$stamp
    Move-Item -LiteralPath $target -Destination $backup
    try{Copy-Item -LiteralPath $source -Destination $target;if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $expected){throw 'Hash mismatch'}}
    catch{if(Test-Path -LiteralPath $target){Move-Item -LiteralPath $target -Destination ($target+'.failed-'+$stamp)};Move-Item -LiteralPath $backup -Destination $target;throw}
    Write-Host ('Updated '+$name+'; previous version retained.')
}
