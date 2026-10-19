param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$dllPath = Join-Path $projectRoot 'dist\ScholarBridge.WordAddin.dll'
$identity = [Reflection.AssemblyName]::GetAssemblyName($dllPath).FullName
$codebase = [Uri]::UnescapeDataString(([Uri]$dllPath).AbsoluteUri)
$version = [Reflection.AssemblyName]::GetAssemblyName($dllPath).Version.ToString()
$classes = @(
    @{Guid='{B7786CF2-9568-4D9A-997E-EC1E06B56DDD}';ProgId='ScholarBridge.WordSidebar';Class='ScholarBridge.Word.Addin'},
    @{Guid='{46578911-112A-420B-9D5B-AD42DD615E3A}';ProgId='ScholarBridge.WordPane';Class='ScholarBridge.Word.TranslationPane'}
)
foreach ($view in [Microsoft.Win32.RegistryView]::Registry64,[Microsoft.Win32.RegistryView]::Registry32) {
    $root = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser,$view)
    try {
        foreach ($item in $classes) {
            $path = 'Software\Classes\CLSID\'+$item.Guid
            if ($Uninstall) {
                $existing=$root.OpenSubKey($path+'\InprocServer32')
                if ($existing) { $owns=($existing.GetValue('CodeBase') -eq $codebase);$existing.Dispose();if(-not $owns){throw 'Registration belongs to a different installation.'};$root.DeleteSubKeyTree($path,$false);$root.DeleteSubKeyTree('Software\Classes\'+$item.ProgId,$false) }
                continue
            }
            $key=$root.CreateSubKey('Software\Classes\'+$item.ProgId+'\CLSID');$key.SetValue('',$item.Guid);$key.Dispose()
            $key=$root.CreateSubKey($path+'\ProgId');$key.SetValue('',$item.ProgId);$key.Dispose()
            foreach ($suffix in '\InprocServer32',('\InprocServer32\'+$version)) {
                $key=$root.CreateSubKey($path+$suffix);$key.SetValue('','mscoree.dll');$key.SetValue('ThreadingModel','Both');$key.SetValue('Class',$item.Class);$key.SetValue('Assembly',$identity);$key.SetValue('RuntimeVersion','v4.0.30319');$key.SetValue('CodeBase',$codebase);$key.Dispose()
            }
            $key=$root.CreateSubKey($path+'\Implemented Categories\{62C8FE65-4EBB-45E7-B440-6E39B2CDBF29}');$key.Dispose()
            if ($item.ProgId -eq 'ScholarBridge.WordPane') {
                $key=$root.CreateSubKey($path+'\Control');$key.Dispose();$key=$root.CreateSubKey($path+'\MiscStatus\1');$key.SetValue('','131457');$key.Dispose()
                $key=$root.CreateSubKey($path+'\Implemented Categories\{40FC6ED4-2438-11CF-A3DB-080036F12502}');$key.Dispose()
            }
        }
        $path='Software\Microsoft\Office\Word\Addins\ScholarBridge.WordSidebar'
        if ($Uninstall) {$root.DeleteSubKeyTree($path,$false)} else {$key=$root.CreateSubKey($path);$key.SetValue('FriendlyName','ScholarBridge Academic Sidebar');$key.SetValue('Description','Local translation and academic terminology');$key.SetValue('LoadBehavior',3,[Microsoft.Win32.RegistryValueKind]::DWord);$key.SetValue('CommandLineSafe',0,[Microsoft.Win32.RegistryValueKind]::DWord);$key.Dispose()}
    }finally{$root.Dispose()}
}
Write-Host 'Current-user sidebar registration updated. Restart Word.'
