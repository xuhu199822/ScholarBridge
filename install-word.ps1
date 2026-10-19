param([switch]$Uninstall,[switch]$Machine)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$assemblyPath = Join-Path $projectRoot 'dist\ScholarBridge.WordAddin.dll'
$identity = 'ScholarBridge.WordAddin, Version=0.2.0.0, Culture=neutral, PublicKeyToken=null'
$codebase = [Uri]::UnescapeDataString(([Uri]$assemblyPath).AbsoluteUri)
$nativePath = Join-Path $projectRoot 'dist\ScholarBridge.WordNative.dll'
$classes = @(
    @{ Guid='{42B69A25-F64B-453B-AB72-6E309C737F23}'; ProgId='ScholarBridge.WordAddin'; Class='ScholarBridge.Word.Addin'; Control=$false },
    @{ Guid='{46578911-112A-420B-9D5B-AD42DD615E3A}'; ProgId='ScholarBridge.WordPane'; Class='ScholarBridge.Word.TranslationPane'; Control=$true }
)
if (-not $Uninstall -and -not (Test-Path -LiteralPath $assemblyPath)) { throw 'Build the Word add-in first.' }
foreach ($view in [Microsoft.Win32.RegistryView]::Registry64,[Microsoft.Win32.RegistryView]::Registry32) {
    $hive = if ($Machine) { [Microsoft.Win32.RegistryHive]::LocalMachine } else { [Microsoft.Win32.RegistryHive]::CurrentUser }
    $root = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hive,$view)
    try {
        foreach ($class in $classes) {
            $path = 'Software\Classes\CLSID\' + $class.Guid
            $existing = $root.OpenSubKey($path + '\InprocServer32')
            if ($existing) {
                $oldClass = $existing.GetValue('Class'); $oldPath = $existing.GetValue('CodeBase'); $existing.Dispose()
                if ($oldClass -and $oldClass -ne $class.Class) { throw "Registration collision: $path" }
                if ($Uninstall -and $oldPath -ne $codebase) { throw 'The registration belongs to another installation directory. Uninstall from that directory.' }
            }
            if ($Uninstall) {
                if ($existing) { $root.DeleteSubKeyTree($path,$false); $root.DeleteSubKeyTree('Software\Classes\'+$class.ProgId,$false) }
                continue
            }
            $key = $root.CreateSubKey($path); $key.SetValue('',$class.ProgId); $key.Dispose()
            $key = $root.CreateSubKey('Software\Classes\'+$class.ProgId); $key.SetValue('',$class.Class); $key.Dispose()
            $key = $root.CreateSubKey($path+'\Implemented Categories\{62C8FE65-4EBB-45E7-B440-6E39B2CDBF29}'); $key.Dispose()
            $key = $root.CreateSubKey($path+'\ProgId'); $key.SetValue('',$class.ProgId); $key.Dispose()
            $key = $root.CreateSubKey('Software\Classes\'+$class.ProgId+'\CLSID'); $key.SetValue('',$class.Guid); $key.Dispose()
            foreach ($suffix in '\InprocServer32','\InprocServer32\0.2.0.0') {
                $key = $root.CreateSubKey($path+$suffix)
                if ($suffix -eq '\InprocServer32') { $key.SetValue('','mscoree.dll'); $key.SetValue('ThreadingModel','Both') }
                $key.SetValue('Class',$class.Class); $key.SetValue('Assembly',$identity); $key.SetValue('RuntimeVersion','v4.0.30319'); $key.SetValue('CodeBase',$codebase); $key.Dispose()
            }
            if (-not $class.Control) {
                $key = $root.CreateSubKey($path+'\InprocServer32'); $key.SetValue('',$nativePath); $key.SetValue('ThreadingModel','Apartment'); $key.Dispose()
            }
            if ($class.Control) {
                $key = $root.CreateSubKey($path+'\Control'); $key.Dispose()
                $key = $root.CreateSubKey($path+'\MiscStatus\1'); $key.SetValue('','131457'); $key.Dispose()
                $key = $root.CreateSubKey($path+'\Implemented Categories\{40FC6ED4-2438-11CF-A3DB-080036F12502}'); $key.Dispose()
            }
        }
        $addinPath = 'Software\Microsoft\Office\Word\Addins\ScholarBridge.WordAddin'
        if ($Uninstall) { $root.DeleteSubKeyTree($addinPath,$false) }
        else {
            $key = $root.CreateSubKey($addinPath)
            $key.SetValue('FriendlyName','ScholarBridge - Local Academic Translation'); $key.SetValue('Description','Local medical and civil engineering translation sidebar')
            $key.SetValue('LoadBehavior',3,[Microsoft.Win32.RegistryValueKind]::DWord);$key.SetValue('CommandLineSafe',0,[Microsoft.Win32.RegistryValueKind]::DWord);$key.Dispose()
        }
    } finally { $root.Dispose() }
}
if ($Uninstall) { Write-Host 'ScholarBridge Word add-in unregistered. Restart Word.' }
else { Write-Host 'ScholarBridge Word sidebar installed for current user. Restart Word and open the ScholarBridge tab.' }
