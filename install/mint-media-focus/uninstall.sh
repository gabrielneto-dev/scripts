#!/usr/bin/env bash
set -euo pipefail
systemctl --user disable --now mint-media-focus.service || true
rm -f "$HOME/.config/systemd/user/mint-media-focus.service" "$HOME/.local/bin/mint-media-focus"
systemctl --user daemon-reload
printf 'Serviço removido. Remova manualmente os atalhos personalizados no Cinnamon.\n'
