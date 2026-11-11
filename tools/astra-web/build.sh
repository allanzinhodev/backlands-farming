#!/usr/bin/env bash
set -euo pipefail

# Run inside emscripten/emsdk:6.0.8 with this repository at /workspace and
# a persistent Docker volume at /build. Only the ignored study clone is built.
if ! command -v ninja >/dev/null; then
    apt-get update -qq
    apt-get install -y --no-install-recommends ninja-build
fi
# Windows bind mounts are very slow for thousands of small build/asset reads.
# Extract the local source snapshot into the Linux build volume instead.
mkdir -p /build/source
tar -xf /workspace/out/astra-web/source.tar -C /build/source
lua_options=()
if [[ -f /workspace/out/astra-web/lua-5.1.5.tar.gz ]]; then
    printf '%s  %s\n' 2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333 \
        /workspace/out/astra-web/lua-5.1.5.tar.gz | sha256sum --check
    mkdir -p /build/vendor/lua51
    tar -xzf /workspace/out/astra-web/lua-5.1.5.tar.gz --strip-components=1 -C /build/vendor/lua51
    lua_options+=(-DFETCHCONTENT_SOURCE_DIR_LUA51_SOURCE=/build/vendor/lua51)
fi
emcmake cmake -S /build/source -B /build/wasm -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    -DFETCHCONTENT_BASE_DIR=/build/_deps \
    -DASTRA_WASM_THINGS_DIR=/workspace/assets/860 "${lua_options[@]}"
cmake --build /build/wasm --parallel 3
mkdir -p /workspace/_study/AstraClient/build-wasm-release/dist
cp -a /build/wasm/dist/. /workspace/_study/AstraClient/build-wasm-release/dist/
printf '\nAstra browser build is ready.\n'
