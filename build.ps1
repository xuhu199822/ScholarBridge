param([ValidateSet('dist','dist-next')][string]$OutputDirectory='dist')
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$compilerPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compilerPath)) { throw '.NET Framework 4.x C# compiler was not found.' }
$outputDir = Join-Path $projectRoot $OutputDirectory
New-Item -ItemType Directory -Force -Path $outputDir,(Join-Path $projectRoot 'artifacts') | Out-Null
$coreSources = 'Core.cs','LocalModel.cs','WordTarget.cs','NumericText.cs' | ForEach-Object { Join-Path $projectRoot "src\$_" }
& $compilerPath /nologo /target:library /platform:anycpu /optimize+ /codepage:65001 "/out:$outputDir\ScholarBridge.Core.dll" /reference:System.dll /reference:System.Core.dll /reference:System.Web.Extensions.dll /reference:Microsoft.CSharp.dll @coreSources
if ($LASTEXITCODE -ne 0) { throw 'Core build failed.' }
$sourcePaths = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Filter '*.cs' | Where-Object { $_.Name -notin 'Core.cs','LocalModel.cs','WordTarget.cs','NumericText.cs' } | ForEach-Object { $_.FullName }
& $compilerPath /nologo /target:winexe /platform:x64 /optimize+ /codepage:65001 "/out:$outputDir\ScholarBridge.exe" "/reference:$outputDir\ScholarBridge.Core.dll" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll /reference:Microsoft.CSharp.dll @sourcePaths
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
Write-Host "Built: $outputDir\ScholarBridge.exe"
