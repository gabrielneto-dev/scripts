# Migrador Pop!_OS → Linux Mint — v1.3.0

O `migrador.sh` faz o **backup e inventário** no Pop!_OS. Cada execução gera um **restaurador independente** dentro da própria pasta do backup. No Linux Mint, não é necessário instalar nem executar o `migrador.sh` original: use o `restaurar.sh` gerado.

## 1. No Pop!_OS

Abra um terminal na pasta que contém `migrador.sh` e execute como **usuário comum**:

```bash
chmod +x migrador.sh
./migrador.sh
```

Menu:

```text
1) Adicionar pasta personalizada
2) Listar pastas personalizadas
3) Fazer backup e inventario portatil
4) Verificar integridade (SHA256 + TAR)
5) Autotestes Wi-Fi e Docker
0) Sair
```

A opção de **extração/restauração pelo menu foi removida**. A opção 5 agora contém apenas os autotestes (antes era a opção 6).

1. Conecte um **HD externo criptografado** e monte-o. O script não criptografa o conteúdo.
2. Em **1**, adicione pastas ou arquivos adicionais que fiquem fora da sua Home. Você pode registrar quantos caminhos precisar, desde que existam. Os caminhos ficam em `~/.config/linux-migrador/pastas.txt`.
3. Em **2**, confira a lista.
4. Em **3**, informe o caminho **absoluto** do diretório de destino no HD (por exemplo, `/media/usuario/HD_EXTERNO/Backups`). Confirme os alertas; o programa gera automaticamente uma nova pasta de backup. A unidade de destino não pode ficar dentro da Home nem de uma pasta adicional em backup.
5. Confira `backup/06-relatorios/STATUS.md`, `ALERTAS.txt`, `execucao.log`, `APLICATIVOS.md`, `ATALHOS.md`, `SSH.md`, `LINGUAGENS.md` e `INVENTARIO.md`.
6. Execute a opção **4** e informe o caminho da **pasta gerada** para conferir a integridade.
7. Antes de formatar, faça também um teste de extração do backup e backups próprios dos bancos de dados, volumes Docker ativos e serviços essenciais.

## 2. Estrutura criada no HD externo

A pasta recebe **data, hora local, nome da máquina e identificador aleatório**. Cada execução gera uma pasta própria, sem sobrescrever a anterior:

```text
HD_EXTERNO/Backups/
└── PopOS-AAAAMMDD-HHMMSS-HOST-ID/
    ├── backup/
    │   ├── 01-arquivos/
    │   │   ├── home.tar
    │   │   ├── adicional-001.tar
    │   │   └── adicionais.tsv
    │   ├── 02-configuracoes/
    │   ├── 03-sistema/
    │   │   ├── sistema.tar
    │   │   └── dconf-completo.ini  [quando disponível]
    │   ├── 04-desenvolvimento/
    │   ├── 05-docker/
    │   ├── 06-relatorios/
    │   │   ├── ORIGEM.md
    │   │   ├── STATUS.md
    │   │   ├── INVENTARIO.md
    │   │   ├── ATALHOS.md
    │   │   ├── APLICATIVOS.md
    │   │   ├── LINGUAGENS.md
    │   │   └── SSH.md
    │   └── checksums.sha256
    ├── restaurar.sh
    └── USO.md
```

**No nível superior há exatamente três itens:** `backup/`, `restaurar.sh` e `USO.md`. Outros arquivos só são criados dentro de `backup/`. O `restaurar.sh` e o `USO.md` são copiados/gerados automaticamente no momento do backup.

## 3. No Linux Mint

1. Instale o Mint, **sem formatar o HD de backup**.
2. Plugue o HD, abra a pasta `PopOS-AAAAMMDD-HHMMSS-HOST-ID/` desejada e leia `USO.md`.
3. Abra um terminal **dentro dessa pasta** e execute:

```bash
bash ./restaurar.sh --verificar
```

Esse comando só confere checksums/estrutura e o estado da cópia. **Não modifica a Home.**

Para conferir os arquivos em uma área separada antes de integrar:

```bash
bash ./restaurar.sh --somente-conferir
```

Para executar a restauração sem menu:

```bash
bash ./restaurar.sh
```

O restaurador:

1. Identifica automaticamente a pasta `backup/` ao lado dele, independentemente do nome/montagem do HD.
2. Verifica o estado (`SUCESSO` ou `COM_RESSALVAS`), SHA-256 e leitura dos arquivos TAR. Bloqueia backups `INCOMPLETO` ou alterados.
3. Extrai a Home, pastas adicionais e configurações globais em uma **nova pasta de conferência** `~/Migracao-Mint-XXXXXXXX/`. Coloca os arquivos/inventários Docker nessa mesma área, sem importá-los para o daemon.
4. Solicita que você digite **RESTAURAR**. Se confirmado, utiliza `rsync` para adicionar **somente os arquivos que não existem ainda** na Home atual; não sobrescreve arquivos existentes. Mantém configurações COSMIC, dconf, GNOME Shell e algumas personalizações de interface somente na pasta de conferência, para não quebrar o Cinnamon.
5. Cria `~/Migracao-Mint-XXXXXXXX/relatorios/RESTAURACAO.md` e `CONFLITOS-HOME.txt`, que lista arquivos já existentes no Mint que exigem revisão (por exemplo, `.zshrc`), e informa o diretório usado.

Se o Linux Mint não tiver `rsync`, instale com `sudo apt install rsync`. Sem ele, o restaurador **extrai para conferência**, mas não integra à Home.

Em EXT4, se a nova conta tiver UID/GID diferente, talvez você precise ajustar a propriedade da pasta **do seu próprio backup**, com `sudo chown -R "$(id -u):$(id -g)" "/caminho/da/pasta/PopOS-..."`. Em NTFS/exFAT, a propriedade depende das opções de montagem. Em NTFS/exFAT ou partições montadas como `noexec`, pode ser impossível executar `./restaurar.sh` diretamente. **`bash ./restaurar.sh` funciona sem bit executável**, desde que a mídia esteja legível. Não use `sudo` no restaurador.

## 4. Limites e cuidados essenciais

- **Não é uma clonagem do Pop!_OS nem reinstalação completa automática.** Aplicativos APT/Flatpak/Snap, linguagens, SDKs e ferramentas externas são inventariados, mas precisam ser instalados/revisados no Mint.
- `sistema.tar` guarda amostras/configurações globais (inclusive Wi-Fi em `/etc/NetworkManager/system-connections`, quando existirem), mas é restaurado **apenas para conferência**, nunca diretamente em `/etc`. Configurações de Wi-Fi podem depender do chaveiro e exigir nova autenticação.
- O backup da Home inclui SSH e dotfiles. Chaves privadas ficam nos arquivos TAR protegidos **apenas pela proteção do HD**; não aparecem em texto nos relatórios. SSH pode requerer correção de permissões, URLs e desbloqueio de senhas após migrar.
- Atalhos específicos COSMIC não são convertidos automaticamente para Cinnamon. Consulte `ATALHOS.md`.
- Docker é opcional. Contêineres, imagens, redes e mounts são inventariados se habilitado; só os volumes livres e selecionados são exportados. **Nenhum volume é restaurado automaticamente. Bancos em atividade exigem dumps consistentes e teste de restauração separado.** Bind mounts fora da Home devem entrar como pastas adicionais.
- Os arquivos `~/.cache`, Lixeira, `node_modules`, `.venv` e alguns arquivos transitórios são excluídos. Se fizer uso crítico de algum desses caminhos, realize uma cópia própria.
- A restauração **extrai cópias completas** antes de tentar integrá-las à Home; confirme espaço livre suficiente no Mint. Se seu usuário tiver nome diferente, alguns caminhos internos e configurações podem precisar de adaptação.
- SHA-256 indica alteração de dados e erros de leitura, **não** comprova que tudo foi coletado ou que alguém não alterou também o manifesto.
- O script gerado é código executável guardado no HD; inspecione-o antes de executar, principalmente se a unidade tiver sido compartilhada.
- NUNCA copie integralmente o `/etc` antigo sobre o `/etc` do Mint. NUNCA formate sem verificar os relatórios, testar a extração e confirmar os dados de Docker/bancos.

## 5. Validação e testes

A implementação e os cenários testados estão em `AUDITORIA.md`. O teste de Wi-Fi e Docker **real no seu Pop!_OS** continua necessário: menu **5**. Os testes feitos em ambiente isolado não substituem o teste no computador de origem.
