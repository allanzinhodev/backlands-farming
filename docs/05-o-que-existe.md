# O que já existe no servidor — guia para limpeza

Inventário de `server/` (levantado em 2026-11-10). Tudo está em `server/data/` salvo indicação.
Coluna **Sugestão**: ✂️ remover · 🔁 reaproveitar para fazenda · ✅ manter. A decisão final é sua.
Config dos sistemas opcionais: ver [02-features-e-custo.md](02-features-e-custo.md).

## Visão geral

| Pasta | Arquivos | Tamanho | Conteúdo |
|---|---|---|---|
| `monsters/` | 1809 | 9.2 MB | ~1700 monstros Tibia em Lua/RevScript |
| `npc/` | 1095 | 9.9 MB | `crystalserver/` (1050 NPCs do Crystal 15.x), `lua/` (21 NPCs TFS), `lib/` |
| `scripts/` | 1254 | 6.3 MB | actions, spells, talkactions, network (sistemas 15.x), etc. |
| `items/` | 3 | 6.4 MB | `items.otb`, `items.xml` (17.411 itens), `proficiencies.json` |
| `world/` | 3 | 4.2 MB | mapa de exemplo `world.otbm` + 61 casas + spawns |
| `migrations/` | 70 | 230 KB | migrações de banco (não apagar — o servidor usa para versionar o schema) |
| `lib/` | 42 | 464 KB | biblioteca Lua base (core, compat, funções) |
| `startup/` | 22 | 54 KB | tabelas carregadas no boot (portas, alavancas, baús de quest, teleports) |
| `XML/` | 8 | 118 KB | vocações, outfits, montarias, grupos, quests, imbuements, clima por zona |
| `raids/`, `store/`, `events/` | 11 | — | raids, catálogo da loja, callbacks de eventos |

## Monstros (`monsters/`, 1809)

| Subpasta | Qtde | Sugestão |
|---|---|---|
| `quests/` | 693 | ✂️ |
| `bosses/` | 109 | ✂️ |
| `humanoids` 94, `humans` 80, `mammals` 80, `magicals` 64, `undeads` 64, `vermins` 62 | 444 | ✂️ quase tudo; 🔁 `mammals` (animais de fazenda/selvagens), `vermins` (pragas: ratos, insetos) |
| `winter_update_2025` 57, `summer_update_2026` 36, `raids` 55, `event_creatures` 38, `newhaven_update_2025` 4 | 190 | ✂️ |
| `reptiles` 42, `aquatics` 40, `demons` 40, `constructs` 31, `elementals` 19, `fey` 19, `dawnport` 20, `birds` 17, `dragons` 17, `giants` 16, `lycanthropes` 15, `amphibics` 12, `slimes` 12, `inkborn` 11, `extra_dimensional` 11, `nostalgia` 8, `wild_magics` 4, `no_rest_for_the_wicked` 1 | ~335 | ✂️; talvez 🔁 `birds` (corvos na lavoura), `plants` 15 (plantas-monstro) |
| `traps` 13, `trainers` 5, `familiars` 5 | 23 | ✂️ (trainers só se manter skills) |

Monstros carregados no boot custam RAM/tempo de startup (`forceMonsterTypesOnLoad = true`). Apagar reduz os dois.

## NPCs (`npc/`)

| Subpasta | Qtde | Sugestão |
|---|---|---|
| `crystalserver/` | 1050 | ✂️ (só usado com `npcSystem = "crystal"`) |
| `lua/` | 21 | 🔁 base para vendedor de sementes / comprador de colheita |
| `lib/` | 24 | ✅ (biblioteca de NPC) |

## Scripts (`scripts/`)

| Pasta | Qtde | O que tem | Sugestão |
|---|---|---|---|
| `spells/spells_monsters/` | 632 | magias de monstros | ✂️ junto com os monstros |
| `spells/attack` 79, `conjuring` 49, `support` 49, `healing` 28, `runes` 27, `party` 5, `familiar` 5, `soulpit` 3, `house` 4 | 249 | magias de jogador | ✂️ a maioria; ✅ `house` (comandos de casa) |
| `talkactions/god` 36, `gm` 30 | 66 | comandos de GM | ✅ (ferramenta de administração) |
| `talkactions/player` | 40 | chain/cleave toggle, guild, casa, quickloot, promotion, shop, info | ✅ casa/guild/info; ✂️ chain, cleave, promotion |
| `talkactions/stress` | 4 | testes de carga | ✂️ em produção |
| `network/` | 40 | protocolo dos sistemas 15.x: battlepass, boss, cyclopedia, daily reward, forge, gamestore, highscores, hirelings, hunt analyzer, imbuements, market, prey, proficiency, quests, supply stash/tracker, task board/hunting, wheel, mounts, party analyzer | ✂️ quase tudo; ✅ `market`, `highscores`, `quests`, `player`, `misc_analyzer`; 🔁 `task_board` (encomendas), `daily_reward` |
| `actions/others` | 44 | **`flower_pot`, `blueberry_bush`, `create_bread`, `food`, `fluids`, `decayto`, `transforms`**, `construction_kits`, `bed_modification_kits`, piggy bank, festas/presentes etc. | 🔁 os em negrito são a base da fazenda; ✂️ itens de evento |
| `actions/tools` | 12 | **`fishing`, `juice_squeezer`**, `saw`, `skinning`, `crusher`, `tools` (pá/corda/picareta) | 🔁 ferramentas da fazenda |
| `actions/systems` | 11 | forge, imbuing, market, supply stash, daily reward, workbench, boss room | ✅ market, 🔁 workbench (crafting), ✂️ resto |
| `actions/quests`, `quests/`, `soulpit` | 10 | quests de exemplo, soulpit | ✂️ |
| `movements/others` | 15 | **`seeds.lua`, `dough.lua`, `cake.lua`, `decay.lua`**, `tiles`, `walkback`, `closing_door`, `drowning`, `_swimming`, `snow`, `trap` | 🔁 sementes/massa/bolo; ✅ tiles/portas |
| `movements/system` | 9 | teleport, trainers, instâncias de forge/imbuement/dungeon, boosted | ✂️ instâncias e boosted |
| `creaturescripts/` | 15 | login/logout, morte, loot, firstitems, stamina, offline training, bestiary, bounty, imbuing | ✅ login/morte/firstitems; ✂️ bestiary, bounty, imbuing |
| `eventcallbacks/` | 21 | callbacks padrão (look, mover item, troca, experiência) | ✅ |
| `globalevents/` | 15 | server save, startup, map cleaner, record, time sync; boosted, hirelings, imbuement station, influenced spawn, market deliveries, portal effects, guild war | ✅ save/startup/cleaner/time sync/market; ✂️ resto |
| `magic-roulette-master/` | 15 | roleta | ✂️ |
| `resetsystem/` | 7 | reset de nível | ✂️ |
| `monster_level_system/`, `echo/`, `spy/` | 5 | níveis de monstro, echo raid, spy | ✂️ |
| `chatchannels/` | 8 | canais (world, help, trade, loot, GM) | ✅ |
| `weapons/` | 10 | armas | ✅ se houver combate |

## Dados e configuração

| Item | Sugestão |
|---|---|
| `items.otb` / `items.xml` (17.411 itens Tibia) | Substituir pela lista de itens do Backlands quando a arte 16px existir (o conversor em `tools/assets` serve só para teste) |
| `world/world.otbm` + casas/spawns | ✂️ substituir pelo mapa do Backlands feito no NexaMap 16px |
| `XML/vocations.xml` (Sorcerer, Druid, Paladin, Knight, Monk + promoções) | 🔁 trocar por "classes" do fazendeiro ou uma vocação única |
| `XML/outfits.xml`, `mounts.xml` | 🔁 (montarias = cavalo/carroça) |
| `XML/imbuements.xml`, `smart_pointer_stress.xml` | ✂️ |
| `XML/zone_weather.xml` | 🔁 clima por zona (chuva molhando a lavoura) |
| `raids/` | ✂️ ou 🔁 como "praga" |
| `store/` | ✂️ até definir monetização |
| `schema.sql` → conta padrão | ✂️ antes de produção |
| `key.pem` | trocar (ver [03-cliente-web.md](03-cliente-web.md)) |

## Código C++ (`server/src/`) ligado a sistemas dispensáveis

Não precisa apagar C++ para desligar um sistema (os flags do `config.lua` bastam). Se quiser emagrecer o binário depois:
`bestiary_charm.*`, `character_bazaar.*`, `echo_raid.*`, `familiar.*`, `imbuement.*`, `weapon_proficiency.*`,
`rewardchest.*`, `stash.*`, `spy.*`, `protocolspectator.*`, `stress_test.*`, `store/`. Isso exige mexer em
`game.cpp`/`player.cpp`/`protocolgame.cpp`, então fica para quando o jogo estiver jogável.

## Progresso da limpeza

**Rodada 1 (2026-11-10)**: foram removidos 3.388 arquivos e cerca de 385 mil linhas.

| Área | Feito |
|---|---|
| `config.lua.dist` | `reloadCommandEnabled`, `gameStore` e `toggleChainSystem` passam a `false`. `adminPassword` fica `""`, o que desliga o protocolo admin. Os demais sistemas 15.x já vinham desligados. |
| `data/server_config.lua` | `hirelingSystemEnabled`, `astraHirelingProtocolEnabled`, `resetssystem` e `cleavesystem` passam a `false`, porque os scripts desses sistemas foram removidos. |
| `monsters/` | Ficam apenas `mammals`, `vermins`, `birds`, `plants` e `trainers` (177 tipos). Saem também `hideous_fungus` e `hive_overseer`, que invocavam monstros de pastas removidas. |
| `spells/spells_monsters/` | Ficam as 27 magias usadas pelos monstros mantidos. |
| `spells/` | Saem `familiar` e `soulpit`. As magias de jogador ficam para decisão de design. |
| `npc/crystalserver/` | Removida. |
| Sistemas | Saem `magic-roulette-master`, `resetsystem`, `monster_level_system`, `echo`, `spy`, `quests`, `actions/quests`, `actions/soulpit`, `talkactions/stress` e `god/stress`. |
| `network/` | Ficam `daily_reward`, `highscores`, `item_values`, `market`, `misc_analyzer`, `mounts`, `party_vitals`, `player`, `quests`, `task_board`, `task_hunting` (dependência do `task_board`) e `unjustified_points`. |
| globalevents, creaturescripts, movements, actions | Saem boosted, hirelings, imbuement, influenced spawn, portal effects, bestiary, bounty, boss room/lever, forge, supply stash e as instâncias. |
| talkactions | Saem chain, cleave, promotion e find_influenced. |
| `raids/` | O raid de dragões foi removido e o `raids.xml` ficou vazio. |

O mapa de exemplo ainda tem spawns de monstros removidos. Isso gera avisos `can not find` no boot, mas não impede a subida. Os avisos somem quando o mapa for trocado (etapa 3).

## Ordem sugerida de limpeza

1. Desligar flags no `config.lua` (sem apagar nada) e subir o servidor para confirmar que funciona.
2. Apagar monstros/NPCs/spells em massa → reiniciar → corrigir referências quebradas no log.
3. Trocar o mapa por um mapa mínimo do Backlands.
4. Trocar itens (`items.otb`/`items.xml`) junto com os assets 16px.
5. Por último, remover código C++ de sistemas que não voltarão.
