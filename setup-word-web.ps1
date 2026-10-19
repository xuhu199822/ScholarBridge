param([switch]$Uninstall)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$dataPath=Join-Path $projectRoot 'data\word-web'
$manifestPath=Join-Path $projectRoot 'word-web\manifest.xml'
$registryPath='HKCU:\Software\Microsoft\Office\16.0\WEF\Developer'
$addinId='ebb89ac1-32e9-4a54-9fc2-662921cbaae8'
if($Uninstall){
    if(Test-Path -LiteralPath (Join-Path $dataPath 'tls.json')){
        $saved=Get-Content -Raw -LiteralPath (Join-Path $dataPath 'tls.json')|ConvertFrom-Json
        foreach($store in 'My','Root'){
            $certPath='Cert:\CurrentUser\'+$store+'\'+$saved.thumbprint
            if(Test-Path -LiteralPath $certPath){$certificate=Get-Item -LiteralPath $certPath;if($certificate.Subject -eq 'CN=localhost' -and $certificate.FriendlyName -eq 'ScholarBridge Local Word'){Remove-Item -LiteralPath $certPath}}
        }
    }
    if(Test-Path -LiteralPath $registryPath){$value=(Get-Item -LiteralPath $registryPath).GetValue($addinId);if($value -eq $manifestPath){Remove-ItemProperty -LiteralPath $registryPath -Name $addinId}}
    Write-Host 'Current-user Word web add-in and localhost certificate unregistered. Model and data preserved.'
    exit
}
New-Item -ItemType Directory -Force -Path $dataPath|Out-Null
$identity=[Security.Principal.WindowsIdentity]::GetCurrent().User
$acl=Get-Acl -LiteralPath $dataPath
$acl.SetAccessRuleProtection($true,$false)
$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow')))
$systemSid=New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($systemSid,'FullControl','ContainerInherit,ObjectInherit','None','Allow')))
Set-Acl -LiteralPath $dataPath -AclObject $acl
$saved=$null
if(Test-Path -LiteralPath (Join-Path $dataPath 'tls.json')){$saved=Get-Content -Raw -LiteralPath (Join-Path $dataPath 'tls.json')|ConvertFrom-Json}
if(-not $saved -or -not (Test-Path -LiteralPath ('Cert:\CurrentUser\My\'+$saved.thumbprint))){
    $certificate=New-SelfSignedCertificate -Type Custom -Subject 'CN=localhost' -FriendlyName 'ScholarBridge Local Word' -CertStoreLocation 'Cert:\CurrentUser\My' -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeyExportPolicy Exportable -KeyUsage DigitalSignature,KeyEncipherment -NotAfter (Get-Date).AddYears(1) -TextExtension @('2.5.29.19={text}ca=0','2.5.29.37={text}1.3.6.1.5.5.7.3.1','2.5.29.17={text}DNS=localhost&IPAddress=127.0.0.1')
    $tlsPassword=[Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N')
    $secret=ConvertTo-SecureString -String $tlsPassword -AsPlainText -Force
    Export-PfxCertificate -Cert $certificate -FilePath (Join-Path $dataPath 'localhost.pfx') -Password $secret|Out-Null
    Export-Certificate -Cert $certificate -FilePath (Join-Path $dataPath 'localhost.cer')|Out-Null
    @{thumbprint=$certificate.Thumbprint;password=$tlsPassword}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $dataPath 'tls.json') -Encoding UTF8
}
$saved=Get-Content -Raw -LiteralPath (Join-Path $dataPath 'tls.json')|ConvertFrom-Json
$trustedPath='Cert:\CurrentUser\Root\'+$saved.thumbprint
if(Test-Path -LiteralPath $trustedPath){$trusted=Get-Item -LiteralPath $trustedPath}
else{$trusted=Import-Certificate -FilePath (Join-Path $dataPath 'localhost.cer') -CertStoreLocation 'Cert:\CurrentUser\Root'}
$trusted.FriendlyName='ScholarBridge Local Word'
New-Item -Path $registryPath -Force|Out-Null
New-ItemProperty -Path $registryPath -Name $addinId -Value $manifestPath -PropertyType String -Force|Out-Null
New-ItemProperty -Path $registryPath -Name 'RefreshAddins' -Value 1 -PropertyType DWord -Force|Out-Null
Write-Host 'Word sidebar registered for current user; localhost-only leaf certificate trusted for this user.'
Write-Host 'Save documents and fully exit all Word instances after registration. Then start Word > Home > Add-ins > Developer Add-ins > ScholarBridge. The store My Add-ins page may be empty for this local developer deployment.'
