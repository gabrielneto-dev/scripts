#!/usr/bin/env bash
# Migrador Pop!_OS -> Linux Mint (backup portatil + restaurador por backup).
# Requer Bash 4+, GNU tar, GNU coreutils. Executar como usuario comum.
set -Eeuo pipefail
umask 077

VERSION='1.3.0'
APPDIR="${XDG_CONFIG_HOME:-$HOME/.config}/linux-migrador"
PATHS_FILE="$APPDIR/pastas.txt"
BACKUP=''
BACKUP_ROOT=''
LOG=''
ERRORS=0
WARNINGS=0
mkdir -p -- "$APPDIR"
[[ -f "$PATHS_FILE" ]] || : > "$PATHS_FILE"

declare -a CUSTOM_PATHS=()
while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -z "$path" ]] || CUSTOM_PATHS+=("$path")
done < "$PATHS_FILE"

log() {
  local line
  line="[$(date '+%F %T')] $*"
  printf '%s\n' "$line"
  if [[ -n "$LOG" ]]; then printf '%s\n' "$line" >> "$LOG"; fi
}
warning() {
  WARNINGS=$((WARNINGS + 1))
  log "AVISO: $*"
  if [[ -n "$BACKUP" ]]; then printf 'AVISO: %s\n' "$*" >> "$BACKUP/06-relatorios/ALERTAS.txt"; fi
}
error_stage() {
  ERRORS=$((ERRORS + 1))
  log "ERRO: $*"
  if [[ -n "$BACKUP" ]]; then printf 'ERRO: %s\n' "$*" >> "$BACKUP/06-relatorios/ALERTAS.txt"; fi
}
need() { command -v "$1" >/dev/null 2>&1; }
ask() {
  local answer
  read -r -p "$1 [s/N]: " answer || return 1
  [[ "$answer" =~ ^[sSyY]$ ]]
}

contains_path() { # $1 ancestor, $2 candidate
  [[ "$2" == "$1" || "$2" == "$1/"* ]]
}

add_path() {
  local input canonical existing
  read -r -e -p 'Caminho absoluto do arquivo/pasta adicional: ' input || return
  [[ "$input" = /* && -e "$input" ]] || { echo 'Caminho inexistente ou relativo.'; return 0; }
  [[ "$input" != *$'\n'* ]] || { echo 'Caminhos com quebra de linha não são suportados.'; return 0; }
  canonical=$(realpath -e -- "$input") || return
  if [[ "$canonical" == / || "$canonical" == /proc || "$canonical" == /proc/* || "$canonical" == /sys || "$canonical" == /sys/* || "$canonical" == /dev || "$canonical" == /dev/* || "$canonical" == /run || "$canonical" == /run/* ]]; then
    echo 'Pasta virtual ou raiz proibida.'
    return 0
  fi
  for existing in "${CUSTOM_PATHS[@]}"; do
    if [[ "$canonical" == "$existing" ]]; then echo 'Caminho já cadastrado.'; return 0; fi
  done
  CUSTOM_PATHS+=("$canonical")
  printf '%s\n' "$canonical" >> "$PATHS_FILE"
  echo "Incluído: $canonical"
}

choose_dest() {
  local input home_real root_disk dest_disk p
  read -r -e -p 'Destino absoluto do backup (recomendado HD externo criptografado): ' input || return 1
  [[ "$input" = /* && -n "$input" ]] || { echo 'Use caminho absoluto.'; return 1; }
  mkdir -p -- "$input" || return 1
  input=$(realpath -e -- "$input") || return 1
  home_real=$(realpath -e -- "$HOME")
  if [[ "$input" == / ]] || contains_path "$home_real" "$input"; then
    echo 'Destino inválido: escolha fora da Home e da raiz.'
    return 1
  fi
  [[ -w "$input" ]] || { echo 'Destino sem acesso de escrita.'; return 1; }
  # Custom path containing the destination leads to recursive backup and must fail beforehand.
  for p in "${CUSTOM_PATHS[@]}"; do
    [[ -e "$p" ]] || continue
    p=$(realpath -e -- "$p") || continue
    if contains_path "$p" "$input"; then
      echo "ERRO: destino está dentro da pasta adicional '$p'. Altere destino ou remova essa pasta da lista."
      return 1
    fi
  done
  # /opt and /usr/local/bin are included in the system archive.
  for p in /opt /usr/local/bin /usr/local/sbin /etc; do
    if contains_path "$p" "$input"; then
      echo "ERRO: destino dentro de '$p', que integra o backup global. Selecione outra unidade."
      return 1
    fi
  done
  DEST="$input"
  local fs
  fs=$(findmnt -no FSTYPE -T "$DEST" 2>/dev/null || true)
  case "$fs" in
    vfat|exfat|ntfs|ntfs3) echo 'OBS: o TAR preserva metadados, mas não extraia diretamente em FAT/NTFS.';;
  esac
  root_disk=$(findmnt -no SOURCE -T / 2>/dev/null || true)
  dest_disk=$(findmnt -no SOURCE -T "$DEST" 2>/dev/null || true)
  if [[ -n "$root_disk" && "$root_disk" == "$dest_disk" ]]; then
    echo 'AVISO: o destino parece estar no mesmo sistema de arquivos da raiz. Não sobreviverá a uma formatação dessa unidade.'
  fi
  echo 'CONFIDENCIAL: este script NÃO criptografa o backup (chaves SSH, Wi-Fi, .env e tokens).'
  ask 'Confirma que o destino está protegido e não será formatado?' || return 1
}

report_cmd() {
  local heading=$1; shift
  {
    printf '\n### %s\n\n```text\n' "$heading"
    "$@" 2>&1 || true
    printf '\n```\n'
  } >> "$BACKUP/06-relatorios/INVENTARIO.md"
}

collect() {
  log 'Gerando inventários e relatórios.'
  printf '# Inventário do Pop!_OS\n\nData: %s  \nHost: %s  \nUsuário: %s  \nMigrador: %s\n\n' \
    "$(date -Is)" "$(hostname)" "${USER:-$(id -un)}" "$VERSION" > "$BACKUP/06-relatorios/INVENTARIO.md"
  report_cmd 'Sistema, discos e partições' bash -c 'cat /etc/os-release; uname -a; lsblk -f; df -hT'
  report_cmd 'APT instalados manualmente' bash -c 'apt-mark showmanual'
  report_cmd 'DPKG - lista instalada' dpkg-query -W '-f=${binary:Package}\t${Version}\n'
  report_cmd 'Flatpak' bash -c 'flatpak list --app --columns=application,version,origin || true'
  report_cmd 'Snap' bash -c 'snap list || true'
  report_cmd 'Versões no PATH' bash -c 'for x in node npm npx pnpm yarn bun deno python python3 pip pip3 pipx poetry uv ruby gem java javac mvn gradle go rustc cargo rustup dotnet php composer gcc g++ clang make cmake git docker podman nvim vim tmux zsh bash code codium claude codex n8n; do if command -v "$x" >/dev/null 2>&1; then printf "%-14s %s | " "$x" "$(command -v "$x")"; "$x" --version 2>&1 | head -n 2 | tr "\n" " "; printf "\n"; fi; done'
  report_cmd 'Gerenciadores de versão/SDK' bash -c 'for p in "$HOME/.nvm" "$HOME/.pyenv" "$HOME/.sdkman" "$HOME/.rustup" "$HOME/.cargo" "$HOME/.asdf" "$HOME/.local/share/mise"; do [[ ! -e "$p" ]] || ls -ld -- "$p"; done; command -v mise || true; command -v asdf || true; command -v nvm || true'
  report_cmd 'Versões instaladas em gerenciadores' bash -c 'for p in "$HOME/.nvm/versions/node" "$HOME/.pyenv/versions" "$HOME/.sdkman/candidates" "$HOME/.rustup/toolchains" "$HOME/.asdf/installs" "$HOME/.local/share/mise/installs" "$HOME/.dotnet/sdk"; do if [[ -d "$p" ]]; then echo "## $p"; find "$p" -mindepth 1 -maxdepth 2 -type d -print 2>/dev/null | head -150; fi; done'
  report_cmd 'npm/pnpm globais' bash -c 'npm -g ls --depth=0 || true; pnpm -g ls --depth=0 || true'
  report_cmd 'pipx/pip global' bash -c 'pipx list || true; python3 -m pip list --format=freeze || true'
  report_cmd 'Alternatives' bash -c 'update-alternatives --get-selections || true'
  report_cmd 'Serviços habilitados' bash -c 'systemctl list-unit-files --state=enabled --no-pager || true; systemctl --user list-unit-files --state=enabled --no-pager || true'
  report_cmd 'Cron do usuário' bash -c 'crontab -l || true'
  report_cmd 'Shell, fontes e PATH' bash -c 'echo "SHELL=$SHELL"; echo "PATH=$PATH"; fc-list : family 2>/dev/null | sort -u | head -100'
  report_cmd 'Fontes dos repositórios APT' bash -c 'grep -RhE "^(deb |URIs:|Suites:)" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null || true'
  report_cmd 'Atalhos GNOME/dconf' bash -c 'for k in /org/gnome/settings-daemon/plugins/media-keys/ /org/gnome/desktop/wm/keybindings/ /org/gnome/mutter/keybindings/; do echo "$k"; dconf dump "$k" 2>/dev/null || true; done'
  if need dconf; then dconf dump / > "$BACKUP/03-sistema/dconf-completo.ini" 2>> "$LOG" || warning 'Não foi possível exportar toda a base dconf.'; fi
  if [[ -d "$HOME/.config/cosmic" ]]; then
    find "$HOME/.config/cosmic" -type f -print > "$BACKUP/06-relatorios/COSMIC-ARQUIVOS.txt" 2>>"$LOG" || warning 'Inventário COSMIC incompleto.'
  fi
  {
    printf '# Atalhos de teclado (referência, não importação)\n\n'
    printf 'Atalhos COSMIC não são compatíveis diretamente com os do Cinnamon.\n\n'
    printf '## GNOME/dconf\n\n```ini\n'
    if need dconf; then
      for k in /org/gnome/settings-daemon/plugins/media-keys/ /org/gnome/desktop/wm/keybindings/; do
        printf '\n# %s\n' "$k"
        dconf dump "$k" 2>/dev/null || true
      done
    fi
    printf '\n```\n\n## COSMIC\n\n'
    printf 'Arquivos originais estão em `01-arquivos/home.tar` e listados em `COSMIC-ARQUIVOS.txt`.\n'
    printf '\n## Possíveis arquivos de atalhos COSMIC (conteúdo legível, até 200 linhas por arquivo)\n'
    if [[ -d "$HOME/.config/cosmic" ]]; then
      while IFS= read -r -d '' config_file; do
        printf '\n### %s\n\n```text\n' "$config_file"
        if [[ $(wc -c < "$config_file") -le 131072 ]] && grep -Iq . "$config_file"; then
          sed -n '1,200p' "$config_file" || true
        else
          printf 'Arquivo binário ou extenso: confira o original no TAR.\n'
        fi
        printf '\n```\n'
      done < <(find "$HOME/.config/cosmic" -type f \( -iname '*shortcut*' -o -iname '*keybind*' -o -iname '*binding*' \) -print0 2>/dev/null)
    fi
  } > "$BACKUP/06-relatorios/ATALHOS.md"
  {
    printf '# SSH — inventário confidencial\n\n'
    printf 'Chaves privadas e valores sensíveis não são impressos aqui.\n\n'
    printf '## Hosts, aliases e nomes de usuário\n\n```text\n'
    if [[ -f "$HOME/.ssh/config" ]]; then
      awk 'BEGIN { IGNORECASE=1 } tolower($1)=="host" || tolower($1)=="hostname" || tolower($1)=="user" || tolower($1)=="port" || tolower($1)=="identityfile" || tolower($1)=="include" || tolower($1)=="proxyjump" || tolower($1)=="identitiesonly" { print }' "$HOME/.ssh/config"
    fi
    printf '\n```\n\n## Arquivos na pasta .ssh\n\n```text\n'
    if [[ -d "$HOME/.ssh" ]]; then find "$HOME/.ssh" -maxdepth 3 -type f -printf '%P\n' 2>/dev/null || true; fi
    printf '\n```\n'
  } > "$BACKUP/06-relatorios/SSH.md"
  {
    printf '# Aplicativos\n\n'
    printf 'APT, DPKG, Flatpak e Snap: consulte `INVENTARIO.md`.\n\n'
    printf '## Possíveis instalações manuais\n\n```text\n'
    ls -ld /opt/* /usr/local/bin/* "$HOME"/Applications/* "$HOME"/.local/share/applications/* 2>/dev/null || true
    printf '\n```\n\n## AppImages encontrados na Home (limite: profundidade 7)\n\n```text\n'
    find "$HOME" -maxdepth 7 -type f -iname '*.AppImage' -print 2>/dev/null || true
    printf '\n```\n'
  } > "$BACKUP/06-relatorios/APLICATIVOS.md"
  {
    printf '# Linguagens e SDKs\n\n'
    printf 'O inventário de versões está em `INVENTARIO.md` na seção **Versões no PATH**.\n'
    printf 'Instalações fora do PATH, por projeto ou em outras contas podem não ser detectadas.\n'
  } > "$BACKUP/06-relatorios/LINGUAGENS.md"
  printf '%s\n' "${CUSTOM_PATHS[@]}" > "$BACKUP/06-relatorios/PASTAS-ADICIONAIS.txt"
  printf 'Configurações de aplicativos, SSH e shell estão preservadas dentro de 01-arquivos/home.tar.\n' > "$BACKUP/02-configuracoes/LOCALIZACAO.txt"
  printf 'Ferramentas e SDKs inventariados em 06-relatorios/INVENTARIO.md e LINGUAGENS.md.\n' > "$BACKUP/04-desenvolvimento/LOCALIZACAO.txt"
  cat > "$BACKUP/06-relatorios/BANCOS-E-DOCKER.md" <<'DOC'
# Docker e bancos de dados: conferência obrigatória

Os metadados e arquivos Compose **não substituem** dumps consistentes dos bancos.
Antes de formatar, faça dumps PostgreSQL, MySQL, SQLite etc. conforme sua configuração real,
e teste a restauração. Volumes vinculados a diretórios fora da Home precisam estar nas pastas adicionais.
Imagens Docker listadas NÃO foram exportadas; precisam ser baixadas/criadas novamente.
DOC
  log 'Inventários criados.'
}

copy_home() {
  log 'Arquivando Home, incluindo dotfiles/SSH (sem caches e dependências regeneráveis).'
  if tar --acls --xattrs --numeric-owner -cpf "$BACKUP/01-arquivos/home.tar" \
      --exclude='./.cache' --exclude='./.local/share/Trash' \
      --exclude='*/node_modules' --exclude='*/.venv' --exclude='*/.git/objects/pack/tmp_*' \
      -C "$HOME" . 2>> "$LOG"; then
    log 'Home: cópia realizada.'
  else
    error_stage 'Falha ou alteração detectada durante cópia da Home. Backup NÃO está completo.'
  fi
  local p i=0 archive
  for p in "${CUSTOM_PATHS[@]}"; do
    if [[ ! -e "$p" ]]; then warning "Pasta adicional não existe: $p"; continue; fi
    p=$(realpath -e -- "$p") || { error_stage 'Falha ao resolver caminho adicional.'; continue; }
    i=$((i + 1))
    archive="$BACKUP/01-arquivos/adicional-$(printf '%03d' "$i").tar"
    log "Copiando pasta adicional: $p"
    if sudo tar --acls --xattrs --numeric-owner -cpf - -C / "${p#/}" > "$archive" 2>> "$LOG"; then
      printf '%03d\t%s\n' "$i" "$p" >> "$BACKUP/01-arquivos/adicionais.tsv"
    else
      error_stage "Não foi possível copiar integralmente: $p"
    fi
  done
}

copy_system() {
  local p
  local -a paths=(etc/ssh etc/NetworkManager/system-connections etc/systemd/system etc/cron.d etc/crontab etc/fstab etc/hosts etc/hostname etc/environment etc/profile.d etc/udev/rules.d usr/local/bin usr/local/sbin opt)
  local -a found=()
  for p in "${paths[@]}"; do [[ ! -e "/$p" ]] || found+=("$p"); done
  if ((${#found[@]} == 0)); then warning 'Nenhum dos diretórios globais esperados foi encontrado.'; return; fi
  log 'Arquivando configurações globais e perfis Wi-Fi via sudo.'
  if sudo tar --acls --xattrs --numeric-owner -cpf - -C / "${found[@]}" > "$BACKUP/03-sistema/sistema.tar" 2>> "$LOG"; then
    log 'Sistema: cópia realizada, com restauração SOMENTE manual.'
  else
    error_stage 'Cópia global falhou (sudo, permissões, leitura ou arquivos alterados).'
  fi
  # Comprovar que os perfis persistentes fizeram parte do backup global.
  # Não exportar senhas via nmcli; o TAR preserva os arquivos originais.
  if [[ -d /etc/NetworkManager/system-connections ]]; then
    if [[ ! -f "$BACKUP/03-sistema/sistema.tar" ]] || ! tar -tf "$BACKUP/03-sistema/sistema.tar" 2>/dev/null | grep '^etc/NetworkManager/system-connections/' > /dev/null; then
      error_stage 'Diretório de perfis Wi-Fi não foi encontrado no arquivo do sistema.'
    else
      log 'Perfis persistentes de NetworkManager presentes no sistema.tar (não garante segredos do chaveiro).'
    fi
  else
    warning 'Diretório padrão de perfis Wi-Fi não existe: verifique NetworkManager, chaveiro e perfis de outra origem.'
  fi
}

docker_backup() {
  if ! need docker; then warning 'Docker não instalado: inventário ignorado.'; return; fi
  if ! docker info >/dev/null 2>&1; then warning 'Docker não está acessível: inventário ignorado. Verifique daemon/permissões.'; return; fi
  log 'Inventariando Docker.'
  if ! docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' > "$BACKUP/05-docker/containers.tsv"; then
    error_stage 'Falha ao listar containers Docker.'
  fi
  if ! docker image ls --format '{{.Repository}}:{{.Tag}}' > "$BACKUP/05-docker/imagens.txt"; then
    error_stage 'Falha ao listar imagens Docker.'
  fi
  if ! docker network ls > "$BACKUP/05-docker/redes.txt"; then
    error_stage 'Falha ao listar redes Docker.'
  fi
  if ! docker volume ls --format '{{.Name}}' > "$BACKUP/05-docker/volumes.txt"; then
    error_stage 'Falha ao listar volumes Docker.'
  fi
  if ! docker ps -aq > "$BACKUP/05-docker/ids.txt"; then
    error_stage 'Falha ao listar IDs de containers Docker.'
  else
    local -a ids=()
    mapfile -t ids < "$BACKUP/05-docker/ids.txt"
    if ((${#ids[@]})); then
      if ! docker inspect "${ids[@]}" > "$BACKUP/05-docker/inspect-containers.json" 2>> "$LOG"; then
        error_stage 'Docker inspect falhou; descrições de bind mounts/volumes podem estar incompletas.'
      fi
      # Relatório legível das origens de volumes/bind mounts; não copiar dados de binds automaticamente.
      if ! docker inspect --format '{{.Name}}{{range .Mounts}}{{printf "\n"}}{{.Type}}|{{.Source}}|{{.Destination}}{{end}}{{printf "\n"}}' "${ids[@]}" > "$BACKUP/05-docker/montagens.txt" 2>> "$LOG"; then
        warning 'Falha ao inventariar montagens Docker.'
      fi
    fi
  fi
  warning 'Docker: inventário NÃO é cópia completa. Faça dumps de bancos, backup dos bind mounts e revisão dos arquivos Compose.'
  echo 'Volumes em uso serão IGNORADOS. Pare aplicações/bancos e faça dumps consistentes antes de exportar.'
  if ! ask 'Exportar agora volumes Docker que NÃO estão em uso por containers executando?'; then
    warning 'Exportação de volumes Docker não solicitada; dados dos volumes NÃO foram copiados.'
    return
  fi
  local vol filename running
  if [[ ! -f "$BACKUP/05-docker/volumes.txt" ]]; then error_stage 'Inventário de volumes não encontrado.'; return; fi
  printf 'VOLUME\tRESULTADO\n' > "$BACKUP/05-docker/resultado-volumes.tsv"
  while IFS= read -r vol; do
    [[ -n "$vol" ]] || continue
    # Se a consulta de uso falhar, nunca presumir que o volume está livre.
    if ! running=$(docker ps -q --filter "volume=$vol"); then
      error_stage "Não foi possível verificar se o volume está em uso: $vol. Exportação bloqueada."
      printf '%s\tERRO_CONSULTA\n' "$vol" >> "$BACKUP/05-docker/resultado-volumes.tsv"
      continue
    fi
    if [[ -n "$running" ]]; then
      warning "Volume ainda em uso, ignorado: $vol"
      printf '%s\tEM_USO_NAO_COPIADO\n' "$vol" >> "$BACKUP/05-docker/resultado-volumes.tsv"
      continue
    fi
    filename="volume-${vol//\//_}.tar"
    if docker run --rm \
      --mount "type=volume,source=$vol,target=/source,readonly" \
      alpine:3.20 sh -c 'cd /source && tar -cpf - .' > "$BACKUP/05-docker/$filename" 2>> "$LOG" \
      && [[ -s "$BACKUP/05-docker/$filename" ]] \
      && tar -tf "$BACKUP/05-docker/$filename" >/dev/null 2>> "$LOG"; then
      printf '%s\tEXPORTADO\n' "$vol" >> "$BACKUP/05-docker/resultado-volumes.tsv"
      log "Volume exportado: $vol"
    else
      error_stage "Erro ao exportar/verificar volume Docker: $vol"
      printf '%s\tERRO_EXPORTACAO\n' "$vol" >> "$BACKUP/05-docker/resultado-volumes.tsv"
      rm -f -- "$BACKUP/05-docker/$filename"
    fi
  done < "$BACKUP/05-docker/volumes.txt"
}

generate_restore_bundle() {
  # Os tres itens no nivel superior sao backup/, restaurar.sh e USO.md.
  cat > "$BACKUP_ROOT/restaurar.sh" <<'MIGRADOR_RESTAURADOR_SCRIPT'
#!/usr/bin/env bash
# Gerado pelo Migrador Pop!_OS -> Mint. Executar como usuario comum no Linux Mint.
# Restaura arquivos da Home SEM sobrescrever arquivos existentes; itens globais ficam em conferencia.
set -Eeuo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DATA="$ROOT/backup"
MODE="${1:-restaurar}"

say() { printf '[restaurador] %s\n' "$*"; }
fail() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Comando necessario nao encontrado: $1"; }

case "$MODE" in
  restaurar|--verificar|--somente-conferir|--ajuda) ;;
  *) fail 'Uso: bash restaurar.sh [--verificar | --somente-conferir | --ajuda]' ;;
esac
if [[ "$MODE" == --ajuda ]]; then
  cat <<'HELP'
Uso:
  bash ./restaurar.sh                   Verifica e inicia a restauração assistida sem menu
  bash ./restaurar.sh --verificar       Confere integridade, nao altera arquivos
  bash ./restaurar.sh --somente-conferir Verifica e extrai para pasta separada, sem integrar à Home

O modo padrao pede confirmacao antes de copiar arquivos novos para a sua Home.
Nunca sobrescreve arquivos existentes, nem importa automaticamente /etc, Docker ou atalhos COSMIC.
HELP
  exit 0
fi
[[ "$(id -u)" -ne 0 ]] || fail 'Nao execute como root. Entre no Mint como usuario comum.'
[[ -d "$DATA" && ! -L "$DATA" ]] || fail 'Pasta backup/ ausente ou nao confiavel.'
[[ -f "$DATA/checksums.sha256" ]] || fail 'Falta backup/checksums.sha256.'
[[ -f "$DATA/01-arquivos/home.tar" ]] || fail 'Falta backup/01-arquivos/home.tar.'
[[ -f "$DATA/06-relatorios/estado.txt" ]] || fail 'Falta o estado do backup.'
need sha256sum
need tar
need find

STATUS="$(cat -- "$DATA/06-relatorios/estado.txt")"
case "$STATUS" in
  SUCESSO|COM_RESSALVAS) ;;
  *) fail "Estado nao seguro para restaurar: $STATUS" ;;
esac
say 'Verificando hashes SHA-256 dos arquivos de backup...'
if ! (cd "$DATA" && sha256sum --check --status checksums.sha256); then
  fail 'Checksum incorreto ou arquivo faltando. Nao restaure, refaca o backup.'
fi
say 'Conferindo os arquivos TAR...'
while IFS= read -r -d '' archive; do
  if ! tar -tf "$archive" >/dev/null; then fail "Arquivo TAR invalido: $archive"; fi
done < <(find "$DATA" -type f -name '*.tar' -print0)
say 'Integridade verificada. Ela nao comprova que dados externos, bancos e Docker foram incluidos.'
if [[ "$MODE" == --verificar ]]; then exit 0; fi

# Check TAR member names, block unsafe paths and special files before any extraction.
# Only accept archives created as relative paths by the migrador.
validate_archive() {
  local archive="$1" entry
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    case "$entry" in
      /*|../*|*/../*|*/..|..|*/./../*) fail "Caminho inseguro no TAR: $archive" ;;
    esac
  done < <(tar -tf "$archive")
  if tar -tvf "$archive" 2>/dev/null | LC_ALL=C grep -Eq '^[bcp]'; then
    fail "TAR tem arquivo especial (bloco, caractere ou pipe): $archive"
  fi
}
validate_archive "$DATA/01-arquivos/home.tar"

DEST_PARENT="${MIGRADOR_RESTORE_PARENT:-$HOME}"
[[ -d "$DEST_PARENT" && -w "$DEST_PARENT" ]] || fail "Destino temporario indisponivel: $DEST_PARENT"
TARGET="$(mktemp -d "$DEST_PARENT/Migracao-Mint-XXXXXXXX")" || fail 'Nao foi possivel criar pasta de conferencia.'
chmod 700 "$TARGET"
mkdir -p "$TARGET/home" "$TARGET/adicionais" "$TARGET/sistema" "$TARGET/docker" "$TARGET/relatorios"
REPORT="$TARGET/relatorios/RESTAURACAO.md"
{
  printf '# Relatorio de restauracao\n\n'
  printf -- '- Backup: `%s`\n' "$ROOT"
  printf -- '- Destino de conferencia: `%s`\n' "$TARGET"
  printf -- '- Executado em: %s\n' "$(date -Is)"
  printf -- '- Estado original: %s\n\n' "$STATUS"
} > "$REPORT"
say "Extraindo arquivos para: $TARGET"
if ! tar --no-same-owner --no-same-permissions -xf "$DATA/01-arquivos/home.tar" -C "$TARGET/home"; then
  fail "Erro ao extrair Home. Verifique espaco e permissões. Copia parcial permanece em $TARGET"
fi

# Extract extras into separate directories, never into their original absolute paths.
while IFS= read -r -d '' archive; do
  validate_archive "$archive"
  base="$(basename -- "$archive" .tar)"
  mkdir -p "$TARGET/adicionais/$base"
  if ! tar --no-same-owner --no-same-permissions -xf "$archive" -C "$TARGET/adicionais/$base"; then
    fail "Extracao adicional falhou: $archive. Confirme espaco em disco."
  fi
done < <(find "$DATA/01-arquivos" -maxdepth 1 -type f -name 'adicional-*.tar' -print0 | sort -z)

# Extract system configuration ONLY to separate staging, never automatically into /etc.
if [[ -f "$DATA/03-sistema/sistema.tar" ]]; then
  validate_archive "$DATA/03-sistema/sistema.tar"
  if ! tar --no-same-owner --no-same-permissions -xf "$DATA/03-sistema/sistema.tar" -C "$TARGET/sistema"; then
    fail 'Falha ao extrair configuracoes globais.'
  fi
fi
# Docker volume tarballs remain untouched. It is dangerous to restore a database over a live container.
if [[ -d "$DATA/05-docker" ]]; then
  cp -a -- "$DATA/05-docker/." "$TARGET/docker/"
fi
if [[ -d "$DATA/06-relatorios" ]]; then
  cp -a -- "$DATA/06-relatorios/." "$TARGET/relatorios/"
fi

say 'A extracao inicial terminou.'
if [[ "$MODE" == --somente-conferir ]]; then
  printf '\nArquivos extraidos: %s\nNenhum dado foi integrado a Home.\n' "$TARGET"
  printf '\n- Modo: somente conferencia\n' >> "$REPORT"
  exit 0
fi

say 'Serao adicionados arquivos AUSENTES da Home antiga para esta Home, sem substituir os existentes.'
say 'Configuracoes COSMIC e dconf nao serao importadas (consulte a pasta de conferencia).'
say 'APT, Flatpak, SSH global, Wi-Fi, Docker e bancos nao serao reinstalados/importados automaticamente.'
read -r -p 'Digite RESTAURAR para confirmar a copia de arquivos novos para a Home: ' confirmation || fail 'Operacao cancelada.'
[[ "$confirmation" == RESTAURAR ]] || fail "Cancelado. Copia para conferencia: $TARGET"
if command -v rsync >/dev/null 2>&1; then
  # Existing Mint files win. COSMIC and dconf remain in staging for manual migration.
  if ! rsync -a --no-owner --no-group --no-perms --executability --omit-dir-times --ignore-existing --safe-links \
      --exclude='/.config/cosmic/***' \
      --exclude='/.config/dconf/***' \
      --exclude='/.config/gnome-shell/***' \
      --exclude='/.local/share/gnome-shell/***' \
      --exclude='/.config/gtk-4.0/***' \
      --exclude='/.config/gtk-3.0/***' \
      --exclude='/.local/share/cosmic/***' \
      --exclude='/.local/state/cosmic/***' \
      "$TARGET/home/" "$HOME/"; then
    fail "Copia para Home falhou. Os arquivos originais estao em $TARGET/home"
  fi
  # Arquivos existentes são preservados; registrar caminhos para revisão manual.
  conflicts="$TARGET/relatorios/CONFLITOS-HOME.txt"
  : > "$conflicts"
  while IFS= read -r -d '' path; do
    rel="${path#"$TARGET/home/"}"
    if [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]]; then
      printf '%q\n' "$rel" >> "$conflicts"
    fi
  done < <(find "$TARGET/home" -type f -print0)
  printf '\n- Modo: aplicacao sem sobrescrita\n- Destino: `%s`\n- Conflitos: `%s`\n' "$HOME" "$conflicts" >> "$REPORT"
  say "Concluido. Arquivos novos copiados para $HOME, arquivos existentes preservados."
  say "Arquivos que ja existiam e exigem conferencia: $conflicts"
else
  printf '\n- Modo: conferencia, rsync ausente\n' >> "$REPORT"
  say 'rsync nao instalado; integracao automatica da Home foi pulada. Para instalar: sudo apt install rsync'
fi
say "Arquivos extras, /etc, Docker e relatorios foram mantidos em: $TARGET"
say 'Consulte USO.md e o relatorio de restauracao antes de reconfigurar serviços.'
MIGRADOR_RESTAURADOR_SCRIPT
  chmod 700 "$BACKUP_ROOT/restaurar.sh" || warning 'O disco nao suporta chmod; execute no Mint com bash restaurar.sh.'
  cat > "$BACKUP_ROOT/USO.md" <<'MIGRADOR_USO'
# Restaurar este backup no Linux Mint

**Este backup pode conter chaves privadas SSH, senhas Wi-Fi, tokens e arquivos `.env`.** Guarde a unidade protegida. O script não fornece criptografia.

Este diretório contém somente três itens no nível superior:

- `backup/`: arquivos TAR de dados, inventários, avisos, estado e manifesto de integridade.
- `restaurar.sh`: restaurador independente, vinculado à pasta atual; dispensa o `migrador.sh` original.
- `USO.md`: estas instruções.

## Passos após instalar o Linux Mint

1. Conecte e monte o HD externo. Abra **esta pasta específica** do backup.
2. Abra um terminal aqui, como seu usuário normal (**não** rode com `sudo`).
3. Para conferir dados antes de qualquer extração, rode:

   ```bash
   bash ./restaurar.sh --verificar
   ```

4. Para extrair tudo em uma pasta de conferência, sem integrar à Home:

   ```bash
   bash ./restaurar.sh --somente-conferir
   ```

5. Para executar a restauração assistida **sem menu**:

   ```bash
   bash ./restaurar.sh
   ```

   O script primeiro confere SHA-256 e estrutura dos TARs. Depois extrai a Home e as pastas extras em `~/Migracao-Mint-XXXXXXXX/`. Em seguida solicita confirmação digitando **RESTAURAR** para **copiar somente arquivos ausentes** para sua nova Home, preservando os arquivos já existentes. O relatório `relatorios/CONFLITOS-HOME.txt` lista caminhos que já existem no Mint, como `.zshrc`, para você mesclar manualmente. É preciso ter `rsync` instalado (`sudo apt install rsync`).

   Em unidades Linux pode executar `chmod +x restaurar.sh && ./restaurar.sh`; em exFAT/NTFS use `bash ./restaurar.sh`, pois o sistema de arquivos ou a montagem pode não permitir bit executável.

6. Veja `~/Migracao-Mint-XXXXXXXX/relatorios/RESTAURACAO.md`, `backup/06-relatorios/STATUS.md` e os avisos do backup.

## O que **não** é aplicado automaticamente

- `sistema.tar`: SSH global, configurações de Wi-Fi, systemd, cron, `/opt` etc. São extraídos para `~/Migracao-Mint-XXXXXXXX/sistema/` para revisão. **Não** copie o `/etc` do Pop!_OS por cima do Mint.
- Pastas extras: extraídas em `~/Migracao-Mint-XXXXXXXX/adicionais/`, preservando a estrutura original. Selecione os caminhos a integrar manualmente.
- Docker: inventários e eventuais volumes exportados ficam em `~/Migracao-Mint-XXXXXXXX/docker/`; não são carregados nem recriados. Bancos precisam de backups consistentes e restauração própria.
- Aplicativos, APT, Flatpak, linguagens e versões de SDK: inventariados em `backup/06-relatorios/`, **não são reinstalados** automaticamente por motivos de compatibilidade e segurança.
- Atalhos COSMIC, GNOME e dconf: podem ser consultados nos relatórios, mas não são importados automaticamente no Cinnamon. Os diretórios COSMIC/dconf ficam na conferência.
- Credenciais protegidas por chaveiro podem exigir novo login.

Se o backup está marcado **INCOMPLETO**, o restaurador impede a restauração. `COM_RESSALVAS` exige revisão dos avisos antes de formatar. Checksums não garantem que todos os dados necessários tenham sido coletados.

**Permissões em EXT4:** se a nova conta tiver UID diferente, você poderá precisar ajustar a propriedade da pasta no seu HD com `sudo chown -R "$(id -u):$(id -g)" "/caminho/da/pasta/PopOS-..."` (use apenas em pastas do seu próprio backup). Em NTFS/exFAT, o dono depende das opções de montagem.

**Nunca formate antes de testar a integridade, a extração, os repositórios e os serviços/bancos importantes.**
MIGRADOR_USO
}

finalize_backup() {
  local state
  if (( ERRORS > 0 )); then state='INCOMPLETO';
  elif (( WARNINGS > 0 )); then state='COM_RESSALVAS';
  else state='SUCESSO'; fi
  cat > "$BACKUP/06-relatorios/STATUS.md" <<EOF
# Resultado da execução

- Estado: **$state**
- Erros de cópia: **$ERRORS**
- Avisos: **$WARNINGS**
- Origem: **$(hostname)**
- Data e hora: **$(date -Is)**
- Pasta portátil: **$BACKUP_ROOT**

Verifique ALERTAS.txt e execucao.log.
**Checksum não comprova backup completo**. Faça testes antes de formatar.
EOF
  printf '%s\n' "$state" > "$BACKUP/06-relatorios/estado.txt"
  log "Estado final: $state ($ERRORS erros, $WARNINGS avisos)."
  if ! (cd "$BACKUP" && find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 -r sha256sum > checksums.sha256); then
    printf 'ERRO: falha ao gerar manifesto SHA256. Nao formate.\n'
    return 1
  fi
  printf '\nBackup portátil em: %s\nEstado: %s\n' "$BACKUP_ROOT" "$state"
  if (( ERRORS > 0 )); then
    echo 'BACKUP INCOMPLETO. Confira erros, corrija e execute novamente.'
    return 1
  fi
  echo 'Agora esta pasta contém backup/, restaurar.sh e USO.md. Teste antes de formatar.'
}

backup() {
  if ! choose_dest; then return 0; fi
  local host id
  host="$(hostname | LC_ALL=C tr -cd '[:alnum:]._-')"
  host="${host:0:24}"
  [[ -n "$host" ]] || host='host'
  id="$(printf '%04x%04x' "$RANDOM" "$RANDOM")"
  BACKUP_ROOT="$DEST/PopOS-$(date +%Y%m%d-%H%M%S)-$host-$id"
  BACKUP="$BACKUP_ROOT/backup"
  LOG=''
  ERRORS=0
  WARNINGS=0
  if ! mkdir -m 700 -- "$BACKUP_ROOT"; then echo 'Nao foi possivel criar destino exclusivo.'; return 1; fi
  mkdir -p "$BACKUP"/{01-arquivos,02-configuracoes,03-sistema,04-desenvolvimento,05-docker,06-relatorios}
  LOG="$BACKUP/06-relatorios/execucao.log"
  : > "$LOG"
  log "Inicio do backup portatil em $BACKUP_ROOT"
  cat > "$BACKUP/06-relatorios/ORIGEM.md" <<EOF
# Origem deste backup

- Sistema: $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | head -1 || true)
- Host: $(hostname)
- Usuario: $(id -un)
- UID/GID: $(id -u)/$(id -g)
- Data e hora ISO: $(date -Is)
- Migrador: $VERSION
- Identificador: $id
EOF
  generate_restore_bundle
  collect
  copy_home
  copy_system
  if ask 'Gerar inventario Docker e, opcionalmente, exportar volumes parados?'; then
    docker_backup
  elif need docker; then
    warning 'Docker nao incluido por escolha do usuario. Containers, volumes e bancos precisam de backup separado.'
  fi
  finalize_backup
}

verify_dir() {
  local dir="$1" payload="$1" failed=0 tarfile state
  if [[ -d "$dir/backup" ]]; then payload="$dir/backup"; fi
  [[ -f "$payload/checksums.sha256" ]] || { echo 'Manifesto SHA256 ausente.'; return 1; }
  [[ -f "$payload/01-arquivos/home.tar" ]] || { echo 'home.tar ausente.'; return 1; }
  echo 'Conferindo checksums de todos os arquivos...'
  if ! (cd "$payload" && sha256sum --check --status checksums.sha256); then
    echo 'ERRO: checksum invalido.'
    failed=1
  fi
  echo 'Validando a leitura dos arquivos TAR...'
  while IFS= read -r -d '' tarfile; do
    if ! tar -tf "$tarfile" >/dev/null; then echo "TAR invalido: $tarfile"; failed=1; fi
  done < <(find "$payload" -type f -name '*.tar' -print0)
  state="$(cat "$payload/06-relatorios/estado.txt" 2>/dev/null || echo DESCONHECIDO)"
  echo "Estado registrado: $state"
  if [[ "$state" != SUCESSO && "$state" != COM_RESSALVAS ]]; then failed=1; fi
  if (( failed > 0 )); then echo 'VERIFICACAO FALHOU.'; return 1; fi
  echo 'Checksums e estrutura dos TARs verificados. Confira alertas e teste a recuperacao.'
}

verify() {
  local dir
  read -r -e -p 'Pasta raiz do backup para verificar: ' dir || return 0
  [[ -d "$dir" ]] || { echo 'Diretorio inexistente.'; return 0; }
  verify_dir "$dir" || return 0
}

# Testes locais realizados na máquina do usuário, sem alterar perfis nem containers existentes.
# Wi-Fi: arquivos são copiados para uma pasta temporária restrita (preferencialmente tmpfs).
# Docker: cria dois volumes e containers EFÊMEROS identificados com 'migrador-autoteste'.
autoteste_wifi() (
  set -u
  local tmp base count
  echo '=== AUTOTESTE WI-FI / NETWORKMANAGER ==='
  if ! need nmcli; then
    echo 'AVISO: nmcli não está disponível. Não é possível testar o daemon NetworkManager.'
  elif ! nmcli -t -f STATE general status >/dev/null 2>&1; then
    echo 'AVISO: o NetworkManager não respondeu ao comando nmcli.'
  else
    echo 'OK: nmcli responde (nenhuma senha foi consultada).'
  fi
  if [[ ! -d /etc/NetworkManager/system-connections ]]; then
    echo 'NÃO TESTADO: diretório /etc/NetworkManager/system-connections não existe.'
    return 2
  fi
  if ! sudo -v; then echo 'FALHA: não foi possível obter permissão sudo.'; return 1; fi
  base='/dev/shm'
  if [[ ! -d "$base" || ! -w "$base" ]]; then
    echo 'FALHA: /dev/shm não disponível para teste seguro em memória.'
    return 1
  fi
  tmp=$(mktemp -d "$base/migrador-wifi.XXXXXXXX") || return 1
  trap 'rm -rf -- "$tmp"' EXIT
  mkdir -p "$tmp/conferencia" || return 1
  if ! sudo tar --acls --xattrs --numeric-owner -cpf - -C / etc/NetworkManager/system-connections > "$tmp/wifi.tar"; then
    echo 'FALHA: não foi possível arquivar perfis Wi-Fi. Verifique sudo e permissões.'
    return 1
  fi
  if ! tar -tf "$tmp/wifi.tar" > /dev/null; then
    echo 'FALHA: arquivo TAR Wi-Fi não pode ser lido.'
    return 1
  fi
  if ! tar --no-same-owner --no-same-permissions -xf "$tmp/wifi.tar" -C "$tmp/conferencia"; then
    echo 'FALHA: extração de conferência Wi-Fi falhou.'
    return 1
  fi
  if [[ ! -d "$tmp/conferencia/etc/NetworkManager/system-connections" ]]; then
    echo 'FALHA: diretório Wi-Fi não apareceu após extração.'
    return 1
  fi
  count=$(find "$tmp/conferencia/etc/NetworkManager/system-connections" -type f | wc -l)
  echo "OK: arquivos de Wi-Fi arquivados e extraídos em memória: $count"
  echo 'Nenhuma conexão foi modificada. Senhas mantidas fora da saída do teste.'
  echo 'ATENÇÃO: senhas guardadas apenas no chaveiro podem não estar nestes arquivos.'
)

autoteste_docker() (
  set -u
  local tmp vol1 vol2 got expected cid='' created1=0 created2=0
  echo '=== AUTOTESTE DOCKER / VOLUMES ==='
  if ! need docker; then echo 'NÃO TESTADO: docker não instalado.'; return 2; fi
  if ! docker info >/dev/null 2>&1; then
    echo 'NÃO TESTADO: daemon indisponível ou sem permissão para acessar Docker.'
    return 2
  fi
  echo 'O teste pode baixar alpine:3.20 e criará dois volumes/containers descartáveis.'
  if ! ask 'Executar teste Docker isolado?'; then echo 'Teste Docker cancelado.'; return 2; fi
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/migrador-docker.XXXXXXXX") || return 1
  vol1="migrador-autoteste-$(date +%s)-$$-$RANDOM-a"
  vol2="migrador-autoteste-$(date +%s)-$$-$RANDOM-b"
  cleanup_docker_test() {
    [[ -z "$cid" ]] || docker stop "$cid" >/dev/null 2>&1 || true
    if (( created1 )); then
      docker volume rm "$vol1" >/dev/null 2>&1 || echo "AVISO: remova manualmente o volume temporário $vol1" >&2
    fi
    if (( created2 )); then
      docker volume rm "$vol2" >/dev/null 2>&1 || echo "AVISO: remova manualmente o volume temporário $vol2" >&2
    fi
    rm -rf -- "$tmp"
  }
  trap cleanup_docker_test EXIT
  if docker volume inspect "$vol1" >/dev/null 2>&1 || docker volume inspect "$vol2" >/dev/null 2>&1; then
    echo 'FALHA: colisão de nome de volume; nenhum volume será alterado.'; return 1
  fi
  if ! docker volume create --label migrador.autoteste=true "$vol1" >/dev/null; then
    echo 'FALHA: não foi possível criar o primeiro volume descartável.'; return 1
  fi
  created1=1
  if ! docker volume create --label migrador.autoteste=true "$vol2" >/dev/null; then
    echo 'FALHA: não foi possível criar o segundo volume descartável.'; return 1
  fi
  created2=1
  expected='MIGRADOR-TESTE-VOLUME-12345'
  if ! docker run --rm --mount "type=volume,source=$vol1,target=/data" \
    alpine:3.20 sh -c 'printf "%s" "MIGRADOR-TESTE-VOLUME-12345" > /data/prova.txt' >/dev/null; then
    echo 'FALHA: escrita em volume descartável. Verifique pull/execução de alpine.'; return 1
  fi
  if ! cid=$(docker run -d --rm --mount "type=volume,source=$vol1,target=/data" alpine:3.20 sleep 120); then
    echo 'FALHA: execução de container descartável de validação.'; return 1
  fi
  if ! docker ps -q --filter "volume=$vol1" | grep -Fxq "$cid"; then
    echo 'FALHA: filtro de volume em uso não retornou o container esperado.'; return 1
  fi
  echo 'OK: detecção de volume ocupado confirmada.'
  if ! docker stop "$cid" >/dev/null; then echo 'FALHA: parada do container de teste.'; return 1; fi
  cid=''
  if ! docker run --rm --mount "type=volume,source=$vol1,target=/source,readonly" \
    alpine:3.20 sh -c 'cd /source && tar -cpf - .' > "$tmp/volume.tar"; then
    echo 'FALHA: exportação de volume.'; return 1
  fi
  if ! tar -tf "$tmp/volume.tar" | grep -Fxq './prova.txt'; then
    echo 'FALHA: arquivo esperado não está no backup do volume.'; return 1
  fi
  if ! docker run --rm -i --mount "type=volume,source=$vol2,target=/destino" \
    alpine:3.20 sh -c 'cd /destino && tar -xpf -' < "$tmp/volume.tar"; then
    echo 'FALHA: restauração em outro volume.'; return 1
  fi
  if ! got=$(docker run --rm --mount "type=volume,source=$vol2,target=/destino,readonly" \
    alpine:3.20 cat /destino/prova.txt); then
    echo 'FALHA: leitura do volume restaurado.'; return 1
  fi
  if [[ "$got" != "$expected" ]]; then
    echo 'FALHA: conteúdo após restauração é diferente do original.'; return 1
  fi
  echo 'OK: Docker exportou e restaurou um volume sem perda dos dados de teste.'
  echo 'O teste não valida automaticamente PostgreSQL, volumes reais em execução ou bind mounts.'
)

autoteste() {
  local opt report code
  printf '\n1) Testar Wi-Fi (somente leitura, cópia temporária em RAM)\n2) Testar Docker (volumes descartáveis)\n3) Testar os dois\n'
  read -r -p 'Opção: ' opt || return 0
  [[ "$opt" =~ ^[123]$ ]] || { echo 'Opção inválida.'; return 0; }
  report="$APPDIR/AUTOTESTE-$(date +%Y%m%d-%H%M%S).log"
  {
    printf 'Autoteste migrador v%s - %s\n' "$VERSION" "$(date -Is)"
    if [[ "$opt" == 1 || "$opt" == 3 ]]; then
      if autoteste_wifi; then
        echo 'RESULTADO WI-FI: APROVADO PARA ARQUIVAMENTO/EXTRACAO'
      else
        code=$?
        if (( code == 2 )); then echo 'RESULTADO WI-FI: NAO TESTADO';
        else echo 'RESULTADO WI-FI: FALHOU'; fi
      fi
    fi
    if [[ "$opt" == 2 || "$opt" == 3 ]]; then
      if autoteste_docker; then
        echo 'RESULTADO DOCKER: APROVADO PARA VOLUME DESCARTAVEL'
      else
        code=$?
        if (( code == 2 )); then echo 'RESULTADO DOCKER: NAO TESTADO';
        else echo 'RESULTADO DOCKER: FALHOU'; fi
      fi
    fi
    echo 'IMPORTANTE: estes testes nao validam os backups de bancos, bind mounts nem a conexao Wi-Fi depois da migracao.'
  } 2>&1 | tee -- "$report"
  printf 'Relatório local: %s\n' "$report"
}

menu() {
  local option
  while true; do
    printf '\n=== Migrador Pop!_OS -> Mint v%s ===\n' "$VERSION"
    printf '1) Adicionar pasta personalizada\n2) Listar pastas personalizadas\n3) Fazer backup e inventario portatil\n4) Verificar integridade (SHA256 + TAR)\n5) Autotestes Wi-Fi e Docker\n0) Sair\n'
    read -r -p 'Escolha: ' option || break
    case "$option" in
      1) add_path;;
      2) if ((${#CUSTOM_PATHS[@]})); then printf '%s\n' "${CUSTOM_PATHS[@]}"; else echo 'Nenhum caminho cadastrado.'; fi;;
      3) backup || echo 'Backup não foi concluído com sucesso. Confira STATUS.md.';;
      4) verify;;
      5) autoteste;;
      0) break;;
      *) echo 'Opção inválida.';;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  menu
fi
