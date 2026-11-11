# Monstros do Backlands

Pasta vazia de propósito: os monstros de Tibia foram removidos (limpeza rodada 2).
O servidor exige que esta pasta exista. Novas criaturas (RevScript) entram aqui:

```lua
local mType = Game.createMonsterType("Nome")
local monster = {}
-- ...
mType:register(monster)
```
