# Backlands Asset Studio

Editor desktop de **DAT/SPR 8.60 com sprites nativos de 16×16 pixels**, inspirado no
[ObjectBuilder de punkice3407](https://github.com/punkice3407/ObjectBuilder).
Implementação em Python/Tk, integrada ao formato deste projeto. Não depende de Adobe AIR.

## Executar

Requer Python 3.10 ou superior com Tk e Pillow. No Windows, o instalador do Python inclui Tk.
Na raiz do repositório:

```powershell
python -m pip install -r object-editor/requirements.txt
python object-editor/main.py
```

Também pode abrir `Backlands-Asset-Studio.cmd` com duplo clique, depois de instalar a dependência.
Sem argumentos, o editor reabre o último projeto usado. Na primeira execução,
procura os assets do jogo em `assets/860/Tibia.otfi`, na raiz do repositório.
Uma pasta ou um OTFI passado na linha de comando tem prioridade. A preferência
fica em `%LOCALAPPDATA%/Backlands/AssetStudio/settings.json` no Windows.
Para abrir um projeto ou validar arquivos sem interface:

```powershell
python object-editor/main.py "C:\assets-backlands\Tibia.otfi"
python object-editor/main.py --check "C:\assets-backlands"
```

Para experimentar com seis objetos de fazenda originais (grama, terra, plantas e caixa):

```powershell
python object-editor/examples/create_demo.py object-editor/out/demo
python object-editor/main.py object-editor/out/demo
```

## Uso

1. Clique em **Novo**. O padrão é 8.60, RGB e IDs de sprites de 16 bits. Escolha
   as extensões do seu cliente se precisar de IDs de 32 bits, alpha parcial, duração
   por quadro ou grupos de animação de criaturas. O primeiro item tem ID 100.
2. Importe um PNG na **Biblioteca de sprites**. Suas dimensões devem ser múltiplos
   de 16. As células são importadas da esquerda para a direita e de cima para baixo,
   sem redimensionamento. Células transparentes mantêm sua posição.
3. Selecione uma categoria e um objeto. Ajuste tiles, camadas, padrões e quadros
   em **Geometria**. Defina flags na aba **Flags** e clique em **Aplicar propriedades**.
   Os campos numéricos aceitam decimal ou `0x` hexadecimal; campos múltiplos usam CSV.
   Exemplo de deslocamento: `8, 8`. No nome de mercado, use aspas se houver vírgula.
4. Na aba **Sprites / slots**, selecione um slot; na biblioteca selecione o sprite
   e clique em **Vincular ao slot**. O sprite 0 representa transparência.
   Os seletores de quadro e X/Y/Z da prévia determinam os slots exibidos.
5. Em **Editor de pixels 16×16**, use lápis, borracha, preenchimento e conta-gotas.
   O botão direito captura a cor. Ctrl+Z e Ctrl+Y desfazem e refazem até 200 alterações
   de pixels da sessão. Uma sprite pode ser compartilhada por vários objetos;
   editar seus pixels altera todos os objetos que a referenciam.
6. Clique em **Salvar como** e escolha uma pasta. O editor grava `Tibia.dat`,
   `Tibia.spr` e `Tibia.otfi`. Ao abrir um projeto existente, preserva nomes,
   assinaturas e IDs. Propriedades pendentes são aplicadas antes de salvar ou trocar de objeto.

Novos objetos e sprites são acrescentados ao fim. Duplicar um objeto copia sua
geometria e flags, mantendo as referências às sprites. Para criar arte independente,
importe outra sprite e vincule seu novo ID. Não há exclusão que renumere IDs existentes.

## Grupos e quadros de animação

A aba **Animação / frame groups** permite selecionar, criar, duplicar e remover
grupos. No DAT clássico, criaturas aceitam os grupos **parado/padrão (0)** e
**andando (1)**, um de cada tipo. Itens, efeitos e projéteis animam os quadros de
seu grupo único. Grupos adicionais de ações futuras exigirão suporte no cliente
e em outro formato; o editor mantém o DAT compatível com esta base.

É possível inserir quadros vazios, duplicar, remover e mover quadros para cima ou
baixo, preservando todas as camadas, tiles e padrões de cada quadro. Sprites de
quadros removidos continuam na biblioteca. Edite o mínimo/máximo em milissegundos
por quadro, modo, ciclos e quadro inicial e clique em **Aplicar animação**.
O desenho dos quadros usa os mesmos slots e ferramentas de pixels do editor.

As extensões podem ser ativadas num projeto existente. Ativar grupos preserva
os quadros e referências das criaturas; ativar durações inicializa as animações
existentes com 150 ms por quadro. DAT e OTFI são atualizados juntos ao salvar.

## Folhas de objetos

**Exportar folha do objeto** inclui todas as camadas, padrões e quadros do **grupo
atual**, sem misturá-los. Cada célula mede `largura_em_tiles × 16` por
`altura_em_tiles × 16` pixels. Posição da célula, com índices começando em zero:

```text
coluna = padrão_X × camadas + camada
linha  = (quadro × padrões_Z + padrão_Z) × padrões_Y + padrão_Y
```

Dentro da célula, o tile x=0,y=0 fica no canto inferior direito, conforme a ordem
do DAT do cliente. **Importar folha do objeto** exige exatamente essas dimensões
para a geometria atual e cria novos IDs, preservando sprites compartilhadas.
Exporte, edite a imagem e importe novamente para manter a disposição.
**Exportar PNG da prévia** exporta só a composição e seleção atual, na resolução original.

## Itens do servidor: XML e OTB

A aba **Itens do servidor** associa o projeto visual ao `items.xml` e ao
`items.otb`. Nos assets deste repositório, o editor encontra automaticamente
`server/data/items/`. Também é possível escolher cada arquivo com **Associar**.
O vínculo é salvo em `backlands-project.json` ao lado do OTFI, usando caminhos
relativos quando possível. O diretório de assets do jogo já fica associado aos
arquivos reais do servidor.

A seleção e a pesquisa de itens passam a mostrar o nome do XML. A associação
usa **ID do DAT = ClientID do OTB = id do XML**, conforme o servidor desta base.
O ServerID legado é exibido para consulta e preservado.

- Em **Definição XML do item**, edite o elemento completo: nome, artigo, plural,
  peso, tipo, duração, transformação e demais atributos, inclusive os aninhados.
  O ID deve ser mantido. Editar um item de um intervalo divide somente essa entrada,
  preservando o restante da faixa, comentários e texto externo ao item.
- Em **Propriedades OTB**, ajuste grupo, flags físicas, velocidade, minimapa,
  luz, ordem superior e Ware ID. Flags e atributos desconhecidos são preservados.
- **Criar registros ausentes** acrescenta o item selecionado com o mesmo ClientID.
  Isso também permite cadastrar no servidor novos itens criados no DAT. A criação
  é explícita; o catálogo não é regenerado a partir do DAT.
- **Copiar flags do DAT → OTB** sincroniza as propriedades físicas compatíveis
  do item selecionado, inclusive animação, uso, camadas superiores, chão e luz.
  Use **Aplicar dados do servidor** para validar edições manuais em memória.

**Salvar / Ctrl+S** grava os assets e os catálogos associados que foram editados,
com backups e recuperação conjunta em caso de erro. Alterar apenas sprites ou
animações não regrava o XML/OTB. Se outro programa alterar um catálogo pendente,
o salvamento é bloqueado para evitar sobrescrever a outra edição; reassocie o
arquivo atualizado antes de continuar.

Ao usar **Salvar como** em um projeto já salvo, os catálogos associados são
copiados para `server-items/` dentro da pasta exportada, e a cópia passa a apontar
para esses arquivos. Os originais do servidor permanecem intactos. No primeiro
salvamento de um projeto novo, arquivos associados manualmente são gravados nos
caminhos escolhidos e exibidos no painel.

## Compatibilidade e arquivos

- Formato DAT da família **8.60**, com flags de 0 a 37 reconhecidas pela base
  do projeto. Outros protocolos, flags desconhecidas e arquivos inconsistentes são rejeitados.
  Uma assinatura diferente não converte automaticamente o layout para 8.60.
- Extensões explicitadas em OTFI: `extended`, `transparency`, `frame-durations`
  e `frame-groups`. Grupos adicionais pertencem a criaturas.
- O OTFI grava `sprite-size: 16` e `sprite-data-size: 1024`. O SPR sozinho
  **não informa a dimensão**. Ao abrir uma pasta sem OTFI, confirme o formato
  explicitamente. Nunca declare um SPR 32×32 como se fosse 16×16.
- RGB aceita alpha 0 ou 255; RGBA aceita alpha parcial. PNGs com alpha parcial são
  rejeitados em projetos RGB, evitando perda silenciosa de informação.
- Deslocamento, elevação e tamanho exato são editados em pixels reais de 16px,
  sem escala automática. Geometria usa tiles, não pixels.
- O [NexaMap](../map-editor) precisa ser compilado com
  `-DNEXAMAP_SPRITE_PIXELS=16`. A ferramenta de migração clássica do NexaMap
  ainda contém restrições a 32px; este editor não altera essa ferramenta.
- `items.otb` e `items.xml` podem ser associados e editados no projeto. Atlas do
  futuro cliente web e mapas OTBM permanecem separados. Criar uma aparência não
  define automaticamente regras de jogo; cadastre seus registros na aba de servidor.

Para os assets antigos de 32px, use o conversor de teste já existente:

```powershell
python tools/assets/spr_dat_resize.py "C:\assets-32" "C:\assets-16"
```

Ele reescala arte e propriedades em pixels; arte final deve ser desenhada em 16px.

## Salvamento e limites

Antes de sobrescrever, o editor valida referências, serializa e relê os dois
arquivos binários. Arquivos anteriores são copiados para `.backups/<data-hora-id>/`
ao lado dos arquivos originais, inclusive nos diretórios dos catálogos do servidor.
A gravação usa arquivos temporários no mesmo sistema de arquivos de cada destino
e restaura os originais se uma substituição falhar. Isso trata erros de gravação;
arquivos separados não constituem uma transação garantida em caso de queda de energia.

Limites de proteção: 262.144 referências por grupo, 2 milhões de sprites no formato
estendido, PNG com até 8.192 pixels por lado e 16.777.216 pixels no total.
Projetos grandes podem levar alguns segundos para abrir ou salvar.

## Verificação

```powershell
python -m unittest discover -s object-editor/tests -v
```

Testes verificam bytes independentes dos formatos, IDs, ordem dos tiles,
extensões, importação PNG e recuperação após falha de gravação. Os testes de interface
precisam de uma sessão gráfica com Tk. Não há assets reais DAT/SPR versionados neste
repositório; a verificação binária usa fixtures construídas independentemente.

## Referência

Foram consultados os leitores/escritores de metadados, sprites, grupos de animação
e OTFI do ObjectBuilder no commit `b07f254d63e64824343d12f526dbdc20dd4a3c5b`.
O editor é uma implementação própria do fluxo e formato; não é uma cópia completa
dos recursos ou do suporte a versões do ObjectBuilder. Ver [THIRD_PARTY.md](THIRD_PARTY.md).
