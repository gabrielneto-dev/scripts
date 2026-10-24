#!/usr/bin/env bash
set -euo pipefail
systemctl --user disable --now spotify-auto-duck.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/spotify-auto-duck.service" "$HOME/.local/bin/spotify-auto-duck"
systemctl --user daemon-reload
echo 'Serviço removido. Configuração preservada em ~/.config/spotify-auto-duck/'
