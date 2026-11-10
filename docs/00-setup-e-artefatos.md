# Setup e artefatos compilados

## Estrutura local

```
backlandsofc/                  (= github.com/allanzinhodev/backlands-farming)
├── docs/                      planejamento
└── _study/                    IGNORADO pelo git
    ├── AstraClient/           só estudo — nunca sobe
    ├── forgottenserver-downgrade-1.8-8.60/
    └── NexaMap-Editor/
```

Servidor e editor ficam em `_study/` enquanto só estudamos. Quando formos modificá-los,
entram no repo com `git subtree`, o que mantém a possibilidade de puxar updates do upstream:

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

### Subindo o servidor para teste (Docker, sugestão)

1. MariaDB: `docker run -d --name bl-db -e MARIADB_ROOT_PASSWORD=dev -e MARIADB_DATABASE=forgottenserver -p 3306:3306 mariadb:11`
2. Importar `schema.sql`.
3. `config.lua` ← `config.lua.dist`, ajustando `mysql*` e `ip`.
4. Rodar o `tfs` do artifact (ou `docker build` com o Dockerfile do repo).
