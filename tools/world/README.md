# Mapa inicial do Backlands

`python tools/world/create_starter_world.py` gera os três arquivos de
`server/data/world`. Use `--check` para conferir os arquivos sem alterá-los ou
`--output caminho` para preparar uma cópia no NexaMap.

O mapa usa OTBM 2 e os **ClientIDs** do `items.otb` atual. Os gráficos são os
assets provisórios 16×16 já disponíveis em `assets/860`; os itens poderão ser
substituídos pela arte original do Backlands quando ela existir.

- Cidade 1: **Backlands**. Templo e entrada: **100, 100, 7**.
- Área: x=80…126, y=80…122, andar 7, 2.021 tiles.
- Praça protegida, cabana pública com entrada pelo sul, oito fileiras de terra,
  pequeno lago para pesca, arbustos e pasto com duas galinhas, um porco e uma ovelha.
- Trigo maduro em 107, 91, 7 e 112, 91, 7 para testar a foice; os outros quatro
  pés mostram estágios anteriores. O lago usa água 4597, que permite pescar.
- Seed Vendor em 102, 98, 7; Harvest Buyer em 98, 98, 7.
- Um coelho fica próximo ao lago e um rato próximo aos canteiros. São seis
  spawns de animais de cinco tipos; os outros monstros antigos não são usados.
- Os 61 imóveis e os spawns antigos foram removidos. A cabana é pública e não
  exige comprar uma casa para entrar.
- Vocação 0: Farmer; outfits iniciais 128 masculino / 136 feminino. Não há
  montarias habilitadas enquanto a arte de cavalo/carroça do Backlands não existir.

A terra cultivável usa o item **103 (dirt)**: o item 101 (earth) bloqueia passagem
no DAT atual. O gerador verifica que o templo, os NPCs, os animais e os principais
pontos do mapa são alcançáveis a pé. O servidor carrega os itens e valida o OTBM
com os mesmos leitores usados pelo mapa de produção.

O arquivo é determinístico. Se o mapa for editado manualmente no NexaMap,
preserve essa versão e pare de executar o gerador sobre ela; `--check` deve
apontar a diferença em vez de substituir as edições.
