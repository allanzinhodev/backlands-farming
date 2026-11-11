# Teste local com AstraClient Web

O cliente roda em **http://127.0.0.1:8088/astraclient.html**. O servidor de
desenvolvimento usa a conta **fazenda**, senha **fazenda**, personagem
**Fazendeiro**. Esses dados existem somente no banco local de teste.

Inicie primeiro o servidor:

```powershell
python tools/dev/server.py start
```

Depois, abra o cliente já compilado:

```powershell
powershell -ExecutionPolicy Bypass -File tools/astra-web/start.ps1
```

No launcher, use **Install** na primeira vez e depois **Play**. A primeira
instalação transfere cerca de **309 MB** (294,49 MiB), incluindo os assets do
jogo e os recursos originais da interface Astra. Nas próximas aberturas o pacote
fica no cache local do navegador. Na tela do jogo,
preencha a conta e a senha, escolha **Backlands (local)** e entre com Fazendeiro.
O campo da conta pode aparecer como “Email”; aceita `fazenda` para o login TCP
local. Use as setas para andar. Os dados do jogo ficam no cache do navegador;
**Update** atualiza esse cache quando o pacote muda e **Reload / Repair** o
verifica novamente.

## Compilar novamente

São necessários Docker Desktop com containers Linux, Git, Node.js 22+ e os
arquivos locais `assets/860/Tibia.dat`, `Tibia.spr` e `Tibia.otfi` do editor.

```powershell
powershell -ExecutionPolicy Bypass -File tools/astra-web/build.ps1
```

A primeira compilação baixa o SDK Emscripten **6.0.8** e as dependências C++.
Os objetos ficam no volume Docker `backlandsofc-astra-build`, acelerando as
próximas compilações. Um snapshot temporário evita o custo de ler milhares de
arquivos pequenos através do bind mount do Windows.

O script prepara o clone de estudo em `_study/AstraClient`, fixado na revisão
`80c59ec7aab584b970b8a9d98cd8282e3b5fe136`, e aplica o patch em
`tools/astra-web/patches/backlands-16px.patch`. O clone, os assets e os binários
permanecem fora do Git. O patch faz o SPR respeitar `sprite-size: 16` no OTFI e
carrega o SPR antes do DAT, para a geometria também receber o tamanho correto.
Packs de 32 pixels continuam usando 32 quando o OTFI não define outro tamanho.
Frame groups e durações usam os recursos existentes do AstraClient, habilitados
pelo OTFI do projeto. O protocolo continua sendo **8.60**.

Para aplicar apenas a preparação do clone, sem compilar:

```powershell
powershell -ExecutionPolicy Bypass -File tools/astra-web/prepare.ps1
```

## Como a conexão funciona

```text
navegador → http://127.0.0.1:8088 → pacote WASM/WebGL2
         → ws://127.0.0.1:8088/login → backlandsofc-server:7171 (TCP)
         → ws://127.0.0.1:8088/game  → backlandsofc-server:7172 (TCP)
```

O container `backlandsofc-astra-web` participa da rede `bl-test` do servidor,
publicando somente a porta 8088 no loopback. Os demais serviços Docker da
máquina continuam independentes. A bridge aceita quadros binários, limita filas
e tamanho das mensagens e verifica a origem do navegador. O HTTP serve apenas
o diretório `dist`, com os cabeçalhos COOP/COEP necessários às threads WASM.
`config.js` é fornecido pela bridge com os destinos locais fixos.

O endpoint `http://127.0.0.1:8088/health` identifica a bridge em execução.
Ele confirma que o host web está ativo; o estado do jogo é consultado com
`python tools/dev/server.py status`.

```powershell
docker logs --tail 30 backlandsofc-astra-web
docker stop backlandsofc-astra-web
```

Este fluxo é para teste local. A publicação requer HTTPS/WSS e configuração
própria de contas e chaves, conforme [03-cliente-web.md](03-cliente-web.md).

## Validação da bridge

```powershell
cd tools/astra-web
npm.cmd ci --ignore-scripts
npm.cmd test
```

Os testes exercitam os dois destinos TCP, preservação dos bytes binários,
rejeição de origens externas e mensagens de texto, arquivos WASM, leitura por
intervalos e isolamento do diretório servido.

Validado em 2026-11-11: compilação WebAssembly concluída, auditoria do pacote com
5.038 arquivos aprovada e três testes da bridge passando. A preparação do clone
também foi executada em checkout limpo e repetida sem reaplicar o patch. No
Chromium, o login de Fazendeiro abriu o mapa com os dois NPCs; as setas moveram
o personagem de `(100,100,7)` para `(101,101,7)`. O console Lua do cliente
confirmou `g_sprites.spriteSize() == 16` antes e depois do movimento. As
capturas e o log dessa verificação local estão em `out/astra-web/`.
