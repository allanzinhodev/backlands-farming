$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
& (Join-Path $PSScriptRoot 'prepare.ps1')
foreach ($asset in @('Tibia.dat', 'Tibia.spr', 'Tibia.otfi')) {
    if (-not (Test-Path -LiteralPath (Join-Path $repository "assets/860/$asset"))) {
        throw "Missing assets/860/$asset. Open the local asset project first."
    }
}
$downloads = Join-Path $repository 'out/astra-web'
New-Item -ItemType Directory -Path $downloads -Force | Out-Null
$luaArchive = Join-Path $downloads 'lua-5.1.5.tar.gz'
if (-not (Test-Path -LiteralPath $luaArchive)) {
    Invoke-WebRequest -Uri 'https://www.lua.org/ftp/lua-5.1.5.tar.gz' -OutFile $luaArchive -UseBasicParsing
}
if ((Get-FileHash -LiteralPath $luaArchive -Algorithm SHA256).Hash -ne '2640FC56A795F29D28EF15E13C34A47E223960B0240E8CB0A82D9B0738695333') {
    throw 'The downloaded Lua 5.1.5 archive failed SHA-256 verification.'
}
& tar -cf (Join-Path $downloads 'source.tar') --exclude=.git --exclude=android_libs.7z `
    --exclude=build-wasm-release --exclude=860.rar -C (Join-Path $repository '_study/AstraClient') .
if ($LASTEXITCODE -ne 0) { throw 'Could not snapshot the local AstraClient source.' }
& docker run --rm --mount "type=bind,source=$repository,target=/workspace" `
    --mount 'type=volume,source=backlandsofc-astra-build,target=/build' `
    emscripten/emsdk:6.0.8 bash /workspace/tools/astra-web/build.sh
if ($LASTEXITCODE -ne 0) { throw 'The AstraClient WebAssembly build failed.' }
