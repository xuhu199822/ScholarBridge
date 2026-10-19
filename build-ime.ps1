$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$toolchain = Join-Path $projectRoot 'tools\compiler\llvm-mingw-20261006-ucrt-x86_64\bin'
$includeJson = Join-Path $projectRoot 'vendor\json'
$includeRime = Join-Path $projectRoot 'vendor\rime\dist\include'
$engineDir = Join-Path $projectRoot 'runtime\ime\x64'
New-Item -ItemType Directory -Force -Path $engineDir | Out-Null
Copy-Item -Path (Join-Path $projectRoot 'ime\data\*.yaml') -Destination (Join-Path $projectRoot 'runtime\ime\shared')
New-Item -ItemType Directory -Force (Join-Path $projectRoot 'runtime\ime\shared\lua') | Out-Null
Copy-Item -Path (Join-Path $projectRoot 'ime\data\lua\*.lua') -Destination (Join-Path $projectRoot 'runtime\ime\shared\lua')
if (-not (Test-Path -LiteralPath (Join-Path $engineDir 'rime.dll'))) { Copy-Item -LiteralPath (Join-Path $projectRoot 'vendor\rime\x64\dist\lib\rime.dll') -Destination $engineDir }
$cpp = Join-Path $toolchain 'x86_64-w64-mingw32-clang++.exe'
& $cpp -std=c++17 -O2 -static -municode "-I$includeJson" "-I$includeRime" (Join-Path $projectRoot 'ime\RimeHost.cpp') -o (Join-Path $projectRoot 'dist\ScholarBridge.RimeHost.exe') -ladvapi32 -lole32
if ($LASTEXITCODE -ne 0) { throw 'Rime host build failed.' }
foreach ($entry in @(@('Register.cpp','ScholarBridge.ImeSetup.exe'),@('ServiceTest.cpp','ImeServiceTest.exe'),@('TsfTest.cpp','ImeTsfTest.exe'),@('RegisteredTest.cpp','ImeRegisteredTest.exe'),@('ActivationTest.cpp','ImeActivationTest.exe'),@('ProfileListTest.cpp','ImeProfileListTest.exe'))) {
    & $cpp -std=c++17 -O2 -static -municode "-I$includeJson" (Join-Path $projectRoot ('ime\'+$entry[0])) -o (Join-Path $projectRoot ('dist\'+$entry[1])) -ladvapi32 -lole32 -loleaut32 -luuid
    if ($LASTEXITCODE -ne 0) { throw 'IME tool build failed.' }
}
foreach ($arch in 'x64','x86') {
    $target = if ($arch -eq 'x64') { 'x86_64' } else { 'i686' }
    $out = Join-Path $projectRoot "dist\ime\$arch"
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    & (Join-Path $toolchain "$target-w64-mingw32-clang++.exe") -std=c++17 -O2 -static -shared "-I$includeJson" (Join-Path $projectRoot 'ime\Tip.cpp') (Join-Path $projectRoot 'ime\Tip.def') -o (Join-Path $out 'ScholarBridge.Tip.dll') -ladvapi32 -lole32 -loleaut32 -luuid -lgdi32 -luser32
    if ($LASTEXITCODE -ne 0) { throw "TSF $arch build failed." }
}
Write-Host 'Built native TSF x64/x86 and Rime host.'


