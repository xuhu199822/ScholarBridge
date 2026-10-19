$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$setup=Join-Path $projectRoot 'dist\ScholarBridge.ImeSetup.exe'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
try {
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
        & $setup --register-system
        if($LASTEXITCODE -ne 0){throw 'System registration failed.'}
    }else{
        $installer=Start-Process -FilePath $setup -ArgumentList '--register-system' -Verb RunAs -WindowStyle Hidden -PassThru -Wait
        if($installer.ExitCode -ne 0){throw 'Administrator registration did not succeed.'}
    }
    & $setup --enable-user
    $enableExitCode=$LASTEXITCODE
    & (Join-Path $PSScriptRoot 'refresh-input-settings.ps1')
    if($enableExitCode -ne 0){Write-Warning 'The enable operation did not pass all checks. Rechecking after notifying applications.'}
    & $setup --verify
    if($LASTEXITCODE -ne 0){throw 'Windows has not enabled ScholarBridge. Open Settings > Time & language > Language & region > Chinese language options > Add a keyboard, select ScholarBridge, then run dist/ScholarBridge.ImeSetup.exe --verify. Restart alone did not resolve this state on the test computer.'}
    Write-Host 'Registration checks passed. Default input method unchanged. Interactive switching is not yet verified.'
    Write-Host 'Use Win+Space to check ScholarBridge. Keyboard acceptance testing is still required.'
}catch{Write-Error ('Repair incomplete: '+$_.Exception.Message);exit 1}
