$ErrorActionPreference = 'Stop'
# Notify existing applications after a language-list change. This does not
# change the default input method or terminate any application.
if (-not ('ScholarBridge.InputSettingsNotification' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace ScholarBridge {
    public static class InputSettingsNotification {
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr window, uint message, UIntPtr parameter, string area,
            uint flags, uint timeout, out UIntPtr result);
    }
}
'@
}
[UIntPtr]$result = [UIntPtr]::Zero
$sent = [ScholarBridge.InputSettingsNotification]::SendMessageTimeout(
    [IntPtr]0xffff, 0x001a, [UIntPtr]::Zero, 'intl', 2, 1000, [ref]$result)
if ($sent -eq [IntPtr]::Zero) {
    Write-Warning 'Some windows did not acknowledge the settings notification. Interactive input-method switching still requires verification.'
} else {
    Write-Host 'Language settings notification sent. This does not prove input-method switching works.'
}
