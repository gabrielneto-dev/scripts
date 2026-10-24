#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo apt-get update
sudo apt-get install -y python3 pulseaudio-utils
install -Dm755 "$SCRIPT_DIR/spotify_duck.py" "$HOME/.local/bin/spotify-auto-duck"
mkdir -p "$HOME/.config/systemd/user" "$HOME/.config/spotify-auto-duck"
if [[ ! -f "$HOME/.config/spotify-auto-duck/config.json" ]]; then
  cat > "$HOME/.config/spotify-auto-duck/config.json" <<'EOF'
{
  "duck_volume": 30,
  "release_delay_seconds": 1.0,
  "poll_seconds": 0.5,
  "spotify_match": ["spotify"],
  "ignore_apps": ["spotify", "spotify-auto-duck"]
}
EOF
fi
cat > "$HOME/.config/systemd/user/spotify-auto-duck.service" <<EOF
[Unit]
Description=Spotify Auto Duck - redução automática de volume
After=pipewire-pulse.service pulseaudio.service
[Service]
Type=simple
ExecStart=$HOME/.local/bin/spotify-auto-duck run
Restart=on-failure
RestartSec=3
[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now spotify-auto-duck.service
systemctl --user restart spotify-auto-duck.service
echo 'Instalado. Use: spotify-auto-duck status'
