#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " Cloudflared - Criar Tunnel Permanente"
echo "=========================================="
echo

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script precisa ser executado com sudo."
  echo "Exemplo:"
  echo "  sudo ./install-cloudflared-tunnel.sh"
  exit 1
fi

read -r -p "Nome da aplicação (ex: n8n): " APP_NAME
read -r -s -p "Token do Cloudflare Tunnel: " TUNNEL_TOKEN
echo

if [[ -z "${APP_NAME}" ]]; then
  echo "Erro: o nome da aplicação não pode ficar vazio."
  exit 1
fi

if [[ -z "${TUNNEL_TOKEN}" ]]; then
  echo "Erro: o token não pode ficar vazio."
  exit 1
fi

# Normaliza o nome para uso seguro no nome do serviço systemd
SERVICE_SLUG="$(echo "${APP_NAME}" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9._-]/-/g' \
  | sed 's/--*/-/g' \
  | sed 's/^-//' \
  | sed 's/-$//')"

if [[ -z "${SERVICE_SLUG}" ]]; then
  echo "Erro: não foi possível gerar um nome de serviço válido."
  exit 1
fi

CLOUDFLARED_BIN="$(command -v cloudflared || true)"

if [[ -z "${CLOUDFLARED_BIN}" ]]; then
  echo "Erro: cloudflared não foi encontrado no PATH."
  echo "Instale o cloudflared antes de executar este script."
  exit 1
fi

SERVICE_NAME="cloudflared-${SERVICE_SLUG}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ -f "${SERVICE_FILE}" ]]; then
  echo
  echo "Já existe um serviço chamado:"
  echo "  ${SERVICE_NAME}.service"
  echo
  read -r -p "Deseja substituir esse serviço? [s/N]: " CONFIRM
  case "${CONFIRM}" in
    s|S|sim|SIM|Sim)
      systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
      ;;
    *)
      echo "Operação cancelada."
      exit 0
      ;;
  esac
fi

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Cloudflare Tunnel - ${APP_NAME}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${CLOUDFLARED_BIN} tunnel run --token ${TUNNEL_TOKEN}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 600 "${SERVICE_FILE}"

echo
echo "Recarregando systemd..."
systemctl daemon-reload

echo "Habilitando ${SERVICE_NAME}.service no boot..."
systemctl enable "${SERVICE_NAME}.service"

echo "Iniciando o tunnel..."
systemctl restart "${SERVICE_NAME}.service"

sleep 2

echo
echo "=========================================="
echo " Serviço criado"
echo "=========================================="
echo "Aplicação: ${APP_NAME}"
echo "Serviço:   ${SERVICE_NAME}.service"
echo "Arquivo:   ${SERVICE_FILE}"
echo

if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
  echo "Status: ATIVO"
else
  echo "Status: FALHOU AO INICIAR"
  echo
  echo "Logs:"
  journalctl -u "${SERVICE_NAME}.service" -n 30 --no-pager
  exit 1
fi

echo
echo "Comandos úteis:"
echo
echo "  Status:"
echo "    sudo systemctl status ${SERVICE_NAME}"
echo
echo "  Logs em tempo real:"
echo "    sudo journalctl -u ${SERVICE_NAME} -f"
echo
echo "  Reiniciar:"
echo "    sudo systemctl restart ${SERVICE_NAME}"
echo
echo "  Parar:"
echo "    sudo systemctl stop ${SERVICE_NAME}"
echo
echo "  Iniciar:"
echo "    sudo systemctl start ${SERVICE_NAME}"
echo
