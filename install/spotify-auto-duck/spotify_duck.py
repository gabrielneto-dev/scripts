#!/usr/bin/env python3
"""Spotify Auto Duck - duck Spotify sink inputs when another app plays.
Uses pactl's PulseAudio-compatible interface (including pipewire-pulse).
"""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

CONFIG = Path.home() / '.config/spotify-auto-duck/config.json'
STATE = Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp')) / f'spotify-auto-duck-{os.getuid()}.json'
DEFAULTS = {'duck_volume': 30, 'release_delay_seconds': 1.0, 'poll_seconds': 0.5,
            'spotify_match': ['spotify'], 'ignore_apps': ['spotify', 'spotify-auto-duck']}
STOP = False

def pactl(*args):
    return subprocess.run(['pactl', *map(str,args)], text=True, capture_output=True, check=True, timeout=5).stdout

def load_config():
    try:
        user = json.loads(CONFIG.read_text())
        cfg = dict(DEFAULTS, **user)
    except (FileNotFoundError, ValueError):
        cfg = dict(DEFAULTS)
    cfg['duck_volume'] = max(0, min(100, int(cfg['duck_volume'])))
    cfg['release_delay_seconds'] = max(0, float(cfg['release_delay_seconds']))
    cfg['poll_seconds'] = max(0.2, float(cfg['poll_seconds']))
    return cfg

def save_config(cfg):
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    CONFIG.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + '\n')

def streams():
    result = json.loads(pactl('--format=json', 'list', 'sink-inputs'))
    return list(result.values()) if isinstance(result, dict) else result

def stream_name(s):
    p = s.get('properties', {})
    return ' '.join(str(p.get(k, '')) for k in ('application.name','application.process.binary','media.name','node.name')).lower()

def is_spotify(s,cfg):
    p = s.get('properties', {})
    identity = ' '.join(str(p.get(k,'')) for k in ('application.name','application.process.binary','application.id')).lower()
    return any(x.lower() in identity for x in cfg['spotify_match'])

def is_other_active(s,cfg):
    if is_spotify(s,cfg) or s.get('mute',False) or s.get('corked',False):
        return False
    if any(x.lower() in stream_name(s) for x in cfg['ignore_apps']):
        return False
    vol = s.get('volume', {})
    return any(v.get('value',0)>0 for v in vol.values()) if isinstance(vol, dict) else True

def raw_vol(s):
    vol=s.get('volume',{})
    return [int(x['value']) for x in vol.values() if isinstance(x,dict) and 'value' in x]

def set_raw(index,vals):
    if vals: pactl('set-sink-input-volume',index,*vals)

def write_state(original):
    STATE.write_text(json.dumps({str(k): v for k,v in original.items()}))

def restore_saved():
    if not STATE.exists(): return
    try:
        previous=json.loads(STATE.read_text())
        current={int(s['index']):s for s in streams()}
        for key, volume in previous.items():
            idx=int(key)
            if idx in current and is_spotify(current[idx], load_config()):
                try:set_raw(idx,volume)
                except (subprocess.SubprocessError,OSError):pass
    except (ValueError,subprocess.SubprocessError,OSError):pass
    finally: STATE.unlink(missing_ok=True)

def stop(*_):
    global STOP
    STOP=True

def run_service():
    signal.signal(signal.SIGTERM,stop)
    signal.signal(signal.SIGINT,stop)
    # Restore leftover volumes from a previous abnormal termination.
    restore_saved()
    original={}
    last_other=time.monotonic()
    ducking=False
    print('Spotify Auto Duck iniciado',flush=True)
    try:
        while not STOP:
            cfg=load_config()
            try: current=streams()
            except (OSError,subprocess.SubprocessError,ValueError) as e:
                print(f'Aguardando servidor de áudio: {e}',file=sys.stderr,flush=True)
                time.sleep(2)
                continue
            spotify={int(s['index']):s for s in current if is_spotify(s,cfg)}
            other=[s for s in current if is_other_active(s,cfg)]
            if other:
                last_other=time.monotonic()
            desired=bool(other) or (ducking and time.monotonic()-last_other < cfg['release_delay_seconds'])
            for idx in list(original):
                if idx not in spotify: original.pop(idx)
            if desired:
                for idx,s in spotify.items():
                    if idx not in original: original[idx]=raw_vol(s)
                    if idx in original:
                        cur=raw_vol(s)
                        target=[round(65536*cfg['duck_volume']/100)]*len(cur)
                        if cur and cur!=target:
                            try:set_raw(idx,target)
                            except subprocess.SubprocessError as e:print(f'Erro ao reduzir {idx}: {e}',file=sys.stderr)
                ducking=True
                write_state(original)
            else:
                for idx,vals in list(original.items()):
                    try:set_raw(idx,vals)
                    except subprocess.SubprocessError:pass
                original.clear()
                STATE.unlink(missing_ok=True)
                ducking=False
            time.sleep(cfg['poll_seconds'])
    finally:
        for idx, vals in original.items():
            try:set_raw(idx,vals)
            except (subprocess.SubprocessError,OSError):pass
        STATE.unlink(missing_ok=True)

def main():
    ap=argparse.ArgumentParser(description='Spotify Auto Duck: volume automático do Spotify')
    sub=ap.add_subparsers(dest='action',required=True)
    sub.add_parser('run');sub.add_parser('status');sub.add_parser('list')
    s=sub.add_parser('set');s.add_argument('option',choices=['volume','delay']);s.add_argument('value',type=float)
    args=ap.parse_args()
    cfg=load_config()
    if args.action=='run':run_service()
    elif args.action=='set':
        if args.option=='volume':
            if not 0<=args.value<=100:ap.error('Volume deve estar entre 0 e 100')
            cfg['duck_volume']=int(args.value)
        else:
            if not 0<=args.value<=60:ap.error('Delay deve estar entre 0 e 60 segundos')
            cfg['release_delay_seconds']=args.value
        save_config(cfg)
        print('Configuração salva:',json.dumps(cfg,ensure_ascii=False,indent=2))
    elif args.action in ('status','list'):
        try: current=streams()
        except Exception as e: sys.exit(f'Falha no pactl: {e}')
        if args.action=='list':
            for s in current:
                print(f"#{s['index']} | {stream_name(s)} | corked={s.get('corked')} | mute={s.get('mute')} | volume={raw_vol(s)}")
        else:
            print('Configuração:',json.dumps(cfg,ensure_ascii=False))
            print('Spotify:',[(s['index'],raw_vol(s)) for s in current if is_spotify(s,cfg)])
            print('Outros ativos (pela sinalização de fluxo):',[(s['index'],stream_name(s)) for s in current if is_other_active(s,cfg)])
            print('Volume original salvo:',STATE.read_text() if STATE.exists() else 'nenhum')
if __name__=='__main__': main()
