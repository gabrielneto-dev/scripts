#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y playerctl python3
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
cp "$(dirname "$(readlink -f "$0")")/media_focus.py" "$HOME/.local/bin/mint-media-focus"
chmod +x "$HOME/.local/bin/mint-media-focus"
cat > "$HOME/.config/systemd/user/mint-media-focus.service" <<EOF
[Unit]
Description=Intelligent MPRIS media focus
After=graphical-session.target

[Service]
Type=simple
ExecStart=$HOME/.local/bin/mint-media-focus daemon
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now mint-media-focus.service
printf '\nInstalado! Configure os atalhos personalizados do Cinnamon:\n'
printf 'Ctrl + ]  => %s/.local/bin/mint-media-focus play-pause\n' "$HOME"
printf 'Proxima    => %s/.local/bin/mint-media-focus next\n' "$HOME"
printf 'Anterior   => %s/.local/bin/mint-media-focus previous\n' "$HOME"
printf '\nTeste: %s/.local/bin/mint-media-focus status\n' "$HOME"
