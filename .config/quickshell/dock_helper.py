#!/usr/bin/env python3
import subprocess
import json
import os
import sys

import shutil

SEARCH_PATHS = [
    '/usr/share/pixmaps',
    '/usr/share/icons/hicolor/256x256/apps',
    '/usr/share/icons/hicolor/512x512/apps',
    '/usr/share/icons/hicolor/scalable/apps',
    '/usr/share/icons/hicolor/128x128/apps',
    '/usr/share/icons/hicolor/64x64/apps',
    '/usr/share/icons/hicolor/48x48/apps',
    '/usr/share/icons/breeze/apps/48',
    '/usr/share/icons/Adwaita/scalable/apps',
    os.path.expanduser('~/.local/share/icons/hicolor/scalable/apps'),
    os.path.expanduser('~/.local/share/icons'),
    '/usr/share/icons/Papirus/64x64/apps',
    '/usr/share/icons/Papirus/scalable/apps'
]
EXTENSIONS = ['.svg', '.png', '.xpm']
ICON_CACHE = {}

def resolve_icon(app_id):
    if not app_id:
        return ''
    if app_id in ICON_CACHE:
        return ICON_CACHE[app_id]
    if os.path.isabs(app_id) and os.path.exists(app_id):
        ICON_CACHE[app_id] = app_id
        return app_id

    low = app_id.lower()
    variants = []
    if 'telegram' in low:
        variants.extend(['org.telegram.desktop', 'telegram-desktop', 'telegram'])
    elif 'vesktop' in low or 'discord' in low:
        variants.extend(['vesktop-bin', 'vesktop', 'discord', 'com.discordapp.Discord'])
    elif 'firefox' in low:
        variants.extend(['firefox-bin', 'firefox', 'org.mozilla.firefox'])
    elif 'kitty' in low:
        variants.extend(['kitty', 'kitty-terminal', 'utilities-terminal'])
    elif 'alacritty' in low:
        variants.extend(['Alacritty', 'alacritty', 'utilities-terminal'])
    elif 'thunar' in low or 'dolphin' in low or 'files' in low:
        variants.extend(['org.kde.dolphin', 'system-file-manager', 'dolphin', 'org.xfce.thunar', 'thunar'])
    elif 'code' in low or 'vscode' in low:
        variants.extend(['vscode', 'code', 'com.visualstudio.code'])
    elif 'steam' in low:
        variants.extend(['steam', 'com.valvesoftware.Steam'])
    elif 'antigravity' in low:
        variants.extend(['antigravity', 'antigravity-ide', 'google-antigravity', 'utilities-terminal'])

    variants.extend([app_id, low])
    if '.' in app_id:
        variants.append(app_id.split('.')[-1])
        variants.append(app_id.split('.')[-1].lower())

    for name in variants:
        for p in SEARCH_PATHS:
            for ext in EXTENSIONS:
                f = os.path.join(p, name + ext)
                if os.path.exists(f):
                    ICON_CACHE[app_id] = f
                    return f
            f = os.path.join(p, name)
            if os.path.exists(f):
                ICON_CACHE[app_id] = f
                return f

    ICON_CACHE[app_id] = ''
    return ''

def format_app_name(app_id):
    low = app_id.lower()
    if 'telegram' in low:
        return 'Telegram'
    if 'vesktop' in low or 'discord' in low:
        return 'Discord'
    if 'firefox' in low:
        return 'Firefox'
    if 'kitty' in low:
        return 'Kitty'
    if 'alacritty' in low:
        return 'Alacritty'
    if 'thunar' in low or 'dolphin' in low or 'files' in low:
        return 'Файлы'
    if 'steam' in low:
        return 'Steam'
    if 'code' in low or 'vscode' in low:
        return 'VS Code'
    if 'antigravity' in low:
        return 'Antigravity'
    if '.' in app_id:
        return app_id.split('.')[-1].capitalize()
    return app_id.capitalize()

def get_exec_command(app_id):
    low = app_id.lower()
    if 'firefox' in low:
        return 'firefox'
    if 'telegram' in low:
        return 'telegram-desktop'
    if 'vesktop' in low:
        return 'vesktop'
    if 'discord' in low:
        return 'discord'
    if 'thunar' in low or 'dolphin' in low:
        return 'dolphin' if not shutil.which('thunar') else 'thunar'
    if 'kitty' in low:
        return 'kitty'
    if 'alacritty' in low:
        return 'alacritty'
    return app_id

def main():
    pinned_input = []
    if len(sys.argv) > 1:
        raw = " ".join(sys.argv[1:])
        try:
            pinned_input = json.loads(raw)
        except Exception:
            pinned_input = [s.strip() for s in raw.split(",") if s.strip()]

    # Default pinned if none provided
    if not pinned_input:
        pinned_input = ["firefox", "kitty", "thunar", "vesktop", "telegram"]

    # 1. Fetch Hyprland activewindow
    focused_addr = ""
    focused_class = ""
    try:
        act_raw = subprocess.check_output(['hyprctl', 'activewindow', '-j'], stderr=subprocess.DEVNULL)
        act = json.loads(act_raw.decode('utf-8'))
        focused_addr = act.get('address', '')
        focused_class = act.get('class', '').lower()
    except Exception:
        pass

    # 2. Fetch Hyprland clients
    clients = []
    try:
        cli_raw = subprocess.check_output(['hyprctl', 'clients', '-j'], stderr=subprocess.DEVNULL)
        clients = json.loads(cli_raw.decode('utf-8'))
    except Exception:
        pass

    # Group running windows by normalized app_id
    running_apps = {} # norm_id -> { "class": cls, "windows": [ {address, title} ] }
    for c in clients:
        if not c.get('mapped') or c.get('hidden'):
            continue
        cls = c.get('class', '')
        init_cls = c.get('initialClass', '')
        addr = c.get('address', '')
        title = c.get('title', '') or cls
        app_key = (cls or init_cls).lower()
        if not app_key:
            continue

        # Normalization
        norm = app_key
        if 'firefox' in app_key:
            norm = 'firefox'
        elif 'telegram' in app_key:
            norm = 'telegram'
        elif 'vesktop' in app_key or 'discord' in app_key:
            norm = 'vesktop'
        elif 'kitty' in app_key:
            norm = 'kitty'
        elif 'alacritty' in app_key:
            norm = 'alacritty'
        elif 'thunar' in app_key:
            norm = 'thunar'

        if norm not in running_apps:
            running_apps[norm] = {
                'rawId': cls or init_cls,
                'windows': []
            }
        running_apps[norm]['windows'].append({
            'address': addr,
            'title': title
        })

    # Build final dock item list:
    dock_items = []
    processed_norms = set()

    # 1. Add pinned apps first
    for p in pinned_input:
        p_norm = p.lower()
        if 'firefox' in p_norm: p_norm = 'firefox'
        elif 'telegram' in p_norm: p_norm = 'telegram'
        elif 'vesktop' in p_norm or 'discord' in p_norm: p_norm = 'vesktop'
        elif 'kitty' in p_norm: p_norm = 'kitty'
        elif 'alacritty' in p_norm: p_norm = 'alacritty'
        elif 'thunar' in p_norm: p_norm = 'thunar'

        processed_norms.add(p_norm)
        is_running = p_norm in running_apps
        windows = running_apps[p_norm]['windows'] if is_running else []
        is_focused = any(w['address'] == focused_addr for w in windows) or (focused_class and p_norm in focused_class)
        icon = resolve_icon(p)
        if not icon and is_running:
            icon = resolve_icon(running_apps[p_norm]['rawId'])

        dock_items.append({
            'appId': p,
            'name': format_app_name(p),
            'icon': icon,
            'exec': get_exec_command(p),
            'pinned': True,
            'running': is_running,
            'focused': is_focused,
            'count': len(windows),
            'windows': windows
        })

    # 2. Add running unpinned apps
    for norm, data in running_apps.items():
        if norm in processed_norms:
            continue
        windows = data['windows']
        is_focused = any(w['address'] == focused_addr for w in windows) or (focused_class and norm in focused_class)
        raw_id = data['rawId']
        icon = resolve_icon(raw_id)
        dock_items.append({
            'appId': raw_id,
            'name': format_app_name(raw_id),
            'icon': icon,
            'exec': get_exec_command(raw_id),
            'pinned': False,
            'running': True,
            'focused': is_focused,
            'count': len(windows),
            'windows': windows
        })

    print(json.dumps(dock_items))

if __name__ == '__main__':
    main()
