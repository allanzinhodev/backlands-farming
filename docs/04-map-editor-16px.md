# NexaMap Editor — suporte a sprites 16x16

## Diagnóstico (código em `_study/NexaMap-Editor/source`)

O tamanho de 32 px está concentrado em **duas constantes**, mais alguns `32` soltos:

| Onde | O quê | Usos |
|---|---|---|
| `definitions.h:115` | `constexpr int TileSize = 32;` — pixels por tile na tela | 180 usos em 10 arquivos (`map_drawer.cpp` sozinho: 142) |
| `definitions.h:118` | `#define SPRITE_PIXELS 32` / `SPRITE_PIXELS_SIZE` | 63 usos, todos em `graphics.cpp` (decodificador RLE do `.spr`, upload de textura GL, recolor de outfits, previews) |
| `map_chunk_render_cache.cpp:87-92` | quads de 32 px fixos | 6 |
| `map_migration/classic_resource_catalog.cpp:54` | rejeita `sprite-size != 32` | 1 (+ ~10 `32` no recorte de preview) |
| `palette_*`, `dcbutton.cpp`, `replace_*`, `map_display.cpp` | ícones de paleta 32x32 | ~20 — tamanho de **ícone de UI**, não precisa mudar |

Cuidado com nome confuso: `SPRITE_SIZE_16x16` / `SPRITE_SIZE_32x32` (`graphics.h`) são **tamanhos de miniatura da
paleta**, não o tamanho real do sprite. Com sprites de 16 px, o ícone "32x32" vira um upscale 2x — ok.

Como o decodificador e o desenho do mapa já leem tudo dessas constantes, a mudança é viável e localizada.
O `.otbm` não guarda pixels — **mapas feitos no editor 16px são os mesmos que o servidor lê**.

## Opções

| | 1. Build 16px (opção de CMake) | 2. Tamanho em runtime por cliente (`clients.xml`) | 3. Sem mexer no editor |
|---|---|---|---|
| Como | `NEXAMAP_SPRITE_PIXELS=16` vira `TileSize`/`SPRITE_PIXELS`; trocar os `32` soltos pela constante | `TileSize` deixa de ser `constexpr` e vem do cliente carregado (`sprite-size="16"`) | gerar um `.spr` só para o editor com cada sprite ampliado 2x (nearest-neighbor) e `Displacement/Elevation` x2 |
| Esforço | ~1–2 dias | ~1 semana (180 usos de `constexpr` viram runtime, testes de regressão em 32px) | ~1 dia (script de conversão) |
| Risco | baixo | médio | baixo, mas editor e jogo usam arquivos diferentes |
| Binários | um editor só para o Backlands | um editor para tudo; dá para mandar PR upstream | editor original |

**Recomendação: opção 1.** Menor mudança que entrega 16px nativo. Se depois quiser contribuir com o upstream,
a opção 2 parte da 1.

## Plano da opção 1

1. Trazer o editor para o repo: `git subtree add --prefix map-editor ...` (ver [00-setup-e-artefatos.md](00-setup-e-artefatos.md)).
2. `CMakeLists.txt`: `set(NEXAMAP_SPRITE_PIXELS 32 CACHE STRING ...)` + `add_compile_definitions(NEXAMAP_SPRITE_PIXELS=...)`; validar só 16 ou 32.
3. `definitions.h`: `TileSize` e `SPRITE_PIXELS` derivados de `NEXAMAP_SPRITE_PIXELS`.
4. Substituir os `32` que significam "pixels por tile": `map_chunk_render_cache.cpp`, `classic_resource_catalog.cpp`,
   offset de luz em `map_drawer.cpp:1734` e revisar `light_drawer.cpp`, `minimap_*`, `png_map_import_window.cpp`.
5. Zoom: o zoom padrão deve compensar (16 px em zoom 1.0 fica pequeno) — default 2.0 no build 16px.
6. Compilar Release x64 (VS 2026 + vcpkg, já instalados nesta máquina) e testar com um `.spr`/`.dat` 16px de exemplo.
7. CI: job extra no workflow do Windows com `-DNEXAMAP_SPRITE_PIXELS=16`.

## Dependência bloqueante: de onde vem o `.spr` 16px?

Object Builder e ferramentas comuns de OT só geram 32x32. Precisamos de uma ferramenta própria
(script Python/Rust) que faça **PNGs 16px → `.spr` + `.dat`** — e, de quebra, gere os **atlases PNG**
que o cliente web vai consumir. Uma fonte única de verdade (pasta de PNGs + um manifesto com as flags do
`.dat`) alimenta editor, cliente web e `items.otb`/`items.xml`.

```
assets/ (PNG 16px + manifest.yaml com flags)
   └── tool ──► Backlands.spr / Backlands.dat   → NexaMap (build 16px)
            ├─► atlas-*.png + atlas.json        → cliente web
            └─► items.otb + items.xml (esqueleto) → servidor
```
