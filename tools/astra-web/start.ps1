param([int]$Port = 8088, [string]$Network = 'bl-test', [string]$Server = 'backlandsofc-server', [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dist = Join-Path $repository '_study/AstraClient/build-wasm-release/dist'
if (-not (Test-Path -LiteralPath (Join-Path $dist 'astraclient.html'))) {
    throw 'Build the client first: powershell -ExecutionPolicy Bypass -File tools/astra-web/build.ps1'
}
Push-Location $PSScriptRoot
try {
    & npm.cmd ci --omit=dev --ignore-scripts
    if ($LASTEXITCODE -ne 0) { throw 'Could not install the pinned WebSocket dependency.' }
} finally { Pop-Location }
$existing = & docker ps -a --filter 'name=^backlandsofc-astra-web$' --format '{{.Names}}'
$settings = "$Port|$Network|$Server|$dist"
if ($existing -eq 'backlandsofc-astra-web') {
    $labels = (& docker inspect --format '{{json .Config.Labels}}' backlandsofc-astra-web) | ConvertFrom-Json
    if ($labels.'org.backlands.astra-web' -ne 'true' -or $labels.'org.backlands.workspace' -ne $repository) {
        throw 'Container name backlandsofc-astra-web belongs to another workspace; it was left unchanged.'
    }
    if ($labels.'org.backlands.settings' -eq $settings) {
        & docker restart backlandsofc-astra-web
    } else {
        & docker stop backlandsofc-astra-web
        if ($LASTEXITCODE -ne 0) { throw 'Could not stop the previous owned web bridge.' }
        & docker rm backlandsofc-astra-web
        if ($LASTEXITCODE -ne 0) { throw 'Could not replace the previous owned web bridge.' }
        $existing = ''
    }
}
if (-not $existing) {
    & docker run -d --name backlandsofc-astra-web --restart unless-stopped `
        --label 'org.backlands.astra-web=true' --label "org.backlands.workspace=$repository" `
        --label "org.backlands.settings=$settings" `
        --network $Network -p "127.0.0.1:${Port}:${Port}" `
        --mount "type=bind,source=$PSScriptRoot,target=/app,readonly" `
        --mount "type=bind,source=$dist,target=/dist,readonly" `
        --workdir /app emscripten/emsdk:6.0.8 `
        node server.cjs --bind 0.0.0.0 --port $Port --target $Server --directory /dist
}
if ($LASTEXITCODE -ne 0) { throw 'Could not start the local Astra Web bridge.' }
$ready = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 2
        if ($health.service -eq 'backlands-astra-web' -and $health.ready) { $ready = $true; break }
    } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) { throw 'The local web bridge did not become ready. See docker logs backlandsofc-astra-web.' }
if (-not $NoBrowser) { Start-Process "http://127.0.0.1:$Port/astraclient.html" }
Write-Host "Astra Web ready: http://127.0.0.1:$Port/astraclient.html"
