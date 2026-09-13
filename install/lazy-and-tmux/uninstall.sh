#!/usr/bin/env bash

set -Eeuo pipefail

CURRENT_USER_NAME="$(id -un)"
USER_HOME_DIR="$(getent passwd "$CURRENT_USER_NAME" | cut -d: -f6)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
PURGE_PACKAGES=0
KEEP_FONT=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Uso: ./uninstall.sh [opções]

Opções:
  --purge-packages  Remove também o pacote tmux instalado pelo APT.
  --keep-font       Mantém a MesloLGS Nerd Font.
  -y, --yes         Não solicita confirmação.
  -h, --help        Mostra esta ajuda.

As configurações removidas são movidas para um backup recuperável.
EOF
}

while (($# > 0)); do
  case "$1" in
    --purge-packages) PURGE_PACKAGES=1 ;;
    --keep-font) KEEP_FONT=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
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

die() {
  printf '\033[1;31m[erro]\033[0m %s\n' "$*" >&2
  exit 1
}

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "Execute como usuário normal, sem sudo."
[[ -n "$USER_HOME_DIR" && "$USER_HOME_DIR" != "/" && -d "$USER_HOME_DIR" ]] || die "Diretório pessoal inválido."
[[ -z ${TMUX:-} ]] || die "Saia do tmux antes de desinstalar (Ctrl+b, depois d)."

XDG_CONFIG_BASE="${XDG_CONFIG_HOME:-$USER_HOME_DIR/.config}"
XDG_DATA_BASE="${XDG_DATA_HOME:-$USER_HOME_DIR/.local/share}"
XDG_STATE_BASE="${XDG_STATE_HOME:-$USER_HOME_DIR/.local/state}"
XDG_CACHE_BASE="${XDG_CACHE_HOME:-$USER_HOME_DIR/.cache}"
LOCAL_BIN_DIR="$USER_HOME_DIR/.local/bin"
STATE_ROOT="$XDG_STATE_BASE/dev-environment-kit"
BACKUP_ROOT="$STATE_ROOT/uninstall-backups/$TIMESTAMP"
MOVED_ANYTHING=0

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
  MOVED_ANYTHING=1
  log "Removido com backup: $target"
}

backup_copy() {
  local target="$1"
  local relative destination
  [[ -f "$target" ]] || return 0
  assert_safe_user_path "$target"
  relative="${target#"$USER_HOME_DIR"/}"
  destination="$BACKUP_ROOT/$relative"
  [[ -e "$destination" ]] && return 0
  mkdir -p -- "$(dirname -- "$destination")"
  cp -a -- "$target" "$destination"
}

remove_path_block() {
  local shell_file="$1"
  local temporary
  [[ -f "$shell_file" ]] || return 0
  grep -Fq '# >>> dev-environment-kit PATH >>>' "$shell_file" || return 0

  backup_copy "$shell_file"
  temporary="$(mktemp -p "$(dirname -- "$shell_file")" .dev-kit-shell.XXXXXX)"
  awk '
    $0 == "# >>> dev-environment-kit PATH >>>" { skip = 1; next }
    $0 == "# <<< dev-environment-kit PATH <<<" { skip = 0; next }
    !skip { print }
  ' "$shell_file" > "$temporary"
  chmod --reference="$shell_file" "$temporary"
  mv -- "$temporary" "$shell_file"
}

if ((ASSUME_YES == 0)); then
  printf 'Isso removerá o tmux/LazyVim instalados pelo kit e salvará as configurações em:\n%s\n' "$BACKUP_ROOT"
  read -r -p 'Continuar? [y/N] ' answer
  case "$answer" in
    y|Y|yes|YES|sim|SIM) ;;
    *) printf 'Cancelado.\n'; exit 0 ;;
  esac
fi

if command -v tmux >/dev/null 2>&1; then
  tmux kill-server >/dev/null 2>&1 || true
fi

backup_move "$USER_HOME_DIR/.tmux.conf"
backup_move "$USER_HOME_DIR/.tmux"
backup_move "$XDG_DATA_BASE/tmux"
backup_move "$XDG_CONFIG_BASE/nvim"
backup_move "$XDG_DATA_BASE/nvim"
backup_move "$XDG_STATE_BASE/nvim"
backup_move "$XDG_CACHE_BASE/nvim"
backup_move "$USER_HOME_DIR/.local/opt/neovim"

for helper in nvim tree-sitter dev-session tmux-copy tmux-notes tmux-switcher; do
  backup_move "$LOCAL_BIN_DIR/$helper"
done

if [[ -L "$LOCAL_BIN_DIR/fd" && "$(readlink -- "$LOCAL_BIN_DIR/fd")" == '/usr/bin/fdfind' ]]; then
  backup_move "$LOCAL_BIN_DIR/fd"
fi

if ((KEEP_FONT == 0)); then
  backup_move "$XDG_DATA_BASE/fonts/MesloLGS-Nerd-Font"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
fi

remove_path_block "$USER_HOME_DIR/.profile"
remove_path_block "$USER_HOME_DIR/.zshrc"
remove_path_block "$USER_HOME_DIR/.bashrc"

rm -f -- "$STATE_ROOT/install-manifest"

if ((PURGE_PACKAGES)); then
  log "Removendo o pacote tmux pelo APT..."
  sudo apt-get purge -y tmux
fi

printf '\n\033[1;32mDesinstalação concluída.\033[0m\n'
if ((MOVED_ANYTHING)); then
  printf 'Backup recuperável: %s\n' "$BACKUP_ROOT"
fi
if ((PURGE_PACKAGES == 0)); then
  printf 'O binário do tmux foi mantido. Para removê-lo também: sudo apt purge tmux\n'
fi
printf 'Abra um novo terminal para atualizar o PATH.\n'
