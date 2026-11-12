# Perspectiva top-down dos andares

No Tibia clássico, cada andar acima é desenhado deslocado **um tile para cima e um para a
esquerda** (diagonal). No Backlands, o deslocamento é **só para cima**: o andar `z-1` aparece
uma linha acima do andar `z`, na mesma coluna.

```
clássico (diagonal)             Backlands (top-down)
andar z-1 em (x-1, y-1)         andar z-1 em (x, y-1)
```

## Onde está implementado

Servidor, cliente e editor precisam usar o mesmo valor. O servidor escolhe quais tiles de
cada andar envia, e o cliente posiciona esses tiles na tela. Se os valores forem diferentes,
o cliente mostra os andares de cima com uma coluna errada.

| Peça | Constante | Valor |
|---|---|---|
| Servidor | `tfs::FLOOR_SHIFT_X` em `server/src/position.h` | `0` |
| Cliente (AstraClient web) | `FLOOR_SHIFT_X` em `src/client/position.h`, via `tools/astra-web/patches/backlands-topdown.patch` | `0` |
| Map editor | `FloorShiftX` em `map-editor/source/definitions.h`, opção CMake `NEXAMAP_TOPDOWN_FLOORS` (padrão `ON`) | `0` |

Com o valor `1`, tudo volta ao comportamento clássico.

### Servidor

- Descrição de andares (`GetFloorDescription`): o deslocamento por andar vale só para Y.
- Visão (`ProtocolGame::canSee`, `Creature::canSee`) e espectadores (`Map::getSpectatorsInternal`):
  a faixa horizontal não muda entre andares.
- Troca de andar (`MoveUpCreature`, `MoveDownCreature`): só a linha norte ou sul é reenviada.
  As colunas oeste e leste não são mais enviadas.

### Cliente

- `Position::coveredUp` e `Position::coveredDown`: o tile que cobre `(x, y, z)` está em `(x, y+1, z-1)`.
- `MapView::transformPositionTo2D`: a posição na tela não desloca X entre andares.
- `parseFloorChangeUp`, `parseFloorChangeDown` e `setFloorDescription` seguem o servidor.

### Editor

- Desenho dos andares (`map_drawer`, `minimap_page_cache`, `light_drawer`), clique e seleção
  (`map_display`, `selection`), centralização (`map_window`) e retângulo do minimapa.
- Seleção compensada: ao subir um andar, a seleção desloca só em Y.

## Consequências para o mapa

- Construções de vários andares devem ser alinhadas pela coluna, não pela diagonal. O andar
  de cima de uma casa fica exatamente sobre ela, uma linha acima na tela.
- Mapas feitos para a perspectiva diagonal (por exemplo, o `world.otbm` de exemplo) aparecem
  com os andares superiores deslocados uma coluna.
- O `Elevation` dos itens (pilhas, mesas) continua diagonal no cliente e no editor. Se quiser
  que a elevação também suba só em Y, é uma mudança separada.
