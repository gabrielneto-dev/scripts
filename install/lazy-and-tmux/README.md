# Kit tmux + LazyVim

Instalador reproduzível e personalizado para Ubuntu, Pop!_OS, WSL e distribuições derivadas. Ele instala um ambiente de desenvolvimento com tmux, LazyVim, restauração automática de sessões, clipboard local/remoto e suporte à stack web/backend.

## O que será instalado

- tmux pelo APT;
- Neovim estável oficial em `~/.local/opt/neovim`;
- Tree-sitter CLI 0.26.1 ou superior;
- LazyVim com TokyoNight;
- MesloLGS Nerd Font;
- TPM, tmux-sensible, tmux-resurrect e tmux-continuum;
- ferramentas de terminal: `fzf`, `ripgrep`, `fd`, `htop`, `wl-copy` e `xclip`;
- LSPs, formatadores e linters gerenciados pelo Mason;
- comando `dev-session` para criar o workspace `nvim / term / claude / codex`.

O LazyVim atual exige Neovim 0.11.2 ou superior. Por isso o Neovim usa o binário oficial, e não o pacote potencialmente antigo do APT.

## Antes de instalar

Você precisa de:

- Ubuntu 22.04 ou mais recente, Pop!_OS equivalente ou WSL com APT;
- acesso à internet;
- permissão para usar `sudo`;
- terminal fora do tmux.

Salve os arquivos abertos. O instalador não apaga configurações anteriores: move tudo para um backup com data e hora.

## Instalação

Depois de extrair o ZIP:

```bash
cd dev-environment-kit
chmod +x install.sh uninstall.sh scripts/*
./install.sh
```

Para não baixar plugins e LSPs nessa primeira execução:

```bash
./install.sh --skip-bootstrap
```

Depois, abra um novo terminal ou recarregue seu shell:

```bash
exec zsh -l
```

Se você usa Bash:

```bash
exec bash -l
```

Configure o terminal gráfico para utilizar **MesloLGS Nerd Font**. No WSL, a fonte também precisa ser instalada e selecionada no Windows Terminal.

## Abrindo um projeto

Execute dentro do projeto:

```bash
dev-session
```

Ou informe o caminho:

```bash
dev-session /caminho/do/projeto
```

Para escolher o nome da sessão:

```bash
dev-session /caminho/do/projeto minha-sessao
```

O comando cria:

1. `nvim` — abre o projeto com `nvim .`;
2. `term` — terminal livre;
3. `claude` — executa a Claude CLI quando encontrada;
4. `codex` — executa a Codex CLI quando encontrada.

Se a sessão já existir, `dev-session` apenas conecta nela.

## Atalhos do tmux

O prefixo é `Ctrl+b`: pressione as duas teclas, solte e pressione o próximo atalho.

| Atalho | Ação |
| --- | --- |
| `Ctrl+b c` | Nova janela no diretório atual |
| `Ctrl+b ,` | Renomear a janela e fixar o nome |
| `Ctrl+b s` | Listar sessões |
| `Ctrl+b \|` | Dividir horizontalmente |
| `Ctrl+b -` | Dividir verticalmente |
| `Ctrl+b h/j/k/l` | Navegar entre painéis |
| `Ctrl+b H/J/K/L` | Redimensionar painéis |
| `Ctrl+b [` | Entrar no modo de cópia |
| `v` | Iniciar seleção no modo de cópia |
| `y` ou `Enter` | Copiar para o clipboard e sair |
| `Ctrl+b Ctrl+l` | Seletor de janelas com fzf |
| `Ctrl+b Ctrl+t` | Terminal flutuante |
| `Ctrl+b Ctrl+h` | htop flutuante |
| `Ctrl+b Ctrl+n` | Notas no Neovim |
| `Ctrl+b r` | Recarregar `~/.tmux.conf` |
| `Ctrl+b Ctrl+s` | Salvar sessões manualmente |
| `Ctrl+b Ctrl+r` | Restaurar sessões manualmente |

O tmux-continuum também salva automaticamente a cada 15 minutos e restaura o último estado ao iniciar.

### Clipboard

O atalho `y` detecta nesta ordem:

1. `clip.exe` no WSL;
2. `wl-copy` no Wayland;
3. `xclip` no X11;
4. OSC 52 em SSH/terminais compatíveis.

Se a cópia remota falhar, confira se o terminal local permite OSC 52.

## LazyVim

Principais escolhas:

- tema TokyoNight;
- Snacks Explorer em `Espaço + e`;
- terminal flutuante em `Espaço + t + t`;
- abas de buffers sempre visíveis;
- autocomplete no modo Super Tab;
- diagnóstico discreto ao lado do código;
- salvamento automático ao trocar de buffer ou perder foco;
- formatação automática ao salvar.

| Atalho/comando | Ação |
| --- | --- |
| `Espaço e` | Abrir/fechar explorador |
| `Espaço t t` | Terminal flutuante |
| `Ctrl+s` | Salvar arquivo atual |
| `Espaço W` | Salvar todos os arquivos |
| `Espaço u A` | Ativar/desativar salvamento automático |
| `Espaço u f` | Ativar/desativar formatação automática do LazyVim |
| `:Lazy` | Gerenciar plugins |
| `:Mason` | Gerenciar ferramentas |
| `:LazyExtras` | Gerenciar extras oficiais |
| `:LazyHealth` | Verificar o LazyVim |
| `:checkhealth` | Diagnóstico completo do Neovim |

### Linguagens e ferramentas

- TypeScript, JavaScript e React: vtsls, ESLint, Prettier e Tailwind CSS;
- PHP: Intelephense, PHP CS Fixer e PHPCS;
- Python: basedpyright e Ruff;
- banco de dados: SQL, sqls e sql-formatter;
- Prisma: Prisma Language Server;
- infraestrutura: Dockerfile, Docker Compose, YAML e JSON;
- shell: Bash Language Server, ShellCheck e shfmt;
- Lua: Lua Language Server e StyLua.

A primeira instalação pode levar alguns minutos. Para repetir a sincronização manualmente:

```bash
nvim --headless "+Lazy! sync" +qa
nvim --headless "+MasonToolsInstallSync" +qa
```

### Compatibilidade do Tree-sitter no Ubuntu/Pop!_OS 22.04

Algumas versões recentes do binário oficial do Tree-sitter exigem uma versão de glibc mais nova que a disponível no Ubuntu/Pop!_OS 22.04. O instalador testa o executável antes de usá-lo. Se houver incompatibilidade, ele compila automaticamente o Tree-sitter CLI 0.26.1 a partir da tag oficial, usando `libclang` e um ambiente Rust temporário.

Essa compilação pode levar alguns minutos, mas não instala Rust permanentemente. Caso uma versão anterior do kit tenha parado com a mensagem `GLIBC_2.39 not found`, execute novamente o instalador atualizado:

```bash
./install.sh
```

O Neovim já instalado pela execução anterior será reutilizado.

## Backups

Os backups de instalação ficam em:

```text
~/.local/state/dev-environment-kit/backups/AAAAMMDD-HHMMSS/
```

Os backups da desinstalação ficam em:

```text
~/.local/state/dev-environment-kit/uninstall-backups/AAAAMMDD-HHMMSS/
```

Nada é restaurado automaticamente para evitar sobrescrever alterações novas.

## Desinstalação

Remover as configurações e o Neovim instalado pelo kit, mantendo o pacote tmux:

```bash
./uninstall.sh
```

Remover também o pacote tmux:

```bash
./uninstall.sh --purge-packages
```

Manter a Nerd Font:

```bash
./uninstall.sh --keep-font
```

Os pacotes genéricos como Git, curl, compilador, Node.js ou PHP não são removidos, pois podem ser utilizados por outros projetos.

## Referências oficiais

- LazyVim: <https://www.lazyvim.org/>
- Instalação do LazyVim: <https://www.lazyvim.org/installation>
- Neovim: <https://github.com/neovim/neovim/releases>
- tmux: <https://github.com/tmux/tmux>
- TPM: <https://github.com/tmux-plugins/tpm>
- Tree-sitter: <https://github.com/tree-sitter/tree-sitter/releases>
