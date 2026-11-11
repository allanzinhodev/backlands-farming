# Monstros do Backlands

O mapa inicial mantém cinco tipos de animais: **Chicken**, **Pig**, **Sheep**,
**Rabbit** e **Rat**. Há duas galinhas e um exemplar de cada outro tipo no mapa.
Galinhas, porco, ovelha e coelho são passivos; o rato é uma praga com ataque
corpo a corpo. Eles usam os gráficos provisórios do pacote 16×16 atual.

Essas definições foram recuperadas da base anterior à limpeza. Não dependem das
magias de monstros removidas. Os demais monstros e sistemas continuam removidos.
Novas criaturas usam RevScript:

```lua
local mType = Game.createMonsterType("Nome")
local monster = {}
-- ...
mType:register(monster)
```
