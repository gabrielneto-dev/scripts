#!/usr/bin/env python3
"""MPRIS focus manager for Linux Mint (playerctl backend)."""
import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time

RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
SOCKET = RUNTIME / 'mint-media-focus.sock'
STATE = RUNTIME / 'mint-media-focus-state.json'
INTERVAL = 0.7
EXPIRY = 300


def pc(*args):
    try:
        result = subprocess.run(['playerctl', *args], capture_output=True, text=True, timeout=3)
        return result.returncode, result.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return 1, ''


def read_players():
    code, listing = pc('--list-all')
    if code != 0 or not listing:
        return {}
    names = list(dict.fromkeys(listing.splitlines()))
    states = {}
    for name in names:
        code, value = pc('--player', name, 'status')
        if code == 0:
            states[name] = value
    return states


class Manager:
    def __init__(self):
        self.players = {}
        self.focus = None
        self.previous = None

    def observe(self):
        statuses = read_players()
        now = time.monotonic()
        for name in list(self.players):
            if name not in statuses:
                del self.players[name]
                if self.focus == name:
                    self.focus = None
        for name, status in statuses.items():
            if name not in self.players:
                self.players[name] = {'status': status, 'last': now if status == 'Playing' else 0, 'paused_at': None if status == 'Playing' else now}
                if status == 'Playing':
                    self.focus = name
            else:
                item = self.players[name]
                if item['status'] != status:
                    item['status'] = status
                    item['last'] = now
                    item['paused_at'] = now if status != 'Playing' else None
                    self.focus = name
        self.reconcile(now)
        self.write_state(now)

    def reconcile(self, now):
        if not self.players:
            self.focus = None
            return
        if self.focus not in self.players:
            self.focus = max(self.players, key=lambda n: (self.players[n]['status'] == 'Playing', self.players[n]['last']))
        item = self.players[self.focus]
        if item['status'] != 'Playing' and item['paused_at'] is not None and now - item['paused_at'] >= EXPIRY:
            candidates = [n for n, p in self.players.items() if p['status'] == 'Playing']
            if candidates:
                self.focus = max(candidates, key=lambda n: self.players[n]['last'])

    def command(self, command):
        if command == 'status':
            return self.snapshot(time.monotonic())
        if command not in ('play-pause', 'next', 'previous'):
            return {'error': 'Comando inválido'}
        self.observe()
        if not self.focus:
            return {'error': 'Nenhum player MPRIS encontrado'}
        target = self.focus
        code, output = pc('--player', target, command)
        if code:
            return {'error': f'Falha ao controlar {target}: {output}'}
        # Hold focus for the selected player even if another status arrives asynchronously.
        now = time.monotonic()
        item = self.players.get(target)
        if item:
            item['last'] = now
            if command == 'play-pause':
                item['status'] = 'Paused' if item['status'] == 'Playing' else 'Playing'
                item['paused_at'] = now if item['status'] != 'Playing' else None
            elif item['status'] != 'Playing':
                item['paused_at'] = now
            self.focus = target
        self.write_state(now)
        return {'ok': True, 'target': target, 'command': command}

    def snapshot(self, now):
        return {'focus': self.focus, 'timeout_seconds': EXPIRY, 'players': {
            n: {'status': p['status'], 'seconds_until_fallback': max(0, round(EXPIRY - (now - p['paused_at']))) if p['paused_at'] is not None and n == self.focus else None}
            for n, p in self.players.items()
        }}

    def write_state(self, now):
        temp = STATE.with_suffix('.tmp')
        try:
            temp.write_text(json.dumps(self.snapshot(now), ensure_ascii=False))
            temp.replace(STATE)
        except OSError:
            pass


def serve():
    RUNTIME.mkdir(parents=True, exist_ok=True)
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.bind(str(SOCKET))
    except OSError:
        # Avoid deleting a live daemon socket.
        try:
            with socket.socket(socket.AF_UNIX) as probe:
                probe.settimeout(0.5)
                probe.connect(str(SOCKET))
            sys.exit('Gerenciador já está ativo')
        except OSError:
            SOCKET.unlink(missing_ok=True)
            sock.bind(str(SOCKET))
    os.chmod(SOCKET, 0o600)
    sock.listen(5)
    sock.settimeout(INTERVAL)
    manager = Manager()
    try:
        while True:
            manager.observe()
            try:
                client, _ = sock.accept()
            except socket.timeout:
                continue
            with client:
                client.settimeout(3)
                try:
                    cmd = client.recv(1024).decode().strip()
                    client.sendall((json.dumps(manager.command(cmd), ensure_ascii=False) + '\n').encode())
                except (OSError, ValueError):
                    pass
    finally:
        sock.close()
        SOCKET.unlink(missing_ok=True)
        STATE.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['daemon', 'play-pause', 'next', 'previous', 'status'])
    args = parser.parse_args()
    if args.action == 'daemon':
        serve()
        return
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(5)
            sock.connect(str(SOCKET))
            sock.sendall(args.action.encode())
            chunks = []
            while True:
                data = sock.recv(65536)
                if not data:
                    break
                chunks.append(data)
            result = json.loads(b''.join(chunks))
    except (OSError, ValueError) as error:
        sys.exit(f'Serviço indisponível: {error}. Confira: systemctl --user status mint-media-focus')
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if 'error' in result:
        sys.exit(1)


if __name__ == '__main__':
    main()
