#!/usr/bin/env bash
# Instala/atualiza o Vicinae em Linux Mint 22.x / Ubuntu (APT).
# Nao remove o Flare nem modifica outros aplicativos.
set -Eeuo pipefail

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\nERRO: %s\n' "$*" >&2; exit 1; }
trap 'printf "\nFalha na linha %s. Consulte a mensagem acima.\n" "$LINENO" >&2' ERR

if [[ $EUID -eq 0 ]]; then
  fail 'Execute como usuario normal (bash vicinae-install.sh), nao com sudo.'
fi
command -v apt-get >/dev/null || fail 'Este instalador requer Linux Mint/Ubuntu com apt-get.'
command -v sudo >/dev/null || fail 'sudo nao encontrado.'

info 'Verificando dependencias'
missing=()
for package in curl jq ca-certificates; do
  dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed' || missing+=("$package")
done
if ((${#missing[@]} > 0)); then
  printf 'Instalando: %s\n' "${missing[*]}"
  if ! sudo apt-get install -y "${missing[@]}"; then
    fail 'Nao foi possivel instalar dependencias. Se houver trava do APT, aguarde o Gerenciador de Atualizacoes terminar e execute novamente. Nao remova arquivos lock.'
  fi
else
  info 'Dependencias ja instaladas'
fi

info 'Baixando instalador oficial do Vicinae'
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
curl --fail --location --show-error --silent --retry 3 \
  https://vicinae.com/install --output "$tmpdir/vicinae-oficial.sh"
[[ -s "$tmpdir/vicinae-oficial.sh" ]] || fail 'O download do instalador veio vazio.'

info 'Executando instalador oficial (pode solicitar senha sudo)'
bash "$tmpdir/vicinae-oficial.sh"

info 'Verificando instalacao'
if ! command -v vicinae >/dev/null 2>&1; then
  fail 'O instalador terminou, mas o comando vicinae nao foi encontrado no PATH. Abra um novo terminal e teste vicinae version.'
fi
vicinae version

info 'Tentando habilitar o servico de usuario'
if command -v systemctl >/dev/null 2>&1 && systemctl --user cat vicinae.service >/dev/null 2>&1; then
  if systemctl --user enable --now vicinae.service; then
    echo 'Servico de usuario habilitado.'
  else
    echo 'AVISO: Nao foi possivel habilitar o servico. Confira: systemctl --user status vicinae.service'
  fi
else
  echo 'Servico vicinae.service nao encontrado. Inicie manualmente com: vicinae server'
fi

printf '\nInstalacao finalizada.\n'
printf 'Para abrir/ocultar o launcher: vicinae toggle\n'
printf 'Para configurar Alt+Espaco no Cinnamon: Configuracoes do Sistema > Teclado > Atalhos personalizados > comando: vicinae toggle\n'
printf 'Remova uma associacao antiga de Alt+Espaco caso exista.\n'
printf 'Este script nao remove nem altera o Flare.\n'
