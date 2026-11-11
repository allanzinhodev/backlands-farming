# Servidor local de desenvolvimento

Requer Docker Desktop em modo Linux e Python 3. A partir da raiz do projeto:

```powershell
docker build -t backlands-server:dev server
python tools/dev/server.py start
python tools/dev/server.py status
```

O primeiro build compila o TFS e suas dependências. O launcher cria os containers
`backlandsofc-db` (MariaDB 11) e `backlandsofc-server`, conectados à rede privada
`bl-test`. Nenhuma porta do banco ou do TFS é publicada no host. O cliente web
acessa o servidor pela bridge descrita em [docs/06-astra-web.md](../../docs/06-astra-web.md).

O schema distribuído não cria contas e preserva o ID 1 reservado ao antigo
Account Manager. Apenas este ambiente de desenvolvimento
recebe a conta **fazenda**, senha **fazenda**, personagem **Fazendeiro**. Ele começa
no nível 8, vocação Farmer, em **100, 100, 7**. No primeiro login, recebe o kit de
ferramentas e insumos. Reiniciar preserva a senha, o personagem e os itens salvos.

As senhas aleatórias do banco e a configuração gerada ficam em `out/dev-server/`,
ignorado pelo Git. Os dados persistem no volume `backlandsofc-dev-db`. Os containers
recebem uma identificação do workspace; o launcher recusa alterar containers com
os mesmos nomes pertencentes a outro workspace.

O servidor monta `server/data` local, permitindo testar alterações de scripts e
mapa após reiniciar. Mudanças em C++ exigem reconstruir a imagem. O launcher
recria somente o container do servidor quando a imagem muda, preservando o banco:

```powershell
docker build -t backlands-server:dev server
python tools/dev/server.py start
```

Para acompanhar ou parar o ambiente sem apagar o banco:

```powershell
docker logs -f backlandsofc-server
python tools/dev/server.py stop
```

O launcher não altera os demais containers do Docker.

## Validação dos scripts de fazenda

O jogo não depende de Python/Lupa. Para executar a verificação opcional dos scripts:

```powershell
python -m pip install -r tools/dev/requirements-validation.txt
python -m unittest discover -s tools/dev -v
python -m unittest discover -s tools/world -v
python tools/world/create_starter_world.py --check
```

Os testes executam os hooks Lua de kit inicial, login/logout, lojas, plantio em
vasos e colheita de trigo, compilam os scripts Lua restantes e verificam as tabelas
de startup. Os testes do mundo verificam o OTBM, as rotas e os IDs contra os
arquivos DAT/SPR/OTB locais.
