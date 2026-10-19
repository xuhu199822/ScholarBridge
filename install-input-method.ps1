param([switch]$Uninstall,[switch]$Verify)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$setup=Join-Path $projectRoot 'dist\ScholarBridge.ImeSetup.exe'
if($Verify){& $setup --verify;exit $LASTEXITCODE}
if($Uninstall){& $setup --disable-user;if($LASTEXITCODE -ne 0){throw 'Current-user removal failed.'}}
if(-not $Uninstall){
    & (Join-Path $projectRoot 'dist\ScholarBridge.RimeHost.exe') --deploy
    if($LASTEXITCODE -ne 0){throw 'Pinyin data deployment failed. Close the ScholarBridge Rime service and retry.'}
}
$action=if($Uninstall){'--uninstall'}else{'--register-system'}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    & $setup $action
    if($LASTEXITCODE -ne 0){throw 'System registration step failed.'}
}else{
    $installer=Start-Process -FilePath $setup -ArgumentList $action -Verb RunAs -WindowStyle Hidden -PassThru -Wait
    if($installer.ExitCode -ne 0){throw 'Administrator registration did not succeed.'}
}
if($Uninstall){& $setup --disable-user;if($LASTEXITCODE -ne 0){throw 'Current-user removal failed.'}}
if(-not $Uninstall){
    & $setup --enable-user
    if($LASTEXITCODE -ne 0){throw 'Current-user enable check failed. Open Settings > Time & language > Language & region > Chinese language options > Add a keyboard and select ScholarBridge. Then run dist/ScholarBridge.ImeSetup.exe --verify. See README.md for the Chinese menu path.'}
    & $setup --verify
    if($LASTEXITCODE -ne 0){throw 'Final installation verification failed.'}
    Write-Host 'Installed for current user. Select ScholarBridge with Win+Space. Default input method unchanged.'
}

