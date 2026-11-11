# Setup e artefatos compilados

## Estrutura local

```
backlandsofc/                  (= github.com/allanzinhodev/backlands-farming)
├── server/                    TFS modificado e dados da fazenda
├── map-editor/                NexaMap com opção de tiles 16px
├── object-editor/             editor DAT/SPR e associações XML/OTB
├── tools/                     gerador do mapa e launchers de teste
├── docs/                      documentação
└── _study/                    IGNORADO pelo git
    └── AstraClient/           clone local, não versionado
```

Servidor e editor já foram importados com `git subtree`, mantendo a possibilidade
de puxar updates do upstream. Os comandos de referência são:

```bash
git subtree add  --prefix server     https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60 main --squash
git subtree add  --prefix map-editor https://github.com/Mateuzkl/NexaMap-Editor main --squash
# atualizar depois:
git subtree pull --prefix server https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60 main --squash
```

> Licenças: o TFS é **GPLv2** (se distribuir o binário do servidor modificado, o código vai junto;
> rodar o servidor não é distribuir). O NexaMap traz um EULA herdado do RME (GPL) — ler antes de
> redistribuir. O AstraClient é baseado no OTClient (MIT); ver `CREDITS.md` dele.

## Artefatos já compilados (levantado em 2026-11-10)

Nenhum dos três projetos publica *Release* com binário do servidor/editor. Os binários existem como
**artifacts do GitHub Actions** — é preciso estar **logado no GitHub** para baixar (o zip fica no fim da página da run).
Artifacts expiram; as datas abaixo são de expiração.

| Projeto | Artifact | Tamanho | Expira | Link |
|---|---|---|---|---|
| TFS | `tfs-windows-<sha>` | 4 MB | 2026-11-21 | [run 42335086591](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/actions/runs/42335086591) |
| TFS | `tfs-linux-<sha>` | 2 MB | 2026-11-21 | [run 42335086552](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/actions/runs/42335086552) |
| NexaMap | `NexaMap-Editor-Windows-x64-Release` | 10 MB | 2026-11-16 | [run 41522387810](https://github.com/Mateuzkl/NexaMap-Editor/actions/runs/41522387810) |
| AstraClient | `astraclient-windows-<sha>` | 16 MB | 2026-11-14 | [run 41148987716](https://github.com/Mateuzkl/AstraClient/actions/runs/41148987716) |
| AstraClient | `astraclient-browser-<sha>` (WASM) | 263 MB | 2027-01-29 | [run 41148987818](https://github.com/Mateuzkl/AstraClient/actions/runs/41148987818) |

Observações:
- Os últimos builds Windows/Linux do NexaMap (2026-11-07) **falharam**; o artifact acima é do último build verde (2026-11-02).
- O binário do TFS precisa do `data/`, `config.lua` (copiar de `config.lua.dist`), `schema.sql` e um MariaDB.
  O jeito mais rápido de testar é o `Dockerfile` que já vem no repo do servidor.
- Toolchain local disponível: Visual Studio 2026 (MSVC 14.51) + vcpkg em `C:\vcpkg` + Docker + WSL — dá para compilar tudo localmente.

### Subindo o servidor para teste

```powershell
docker build -t backlands-server:dev server
python tools/dev/server.py start
```

O launcher cria um MariaDB isolado e o TFS sem publicar portas no host, importa
o schema e prepara a conta de desenvolvimento `fazenda` / `fazenda`. Configuração,
persistência e comandos de parada: [tools/dev/README.md](../tools/dev/README.md).
