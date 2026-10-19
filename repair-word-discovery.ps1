$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$manifestPath=Join-Path $projectRoot 'word-web\manifest.xml'
$registryPath='HKCU:\Software\Microsoft\Office\16.0\WEF\Developer'
[xml]$manifest=Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8
$addinId=$manifest.OfficeApp.Id
if($addinId -ne 'ebb89ac1-32e9-4a54-9fc2-662921cbaae8'){throw 'Unexpected add-in identity.'}
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $addinId -Value $manifestPath -PropertyType String -Force | Out-Null
# Same refresh marker used by Microsoft's office-addin-dev-settings package.
New-ItemProperty -Path $registryPath -Name 'RefreshAddins' -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host 'ScholarBridge manifest registration verified; developer add-in discovery refresh requested.'
