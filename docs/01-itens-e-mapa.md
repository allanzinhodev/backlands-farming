# Flags e atributos de itens e mapa

## Quem lê o quê

| Arquivo | Lido por | Conteúdo |
|---|---|---|
| `.spr` | cliente, editor | só pixels (RLE por sprite). **O servidor nunca lê.** |
| `.dat` | cliente, editor | aparência: flags visuais/físicas, tamanho, camadas, animação, offsets |
| `items.otb` | servidor, editor | flags "físicas" do item + mapeamento de IDs |
| `items.xml` | servidor | regras de jogo: nome, peso, ataque, decay, tipo... |
| `.otbm` | servidor, editor | o mapa: tiles, itens nos tiles, zonas, casas, cidades, waypoints |
| `*-spawn.xml`, `*-house.xml` | servidor, editor | spawns de monstros/NPCs, casas |

Esta base é **ClientID-native**: o servidor indexa itens pelo ID do cliente (`items.cpp`, `items[clientId]`),
então o ID no `.dat`, no `.otb` e no `items.xml` é o mesmo número. Isso simplifica muito a pipeline de assets.

**Impacto do 16x16:** o servidor trabalha em tiles, não em pixels — nada muda nele. Só cliente, editor e
os valores em pixels do `.dat` (`Displacement`, `Elevation`, offsets de light) mudam de escala.

---

## 1. `.dat` — flags de aparência (protocolo 8.60)

Fonte: `AstraClient/src/client/thingtype.h`. Em 8.60 o byte da flag no arquivo = valor abaixo; a lista termina com `0xFF`.

| Byte | Flag | Dados extras | Uso no jogo de fazenda |
|---|---|---|---|
| 0x00 | Ground | u16 velocidade | terra, grama, solo arado (velocidade de andar) |
| 0x01 | GroundBorder (clip) | — | bordas de terreno |
| 0x02 | OnBottom | — | paredes, cercas |
| 0x03 | OnTop | — | portas abertas, topo de árvore |
| 0x04 | Container | — | baú, cesto, silo |
| 0x05 | Stackable | — | sementes, colheita, moedas |
| 0x06 | ForceUse | — | |
| 0x07 | MultiUse | — | ferramentas "use com" (enxada, regador) |
| 0x08 | Writable | u16 max chars | placas |
| 0x09 | WritableOnce | u16 max chars | |
| 0x0A | FluidContainer | — | balde, regador |
| 0x0B | Splash | — | poça d'água |
| 0x0C | NotWalkable | — | |
| 0x0D | NotMoveable | — | plantações fixas |
| 0x0E | BlockProjectile | — | |
| 0x0F | NotPathable | — | |
| 0x10 | Pickupable | — | |
| 0x11 | Hangable | — | quadros/decoração de parede |
| 0x12 | HookSouth | — | |
| 0x13 | HookEast | — | |
| 0x14 | Rotateable | — | móveis |
| 0x15 | Light | u16 intensidade, u16 cor | lampião, fogueira |
| 0x16 | DontHide | — | |
| 0x17 | Translucent | — | |
| 0x18 | Displacement | u16 x, u16 y (**pixels**) | **reescalar para 16px** |
| 0x19 | Elevation | u16 (**pixels**) | **reescalar para 16px** |
| 0x1A | LyingCorpse | — | |
| 0x1B | AnimateAlways | — | moinho, água |
| 0x1C | MinimapColor | u16 | cor no minimapa |
| 0x1D | LensHelp | u16 | |
| 0x1E | FullGround | — | |
| 0x1F | Look (ignore look) | — | |

Após as flags vem a geometria: `width`, `height` (em tiles), `exactSize` (se >1x1), `layers`,
`patternX/Y/Z`, `frames`, e a lista de sprite IDs. Com 16px, `exactSize` passa a significar 16 px por tile.

Flags extras que o AstraClient adiciona (WearOut, ClockExpire, Expire, ExpireStop, Market, Wrapable...)
são de versões novas e só existem se o `.dat` for gerado nesse formato estendido.

## 2. `.spr`

Cabeçalho: assinatura u32 + quantidade (u16, ou u32 com a feature `GameSpritesU32`) + tabela de offsets u32.
Cada sprite: cor-chave (3 bytes) + tamanho u16 + RLE de pares (transparentes u16, coloridos u16 + RGB).
O formato **não guarda a dimensão** — todo leitor assume 32x32 (1024 pixels). Para 16x16 (256 pixels)
leitor e escritor precisam concordar. Ver [04-map-editor-16px.md](04-map-editor-16px.md).

---

## 3. `items.otb` — flags (servidor + editor)

Fonte: `forgottenserver/src/itemloader.h`. Grupos: `ground, container, splash, fluid, charges` (os outros estão deprecated).

| Flag | Bit | Flag | Bit |
|---|---|---|---|
| BLOCK_SOLID | 0 | ALWAYSONTOP | 13 |
| BLOCK_PROJECTILE | 1 | READABLE | 14 |
| BLOCK_PATHFIND | 2 | ROTATABLE | 15 |
| HAS_HEIGHT | 3 | HANGABLE | 16 |
| USEABLE | 4 | VERTICAL | 17 |
| PICKUPABLE | 5 | HORIZONTAL | 18 |
| MOVEABLE | 6 | ALLOWDISTREAD | 20 |
| STACKABLE | 7 | LOOKTHROUGH | 23 |
| FLOORCHANGE* | 8–12 (sem uso) | ANIMATION | 24 |
| | | FORCEUSE | 26 |

Atributos OTB: `SERVERID, CLIENTID, NAME, SPEED, SLOT, MAXITEMS, WEIGHT, MINIMAPCOLOR, LIGHT2, TOPORDER, WAREID, CLASSIFICATION, SPRITEHASH`.

## 4. `items.xml` — atributos de jogo (237 chaves)

Fonte: `items.cpp` (`ItemParseAttributesMap`). Agrupados pelo que importa para fazenda:

| Grupo | Chaves | Relevância |
|---|---|---|
| **Básico** | `type, description, weight, showcount, moveable, pickupable, blockprojectile, allowpickupable, stacksize, worth, primarytype` | alta |
| **Crescimento / tempo** | `decayto, duration, showduration, transformto, destroyto, expire, expirestop, clockexpire, wearout, stopduration` | **alta** — plantas crescendo = `decayto` + `duration` |
| **Uso / ferramentas** | `rotateto, transformequipto, transformdeequipto, charges, showcharges, script` | alta (enxada, regador com cargas) |
| **Container** | `containersize, fluidsource, corpsetype` | alta (baús, silos, balde) |
| **Casa / mobília** | `floorchange, leveldoor, partnerdirection, maletransformto, femaletransformto, malesleeper, femalesleeper, wrapableto, walkstack, blocking, replaceable` | média (fazenda = casa) |
| **Texto** | `readable, writeable, maxtextlen, writeonceitemid, allowdistread` | baixa |
| **Combate básico** | `attack, defense, extradef, armor, weapontype, slottype, ammotype, shoottype, range, hitchance, maxhitchance, effect, attackspeed, elementfire/ice/earth/energy/death/holy` | média |
| **Stats de equipamento** | `speed, healthgain, managain, healthticks, manaticks, maxhitpoints*, maxmanapoints*, skill*, magicpoints*, invisible, manashield` | média |
| **Combate avançado** | `absorbpercent*` (16), `reflectpercent*`/`reflectchance*` (32), `boostpercent*` (16), `magiclevel*`/`*magiclevelpoints` (~30), `criticalhit*`, `lifeleech*`, `manaleech*`, `perfectshot*`, `suppress*`, `fieldabsorbpercent*` | **baixa — candidato a ignorar** |
| **Sistemas 15.x** | `imbuementslot, tier, classification, upgradeclassification, augments, elementalbond, mantra, experiencerate*, reduceskillloss, supply, storeitem, loottype, drop` | baixa |

Tipos (`type=`): `key, magicfield, container, depot, mailbox, trashholder, teleport, door, bed, rune, rewardchest, carpet, food, potion, valuable, creatureproduct, tool, decoration`.
Para fazenda os úteis são: `container, depot, mailbox, door, bed, food, tool, decoration, carpet, key`.

---

## 5. `.otbm` — mapa

Fonte: `iomap.h`, `item.h`, `tile.h`.

**Nós:** `ROOTV1, MAP_DATA, ITEM_DEF, TILE_AREA, TILE, ITEM, TILE_SQUARE, TILE_REF, SPAWNS, SPAWN_AREA, MONSTER, TOWNS, TOWN, HOUSETILE, WAYPOINTS, WAYPOINT, TILE_ZONE`.

**Flags de tile no mapa:** `PROTECTIONZONE`, `NOPVPZONE`, `NOLOGOUT`, `PVPZONE`, `ZONE` (zonas nomeadas — útil para "área de fazenda", "cidade", "área de combate").

**Atributos de item no mapa/save** (`ATTR_*`): `TILE_FLAGS, ACTION_ID, UNIQUE_ID, TEXT, DESC, TELE_DEST, ITEM, DEPOT_ID, RUNE_CHARGES, HOUSEDOORID, COUNT, DURATION, DECAYING_STATE, WRITTENDATE, WRITTENBY, SLEEPERGUID, SLEEPSTART, CHARGES, CONTAINER_ITEMS, NAME, ARTICLE, PLURALNAME, WEIGHT, ATTACK, DEFENSE, EXTRADEFENSE, ARMOR, HITCHANCE, SHOOTRANGE, CUSTOM_ATTRIBUTES, SPECIAL, WRAPID, STOREITEM, ATTACK_SPEED, CLASSIFICATION, TIER, REWARDID, REFLECT, BOOST, IMBUESLOTS, IMBUEMENTS`.

Para fazenda o mais importante é **`ACTION_ID`/`UNIQUE_ID`** (ligar scripts a tiles/itens),
**`DURATION`/`DECAYING_STATE`** (estado de crescimento persistido) e **`CUSTOM_ATTRIBUTES`**
(guardar "regada em", "qualidade", "dono" sem mexer em C++).

**Estados de tile em runtime** (`TILESTATE_*`): floorchange (6 direções), protection/nopvp/pvp/nologout zone,
teleport, magicfield, mailbox, trashholder, bed, depot, blocksolid/blockpath (+ variantes imóveis), supports_hangable.
