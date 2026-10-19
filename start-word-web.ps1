$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$serverPath=Join-Path $projectRoot 'word-web\server.mjs'
$dataPath=Join-Path $projectRoot 'data\word-web'
$expectedThumb=(Get-Content -Raw -LiteralPath (Join-Path $dataPath 'tls.json')|ConvertFrom-Json).thumbprint
function Test-SidebarReady {
    try {
        $request=[Net.HttpWebRequest]::Create('https://localhost:18766/api/session')
        $request.Proxy=$null;$request.Timeout=1000;$request.AllowAutoRedirect=$false
        $response=$request.GetResponse()
        try {
            if($request.ServicePoint.Certificate.GetCertHashString() -ne $expectedThumb){return $false}
            $reader=New-Object IO.StreamReader($response.GetResponseStream())
            try{$session=$reader.ReadToEnd()|ConvertFrom-Json;return $session.token -match '^[a-f0-9]{64}$'}finally{$reader.Dispose()}
        }finally{$response.Dispose()}
    }catch{return $false}
}
if(Test-SidebarReady){Write-Host 'Word sidebar service is already ready.';exit 0}
$node=Join-Path $projectRoot 'runtime\node\node.exe'
if(-not (Test-Path -LiteralPath $node)){$node=(Get-Command node -ErrorAction Stop).Source}
$process=Start-Process -FilePath $node -ArgumentList ('"'+$serverPath+'"') -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $dataPath 'server-start.log') -RedirectStandardError (Join-Path $dataPath 'server-error.log') -PassThru
for($attempt=0;$attempt -lt 20;$attempt++){
    if(Test-SidebarReady){Write-Host 'Word sidebar service is ready in the background. Open Word > Add-ins > Developer Add-ins > ScholarBridge.';exit 0}
    if($process.HasExited){throw 'Sidebar service exited; inspect data/word-web/server-error.log. Do not disable certificate checks.'}
    Start-Sleep -Milliseconds 200
}
throw 'Sidebar did not become ready; inspect data/word-web/server-error.log.'
