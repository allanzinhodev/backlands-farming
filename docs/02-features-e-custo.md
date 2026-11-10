# Features do servidor e custo de infraestrutura

Ordenado do **maior para o menor custo de infra**. Os níveis são estimativa pela arquitetura do código
(o que roda por tick, por jogador, por item ou no banco), **não foram medidos**. Para medir de verdade:
`performanceMetricsEnabled = true` e `statsEnabled = true` no `config.lua` durante um teste de carga.

Coluna "Sugestão" é ponto de partida para um jogo de fazenda com combate secundário — **a decisão é sua**.

Legenda: 🔴 alto · 🟠 médio · 🟢 baixo

## A. Núcleo — não dá para desligar, mas dá para dimensionar

| # | Feature | Custo dominante | Nível | Sugestão |
|---|---|---|---|---|
| 1 | **Mapa inteiro em RAM** (`map.cpp`, `mapcache.cpp`, `mapCacheMode`) | RAM proporcional a tiles × itens; todo item de cada tile fica carregado | 🔴 | Mapa enxuto. Plantações = itens nos tiles → RAM cresce com o número de canteiros. |
| 2 | **Persistência de casas** (`iomapserialize.cpp` → tabela `tile_store`) | No server save, **todos os itens de todos os tiles de casa** são serializados e regravados no banco | 🔴 | É o maior risco específico de fazenda: se cada fazenda é uma casa cheia de plantas, o save cresce linearmente. Considere guardar o estado do canteiro numa tabela própria / KV em vez de itens. |
| 3 | **Save de jogadores** (`save_manager.cpp`, `iologindata.cpp`, `player_save_async_pending`) | I/O no MariaDB em logout, intervalo e server save (inventário, depot, storage) | 🔴 | Manter; limitar tamanho de depot (`depotFreeLimit`) e de inventário de colheita. |
| 4 | **Decay** (`decay.cpp`) — base do crescimento de plantas via `decayto`/`duration` | CPU por item em decaimento; escala com nº de plantas ativas | 🟠→🔴 | Alternativa barata: crescimento por **timestamp** (calcula o estágio quando o jogador olha/usa) = ~zero CPU. |
| 5 | **Rede do jogo** (`protocolgame.cpp`, XTEA, `networkThreads`) | Banda e CPU por jogador conectado; viewport fixo 18x14 tiles (`Map::maxClientViewport*`) | 🟠 | Com 16px a tela cabe mais tiles; **aumentar o viewport aumenta banda por jogador** e exige mudar servidor + cliente juntos. |
| 6 | **Bridge WebSocket→TCP** (necessária para cliente web) | Processo extra + TLS (WSS) | 🟠 | Obrigatória para web. Ver [03-cliente-web.md](03-cliente-web.md). |
| 7 | **Banco MariaDB** (63 tabelas em `schema.sql`) | Serviço gerenciado/VPS, backup | 🟠 | Tabelas de features desligadas ficam vazias; dá para podar depois. |

## B. IA e mundo — maior custo de CPU

| # | Feature | Config | Custo | Nível | Sugestão |
|---|---|---|---|---|---|
| 8 | **Monstros + pathfinding** (`monster.cpp`, `spawn.cpp`) | `rateSpawn`, `spawnMultiplier`, spawns do mapa | CPU por monstro × jogadores perto | 🔴 | Poucas áreas de combate, spawns pequenos. |
| 9 | **Facções de monstros** (monstro × monstro) | `monsterFactionSystem` | IA rodando mesmo sem combate de jogador | 🔴 | **Desligar** |
| 10 | Raids / Echo Raid / Influenced spawn / Boosted creature & boss | `echoRaidSystemEnabled`, `data/raids`, globalevents | spawns em massa, timers | 🟠 | Desligar (ou reaproveitar raid como "praga na lavoura" no futuro) |
| 11 | **Hirelings** (NPC por jogador) | `hirelingSystemEnabled = true` (**ligado por padrão**) | 1 criatura com IA por jogador | 🟠 | Desligar agora; pode virar "ajudante da fazenda" depois |
| 12 | NPCs (`npc.cpp`, `npcSystem`) | — | think por NPC | 🟢 | Manter (lojas de sementes/compra de colheita) |
| 13 | Familiars / Summons | `familiarSystemEnabled` | IA extra | 🟢 | Desligado (padrão) |
| 14 | Monster levels | `monsterLevelEnabled` | cálculo por monstro | 🟢 | Desligado |

## C. Combate extra — CPU por ataque e pacotes extras

| # | Feature | Config | Nível | Sugestão |
|---|---|---|---|---|
| 15 | Chain system (ataque que pula entre alvos, eventos agendados) | `toggleChainSystem = true` | 🟠 | **Desligar** |
| 16 | Cleave (dano em área melee) | `cleavesystem = true` (server_config.lua) | 🟠 | Desligar |
| 17 | `classicAttackSpeed` | o próprio config avisa de CPU alto | 🟠 | Manter `false` |
| 18 | Marcas de swing melee (opcode 0x93, pacote extra por golpe) | `meleeWeaponSwingMarksEnabled = true` | 🟢 | Desligar |
| 19 | Dual wield | `allowDualWielding` | 🟢 | Desligado |
| 20 | PvP / skulls / guild war | `worldType`, `killsToRedSkull`... | 🟢 | `worldType = "no-pvp"` provavelmente |

## D. Sistemas de economia e monetização — custo em banco e operação

| # | Feature | Config | Custo | Nível | Sugestão |
|---|---|---|---|---|---|
| 21 | **Market** | `marketSystemEnabled` | 4 tabelas, checagem de expiração, globalevent a cada 5 s | 🟠 | **Provável manter** — comércio de colheita entre jogadores |
| 22 | Game Store + coins | `gameStore = true` | tabelas, pagamento, suporte, legal | 🟠 (operação) | Desligar até ter monetização definida |
| 23 | Character Bazaar | `characterBazaarEnabled` | 3 tabelas, leilões | 🟠 | Desligado |
| 24 | Battle Pass | `battlePassSystemEnabled` | DB/estado por jogador | 🟢 | Desligado (talvez "temporada de colheita" no futuro) |
| 25 | Magic roulette | `data/scripts/magic-roulette-master` | DB `roulette_plays` | 🟢 | Remover |

## E. Progressão estilo Tibia 15.x — quase tudo dispensável para fazenda

Todos 🟢 a 🟠 (tabelas no banco, dados carregados no startup, cálculo por kill/item):
Bestiary/Bosstiary/Charms (`bestiarySystemEnabled`, carrega registro no startup), Prey, Forge, Imbuements
(decay por item imbuído), Wheel of Destiny, Weapon Proficiency, Augments, Task Board / Bounty / Weekly,
Soulpit, Soulseals, Monk, Reward chest de boss, Reset system (`resetssystem = true` — **ligado**),
Power-law skills, Experience/skill stages.

**Sugestão:** desligar todos. Reaproveitáveis com outro nome: *Task Board* → encomendas de colheita;
*Stamina* → energia diária do fazendeiro; *Offline training* → produção offline.

## F. Conveniências baratas

| Feature | Nível | Sugestão |
|---|---|---|
| Autoloot / Quickloot / AutoBank (`Autoloot_enabled`, `enableQuickLoot`) | 🟢 | Útil para colheita em massa; manter |
| Stamina (`staminaSystem`) | 🟢 | Reaproveitar como energia |
| Offline training em cama (`bedOfflineTraining`) | 🟢 | Desligar ou reaproveitar |
| Party, VIP, canais de chat, guildas | 🟢 | Manter (cooperativas = guildas) |
| Casas, aluguel, beds, mailbox, depot | 🟢 | **Manter** — base da posse de fazenda |
| Account Manager in-game (`accountManager = true`) | 🟢 | Desligar; criar conta pelo site (web) |
| Loot grouping, mensagens coloridas | 🟢 | indiferente |

## G. Portas e serviços auxiliares — custo de segurança/operação

| Serviço | Porta | Sugestão |
|---|---|---|
| Login | 7171 | Só acessível pela bridge (rede privada) se o cliente for só web |
| Game | 7172 | idem |
| Status protocol | 7171 | público só se quiser aparecer em listas de OT |
| **Admin protocol** (`adminPort`, `adminPassword = "admin"`) | 7170 | **Desligar em produção** ou manter só localhost com senha forte |
| Spectator/cast (`protocolspectator.cpp`) | — | banda extra por espectador; desligar |
| Spy (`spy.cpp`) | — | ferramenta de GM; avaliar |
| `stressTest*`, `performanceMetricsEnabled`, `statsEnabled` | — | só em teste |
| `reloadCommandEnabled = true` | — | o próprio config avisa que pode derrubar o servidor; desligar em produção |

---

### Resumo: o que mais pesa num jogo de fazenda

1. **Casas cheias de plantas** → save de `tile_store` + RAM. Decidir cedo como o canteiro é modelado.
2. **Decay como motor de crescimento** → CPU por planta. Timestamp é mais barato.
3. **Monstros/IA** → manter combate pequeno.
4. **Viewport** → se quiser mostrar mais tiles por causa do 16px, a banda por jogador sobe.
5. **Web** → bridge WSS é obrigatória e é um processo a mais para operar.
