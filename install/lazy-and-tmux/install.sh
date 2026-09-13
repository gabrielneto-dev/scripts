#!/usr/bin/env bash

set -Eeuo pipefail

KIT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CURRENT_USER_NAME="$(id -un)"
USER_HOME_DIR="$(getent passwd "$CURRENT_USER_NAME" | cut -d: -f6)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

SKIP_BOOTSTRAP=0
SKIP_FONT=0
BACKUP_USED=0

TREE_SITTER_MIN_VERSION="0.26.1"
TREE_SITTER_SOURCE_VERSION="0.26.1"
TREE_SITTER_RUST_VERSION="1.88.0"

usage() {
  cat <<'EOF'
Uso: ./install.sh [opções]

Opções:
  --skip-bootstrap  Não baixa plugins/LSPs do LazyVim durante a instalação.
  --skip-font       Não instala a MesloLGS Nerd Font.
  -h, --help        Mostra esta ajuda.
EOF
}

while (($# > 0)); do
  case "$1" in
    --skip-bootstrap) SKIP_BOOTSTRAP=1 ;;
    --skip-font) SKIP_FONT=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Opção desconhecida: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

log() {
  printf '\033[1;36m[dev-kit]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[aviso]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[erro]\033[0m %s\n' "$*" >&2
  exit 1
}

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "Execute como usuário normal, sem sudo. O script pedirá sudo apenas para o APT."
[[ -n "$USER_HOME_DIR" && "$USER_HOME_DIR" != "/" && -d "$USER_HOME_DIR" ]] || die "Não foi possível determinar um diretório pessoal seguro."
[[ -z ${TMUX:-} ]] || die "Saia do tmux antes de instalar (Ctrl+b, depois d) e execute novamente em um terminal normal."
[[ -f "$KIT_ROOT/config/tmux.conf" && -d "$KIT_ROOT/config/nvim" ]] || die "O kit está incompleto. Extraia todo o ZIP antes de executar."
command -v apt-get >/dev/null 2>&1 || die "Este instalador requer uma distribuição baseada em Debian/Ubuntu com APT."
command -v sudo >/dev/null 2>&1 || die "O comando sudo não está instalado."

XDG_CONFIG_BASE="${XDG_CONFIG_HOME:-$USER_HOME_DIR/.config}"
XDG_DATA_BASE="${XDG_DATA_HOME:-$USER_HOME_DIR/.local/share}"
XDG_STATE_BASE="${XDG_STATE_HOME:-$USER_HOME_DIR/.local/state}"
XDG_CACHE_BASE="${XDG_CACHE_HOME:-$USER_HOME_DIR/.cache}"
LOCAL_BIN_DIR="$USER_HOME_DIR/.local/bin"
LOCAL_OPT_DIR="$USER_HOME_DIR/.local/opt"
NVIM_INSTALL_DIR="$LOCAL_OPT_DIR/neovim"
NVIM_CONFIG_DIR="$XDG_CONFIG_BASE/nvim"
TMUX_CONFIG_FILE="$USER_HOME_DIR/.tmux.conf"
TMUX_PLUGIN_DIR="$USER_HOME_DIR/.tmux/plugins"
FONT_DIR="$XDG_DATA_BASE/fonts/MesloLGS-Nerd-Font"
STATE_ROOT="$XDG_STATE_BASE/dev-environment-kit"
BACKUP_ROOT="$STATE_ROOT/backups/$TIMESTAMP"

assert_safe_user_path() {
  local target="$1"
  case "$target" in
    "$USER_HOME_DIR"/*) ;;
    *) die "Caminho recusado por segurança: $target" ;;
  esac
}

backup_move() {
  local target="$1"
  local relative destination
  [[ -e "$target" || -L "$target" ]] || return 0
  assert_safe_user_path "$target"
  relative="${target#"$USER_HOME_DIR"/}"
  destination="$BACKUP_ROOT/$relative"
  mkdir -p -- "$(dirname -- "$destination")"
  mv -- "$target" "$destination"
  BACKUP_USED=1
  log "Backup: $target"
}

backup_copy() {
  local target="$1"
  local relative destination
  [[ -e "$target" || -L "$target" ]] || return 0
  assert_safe_user_path "$target"
  relative="${target#"$USER_HOME_DIR"/}"
  destination="$BACKUP_ROOT/$relative"
  [[ -e "$destination" || -L "$destination" ]] && return 0
  mkdir -p -- "$(dirname -- "$destination")"
  cp -a -- "$target" "$destination"
  BACKUP_USED=1
}

TEMP_DIR="$(mktemp -d -t dev-environment-kit.XXXXXX)"
cleanup() {
  if [[ -n ${TEMP_DIR:-} && -d "$TEMP_DIR" ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

on_error() {
  local status=$?
  warn "A instalação foi interrompida na linha ${BASH_LINENO[0]:-desconhecida}."
  if ((BACKUP_USED)); then
    warn "Seus arquivos anteriores continuam disponíveis em: $BACKUP_ROOT"
  fi
  exit "$status"
}
trap on_error ERR

install_apt_dependencies() {
  local tmux_version
  local packages=(
    build-essential
    ca-certificates
    curl
    fd-find
    fontconfig
    fzf
    git
    htop
    ripgrep
    tmux
    unzip
    wl-clipboard
    xclip
  )

  log "Atualizando o índice do APT..."
  sudo apt-get update
  log "Instalando dependências do sistema..."
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    warn "Node.js/npm não encontrados; instalando as versões disponíveis pelo APT."
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm
  fi

  if ! command -v php >/dev/null 2>&1; then
    warn "PHP CLI não encontrado; instalando pelo APT para os formatadores PHP."
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y php-cli
  fi

  if apt-cache show lazygit >/dev/null 2>&1; then
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y lazygit
  else
    warn "lazygit não está disponível neste repositório APT; a integração Git básica continuará funcionando."
  fi

  tmux_version="$(tmux -V | awk '{ print $2 }')"
  dpkg --compare-versions "$tmux_version" ge '3.2' || die "O tmux $tmux_version é antigo demais para os popups. Use Ubuntu 22.04 ou mais recente."
}

detect_architecture() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'x86_64' ;;
    aarch64|arm64) printf 'arm64' ;;
    *) die "Arquitetura não suportada automaticamente: $(uname -m)" ;;
  esac
}

download() {
  local url="$1"
  local output="$2"
  curl --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 -fL "$url" -o "$output"
}

install_neovim() {
  local arch archive_name extracted_dir archive_path version

  if [[ -x "$NVIM_INSTALL_DIR/bin/nvim" && -L "$LOCAL_BIN_DIR/nvim" ]] &&
    [[ "$(readlink -f -- "$LOCAL_BIN_DIR/nvim")" == "$(readlink -f -- "$NVIM_INSTALL_DIR/bin/nvim")" ]]; then
    version="$($NVIM_INSTALL_DIR/bin/nvim --version | awk 'NR == 1 { sub(/^v/, "", $2); print $2 }')"
    if dpkg --compare-versions "$version" ge '0.11.2'; then
      export PATH="$LOCAL_BIN_DIR:$PATH"
      log "Neovim $version já instalado pelo kit; reutilizando."
      return 0
    fi
  fi

  arch="$(detect_architecture)"
  archive_name="nvim-linux-$arch.tar.gz"
  extracted_dir="nvim-linux-$arch"
  archive_path="$TEMP_DIR/$archive_name"

  log "Baixando o Neovim estável oficial para $arch..."
  download "https://github.com/neovim/neovim/releases/latest/download/$archive_name" "$archive_path"
  tar -tzf "$archive_path" >/dev/null
  tar -xzf "$archive_path" -C "$TEMP_DIR"
  [[ -x "$TEMP_DIR/$extracted_dir/bin/nvim" ]] || die "O arquivo oficial do Neovim não contém o executável esperado."

  backup_move "$LOCAL_BIN_DIR/nvim"
  backup_move "$NVIM_INSTALL_DIR"
  mkdir -p -- "$LOCAL_BIN_DIR" "$LOCAL_OPT_DIR"
  mv -- "$TEMP_DIR/$extracted_dir" "$NVIM_INSTALL_DIR"
  ln -s -- "$NVIM_INSTALL_DIR/bin/nvim" "$LOCAL_BIN_DIR/nvim"

  export PATH="$LOCAL_BIN_DIR:$PATH"
  version="$(nvim --version | awk 'NR == 1 { sub(/^v/, "", $2); print $2 }')"
  dpkg --compare-versions "$version" ge '0.11.2' || die "Neovim $version instalado, mas o LazyVim exige pelo menos 0.11.2."
  log "Neovim $version instalado."
}

build_tree_sitter_cli() {
  local arch="$1"
  local rust_target rustup_init cargo_home rustup_home build_root

  case "$arch" in
    x86_64) rust_target="x86_64-unknown-linux-gnu" ;;
    arm64) rust_target="aarch64-unknown-linux-gnu" ;;
  esac

  rustup_init="$TEMP_DIR/rustup-init"
  cargo_home="$TEMP_DIR/cargo-home"
  rustup_home="$TEMP_DIR/rustup-home"
  build_root="$TEMP_DIR/tree-sitter-build"

  warn "O binário oficial mais recente não é compatível com a glibc deste sistema."
  log "Instalando a dependência de compilação libclang..."
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y libclang-dev
  log "Compilando Tree-sitter CLI $TREE_SITTER_SOURCE_VERSION localmente (pode levar alguns minutos)..."
  download "https://static.rust-lang.org/rustup/dist/$rust_target/rustup-init" "$rustup_init"
  chmod 0755 "$rustup_init"

  RUSTUP_HOME="$rustup_home" CARGO_HOME="$cargo_home" \
    "$rustup_init" -y --no-modify-path --profile minimal --default-toolchain "$TREE_SITTER_RUST_VERSION"

  RUSTUP_HOME="$rustup_home" CARGO_HOME="$cargo_home" \
    "$cargo_home/bin/cargo" install \
      --git https://github.com/tree-sitter/tree-sitter.git \
      --tag "v$TREE_SITTER_SOURCE_VERSION" \
      --locked \
      --root "$build_root" \
      tree-sitter-cli

  TREE_SITTER_CANDIDATE="$build_root/bin/tree-sitter"
  [[ -x "$TREE_SITTER_CANDIDATE" ]] || die "A compilação do Tree-sitter CLI não produziu o executável esperado."
}

install_tree_sitter_cli() {
  local arch asset archive_path extracted candidate candidate_output candidate_version

  if [[ -x "$LOCAL_BIN_DIR/tree-sitter" ]] && candidate_output="$($LOCAL_BIN_DIR/tree-sitter --version 2>&1)"; then
    candidate_version="$(awk 'NR == 1 { print $2 }' <<< "$candidate_output")"
    if [[ -n "$candidate_version" ]] && dpkg --compare-versions "$candidate_version" ge "$TREE_SITTER_MIN_VERSION"; then
      log "Tree-sitter CLI $candidate_version já instalado; reutilizando."
      return 0
    fi
  fi

  arch="$(detect_architecture)"
  case "$arch" in
    x86_64) asset="tree-sitter-cli-linux-x64.zip" ;;
    arm64) asset="tree-sitter-cli-linux-arm64.zip" ;;
  esac
  archive_path="$TEMP_DIR/$asset"
  extracted="$TEMP_DIR/tree-sitter"

  log "Instalando o Tree-sitter CLI oficial..."
  download "https://github.com/tree-sitter/tree-sitter/releases/latest/download/$asset" "$archive_path"
  unzip -tq "$archive_path" >/dev/null
  unzip -qo "$archive_path" -d "$TEMP_DIR/tree-sitter-release"
  extracted="$(find "$TEMP_DIR/tree-sitter-release" -type f -name tree-sitter -print -quit)"
  [[ -n "$extracted" && -f "$extracted" ]] || die "Executável tree-sitter não encontrado no arquivo baixado."

  chmod 0755 "$extracted"
  candidate=""
  if candidate_output="$($extracted --version 2>&1)"; then
    candidate_version="$(awk 'NR == 1 { print $2 }' <<< "$candidate_output")"
    if [[ -n "$candidate_version" ]] && dpkg --compare-versions "$candidate_version" ge "$TREE_SITTER_MIN_VERSION"; then
      candidate="$extracted"
    else
      warn "Tree-sitter CLI $candidate_version é anterior à versão mínima $TREE_SITTER_MIN_VERSION."
    fi
  fi

  if [[ -z "$candidate" ]]; then
    build_tree_sitter_cli "$arch"
    candidate="$TREE_SITTER_CANDIDATE"
  fi

  backup_move "$LOCAL_BIN_DIR/tree-sitter"
  install -Dm0755 "$candidate" "$LOCAL_BIN_DIR/tree-sitter"
  candidate_output="$($LOCAL_BIN_DIR/tree-sitter --version)"
  candidate_version="$(awk 'NR == 1 { print $2 }' <<< "$candidate_output")"
  dpkg --compare-versions "$candidate_version" ge "$TREE_SITTER_MIN_VERSION" || \
    die "Tree-sitter CLI $candidate_version instalado, mas é necessário $TREE_SITTER_MIN_VERSION ou superior."
  log "Tree-sitter CLI $candidate_version instalado."
}

install_font() {
  local archive_path="$TEMP_DIR/Meslo.zip"
  log "Instalando MesloLGS Nerd Font para o usuário atual..."
  download "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" "$archive_path"
  unzip -tq "$archive_path" >/dev/null
  backup_move "$FONT_DIR"
  mkdir -p -- "$FONT_DIR"
  unzip -qo "$archive_path" -d "$FONT_DIR"
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
}

clone_tmux_plugin() {
  local repository="$1"
  local destination="$2"
  git clone --depth 1 "https://github.com/$repository.git" "$destination"
}

install_tmux_configuration() {
  log "Instalando a configuração e os plugins do tmux..."
  backup_move "$TMUX_CONFIG_FILE"
  backup_move "$USER_HOME_DIR/.tmux"
  backup_move "$XDG_DATA_BASE/tmux"

  install -Dm0644 "$KIT_ROOT/config/tmux.conf" "$TMUX_CONFIG_FILE"
  mkdir -p -- "$TMUX_PLUGIN_DIR"
  clone_tmux_plugin tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
  clone_tmux_plugin tmux-plugins/tmux-sensible "$TMUX_PLUGIN_DIR/tmux-sensible"
  clone_tmux_plugin tmux-plugins/tmux-resurrect "$TMUX_PLUGIN_DIR/tmux-resurrect"
  clone_tmux_plugin tmux-plugins/tmux-continuum "$TMUX_PLUGIN_DIR/tmux-continuum"
  : > "$USER_HOME_DIR/.tmux/.dev-environment-kit"
}

install_helper_scripts() {
  local name
  log "Instalando os comandos auxiliares..."
  mkdir -p -- "$LOCAL_BIN_DIR"
  for name in dev-session tmux-copy tmux-notes tmux-switcher; do
    backup_move "$LOCAL_BIN_DIR/$name"
    install -m0755 "$KIT_ROOT/scripts/$name" "$LOCAL_BIN_DIR/$name"
  done

  if [[ ! -e "$LOCAL_BIN_DIR/fd" && -x /usr/bin/fdfind ]]; then
    ln -s /usr/bin/fdfind "$LOCAL_BIN_DIR/fd"
  fi
}

install_lazyvim_configuration() {
  log "Instalando a configuração personalizada do LazyVim..."
  backup_move "$NVIM_CONFIG_DIR"
  backup_move "$XDG_DATA_BASE/nvim"
  backup_move "$XDG_STATE_BASE/nvim"
  backup_move "$XDG_CACHE_BASE/nvim"

  mkdir -p -- "$NVIM_CONFIG_DIR"
  cp -a -- "$KIT_ROOT/config/nvim/." "$NVIM_CONFIG_DIR/"
  : > "$NVIM_CONFIG_DIR/.dev-environment-kit"
}

ensure_path_block() {
  local shell_file="$1"
  local start_marker='# >>> dev-environment-kit PATH >>>'
  local end_marker='# <<< dev-environment-kit PATH <<<'

  if [[ -f "$shell_file" ]] && grep -Fq "$start_marker" "$shell_file"; then
    return 0
  fi

  backup_copy "$shell_file"
  touch "$shell_file"
  {
    printf '\n%s\n' "$start_marker"
    printf '%s\n' 'if [ -d "$HOME/.local/bin" ]; then'
    printf '%s\n' '  export PATH="$HOME/.local/bin:$PATH"'
    printf '%s\n' 'fi'
    printf '%s\n' "$end_marker"
  } >> "$shell_file"
}

configure_shell_path() {
  log "Garantindo ~/.local/bin no PATH..."
  ensure_path_block "$USER_HOME_DIR/.profile"
  if [[ -f "$USER_HOME_DIR/.zshrc" || "${SHELL:-}" == */zsh ]]; then
    ensure_path_block "$USER_HOME_DIR/.zshrc"
  fi
  if [[ -f "$USER_HOME_DIR/.bashrc" || "${SHELL:-}" == */bash ]]; then
    ensure_path_block "$USER_HOME_DIR/.bashrc"
  fi
}

validate_tmux_configuration() {
  local socket_name="dev-kit-check-$$"
  log "Validando a configuração do tmux..."
  tmux -L "$socket_name" -f "$TMUX_CONFIG_FILE" new-session -d -s dev-kit-check
  tmux -L "$socket_name" list-windows >/dev/null
  tmux -L "$socket_name" kill-server
}

bootstrap_lazyvim() {
  local lazy_status=0 mason_status=0
  if ((SKIP_BOOTSTRAP)); then
    warn "Bootstrap do LazyVim ignorado. Execute 'nvim' depois para baixar os plugins."
    return 0
  fi

  log "Baixando e sincronizando os plugins do LazyVim..."
  nvim --headless "+Lazy! sync" +qa || lazy_status=$?
  if ((lazy_status != 0)); then
    warn "A sincronização do LazyVim falhou. Verifique a internet e execute: nvim --headless '+Lazy! sync' +qa"
    return 0
  fi

  log "Instalando LSPs, formatadores e linters com Mason..."
  nvim --headless "+MasonToolsInstallSync" +qa || mason_status=$?
  if ((mason_status != 0)); then
    warn "Alguma ferramenta do Mason não foi instalada. Abra o Neovim e execute :MasonToolsInstallSync."
  fi
}

write_install_state() {
  mkdir -p -- "$STATE_ROOT"
  {
    printf 'version=%s\n' "$(tr -d '[:space:]' < "$KIT_ROOT/VERSION")"
    printf 'installed_at=%s\n' "$TIMESTAMP"
    printf 'kit_root=%s\n' "$KIT_ROOT"
    printf 'backup_root=%s\n' "$BACKUP_ROOT"
  } > "$STATE_ROOT/install-manifest"
}

main() {
  install_apt_dependencies
  mkdir -p -- "$LOCAL_BIN_DIR" "$LOCAL_OPT_DIR" "$STATE_ROOT"
  install_neovim
  install_tree_sitter_cli
  if ((SKIP_FONT == 0)); then
    install_font
  fi
  install_helper_scripts
  install_tmux_configuration
  install_lazyvim_configuration
  configure_shell_path
  validate_tmux_configuration
  bootstrap_lazyvim
  write_install_state

  printf '\n\033[1;32mInstalação concluída.\033[0m\n'
  printf 'Neovim: %s\n' "$(nvim --version | head -n 1)"
  printf 'tmux: %s\n' "$(tmux -V)"
  printf 'Tree-sitter: %s\n' "$(tree-sitter --version | head -n 1)"
  if ((BACKUP_USED)); then
    printf 'Backup anterior: %s\n' "$BACKUP_ROOT"
  fi
  printf '\nAbra um novo terminal ou execute: exec %s -l\n' "${SHELL:-/bin/bash}"
  printf 'Depois use: tmux   ou   dev-session /caminho/do/projeto\n'
  printf 'No terminal gráfico, selecione a fonte: MesloLGS Nerd Font\n'
  if grep -qi microsoft /proc/version 2>/dev/null; then
    warn "WSL detectado: configure a MesloLGS Nerd Font também no Windows Terminal."
  fi
}

main "$@"
