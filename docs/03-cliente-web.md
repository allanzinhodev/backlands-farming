# Cliente web — stack e segurança (planejamento, sem implementação)

## Fato que muda a decisão

O navegador **não abre TCP**. O TFS fala protocolo 8.60 em TCP (portas 7171/7172).
Então, qualquer stack precisa de uma **bridge WebSocket (WSS) → TCP** no servidor:

```
navegador ──WSS (TLS)──► nginx ──► bridge WS→TCP ──TCP──► TFS (login 7171 / game 7172)
                                                          └─► MariaDB
navegador ──HTTPS──► site/API (criar conta, recuperar senha, ranking)
```

O AstraClient já faz exatamente isso (C++/Lua compilado com Emscripten, bridge + nginx em
`browser/nginx.conf.example`) — vale como referência de arquitetura, mas o artifact web tem **263 MB**,
o que é inviável para um jogo casual de fazenda.

## Rust, Node.js, WebGL — não são alternativas entre si

| Termo | O que é | Onde entra |
|---|---|---|
| **WebGL2 / WebGPU** | API de desenho da GPU no navegador | renderização — qualquer stack usa |
| **WebAssembly** | formato binário que roda no navegador | opcional: código quente (protocolo, decodificação) |
| **Rust** | linguagem que compila bem para WASM e para servidor | cliente (via WASM) e/ou bridge |
| **Node.js** | runtime JS **de servidor** | bridge, site/API — **não roda no navegador** |

## Opções de stack do cliente

| | A. TypeScript + PixiJS (WebGL2/WebGPU) | B. TS (UI) + Rust/WASM (protocolo + estado) | C. Rust total (macroquad/Bevy → WASM) | D. Portar C++ (Emscripten, estilo Astra) |
|---|---|---|---|---|
| Desempenho p/ tiles 16px | sobra | sobra | sobra | sobra |
| Tamanho inicial | ~1–3 MB + assets | ~2–4 MB + assets | macroquad ~1–2 MB, Bevy 10–30 MB | dezenas a centenas de MB |
| UI (inventário, lojas, chat) | HTML/CSS ou Pixi — fácil | HTML/CSS — fácil | UI imediata/própria — trabalhosa | Lua/OTUI |
| Velocidade de desenvolvimento | **alta** | média | baixa | baixa |
| Reuso de código | parsers em TS | parser Rust reaproveitável na bridge/ferramentas | tudo Rust | herda tudo do OTC |
| Risco | baixo | médio (fronteira JS↔WASM) | alto | alto (licença, tamanho, complexidade) |

**Recomendação: A**, com a porta aberta para B. Um mundo de 18x14 tiles de 16 px com algumas camadas é
uma carga trivial para WebGL; WASM não compra desempenho perceptível aqui. Se mais tarde o parser do
protocolo for compartilhado com ferramentas/bots de teste em Rust, ele vira um módulo WASM (opção B)
sem reescrever a UI.

- Render: **PixiJS v8** (WebGL2, WebGPU quando disponível), spritesheets/atlas PNG gerados a partir do `.spr`/`.dat`.
- UI: HTML/CSS por cima do canvas (acessível, fácil de iterar).
- Build: Vite. Assets versionados por hash, cache por Service Worker.

**Bridge:** Rust (`tokio` + `tokio-tungstenite`) ou Node (`ws`). Rust é a escolha mais segura para um
processo exposto à internet (memória, limites de frame, backpressure); Node é mais rápido de escrever.
É um programa pequeno (~300–500 linhas) nas duas linguagens.

## Segurança

### Problemas que já existem na base do servidor (corrigir antes de qualquer produção)

| Achado | Onde | Risco | Ação |
|---|---|---|---|
| `key.pem` é a **chave RSA pública conhecida do OpenTibia** (a privada está no repo) | raiz do servidor | qualquer um decifra o login | gerar chave nova; o cliente embute só a pública |
| Senhas com **SHA1 sem salt** | `iologindata.cpp`, `tools.cpp` | vazamento do banco = senhas quebradas | migrar para Argon2id (ou bcrypt) — mudança no servidor |
| `schema.sql` cria uma **conta padrão** | `INSERT INTO accounts` | conta conhecida em produção | remover |
| Admin protocol com `adminPassword = "admin"` | `config.lua.dist` | controle do servidor | desligar ou só localhost + senha forte |
| `reloadCommandEnabled = true` | `config.lua.dist` | GM derruba o servidor | desligar em produção |

### Modelo de ameaça do cliente web

- **Tudo que vai ao navegador é público**: JS, WASM, sprites, mapas de minimapa, a chave RSA pública.
  Ofuscação não é proteção. O servidor é a única autoridade (movimento, colheita, inventário, preços).
- **Bots são esperados** num jogo de fazenda (colheita repetitiva). Mitigar no servidor: limites por ação
  (`timeBetweenActions`, `maxPacketsPerSecond`), detecção de padrão, economia que não premia farm 24h.
- **Duplicação de itens** é o ataque clássico em OT: revisar scripts Lua de colheita/troca para operações
  atômicas e testar desconexão no meio da ação.

### Transporte e borda

- Só **HTTPS + WSS** (HSTS). O RSA/XTEA do 8.60 continuam por exigência do protocolo, mas a proteção real é o TLS.
- Portas 7171/7172 do TFS **só na rede privada** (a bridge fala com elas); se não houver cliente desktop, não expor.
- Checar `Origin` exato no handshake (barra outros sites; não autentica ninguém).
- Rate limit de handshakes e conexões por IP no nginx; **nginx não limita mensagens depois do upgrade** —
  a bridge precisa limitar tamanho de frame, fila por conexão, mensagens/s, idle timeout e nunca logar payload.
- Cabeçalhos: CSP restrita (`connect-src` só o seu `wss://`, `script-src 'self' 'wasm-unsafe-eval'` se usar WASM),
  `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, COOP/COEP se usar threads WASM.
- DDoS: colocar a borda atrás de um proxy/CDN que suporte WebSocket.

### Contas e sessão

- Criar conta, recuperar senha e 2FA pelo **site** (HTTPS), não pelo Account Manager in-game.
- Não guardar senha no navegador. Melhor: login no site → **token de sessão curto** → bridge/servidor valida o
  token em vez da senha (exige pequena mudança no login do TFS). Isso evita a senha trafegar no protocolo 8.60.
- Cookies `HttpOnly; Secure; SameSite=Strict` no site; CSRF nos formulários.

### Supply chain

- Fixar versões (lockfile), auditoria de dependências no CI, build reproduzível, publicar só o `dist/`
  (nunca a raiz do repo como pasta web). O AstraClient tem um bom modelo disso em
  `browser/production-assets.json` + `tools/browser_bundle.cjs`.

## Decisões em aberto

1. Cliente desktop também vai existir? (define se 7171/7172 ficam públicas)
2. Viewport maior por causa do 16px? (mudança de protocolo + mais banda — ver [02-features-e-custo.md](02-features-e-custo.md))
3. Login por token (recomendado) ou senha no protocolo como hoje?
