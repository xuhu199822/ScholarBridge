$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$toolchain=Join-Path $projectRoot 'tools\compiler\llvm-mingw-20261006-ucrt-x86_64\bin'
$exe=Join-Path $projectRoot 'dist-next\ImeFrequencyTest.exe'
& (Join-Path $toolchain 'x86_64-w64-mingw32-clang++.exe') -std=c++17 -O2 -static -municode ('-I'+(Join-Path $projectRoot 'vendor\json')) ('-I'+(Join-Path $projectRoot 'vendor\rime\dist\include')) (Join-Path $projectRoot 'ime\FrequencyTest.cpp') -o $exe -ladvapi32 -lole32
if($LASTEXITCODE -ne 0){throw 'Frequency test build failed.'}
& $exe
if($LASTEXITCODE -ne 0){throw 'Frequency test failed; see artifacts/ime-frequency-test.txt.'}
