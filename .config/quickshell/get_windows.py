#!/usr/bin/env python3
import subprocess
import json
import os
import sys

THUMB_DIR = '/tmp/qs_thumbs'
os.makedirs(THUMB_DIR, exist_ok=True)

SEARCH_PATHS = [
    '/usr/share/pixmaps',
    '/usr/share/icons/Papirus/48x48/apps',
    '/usr/share/icons/Papirus/scalable/apps',
    '/usr/share/icons/hicolor/scalable/apps',
    '/usr/share/icons/hicolor/128x128/apps',
    '/usr/share/icons/hicolor/64x64/apps',
    '/usr/share/icons/hicolor/48x48/apps',
    '/usr/share/icons/breeze/apps/48',
    '/usr/share/icons/Adwaita/scalable/apps',
    '/usr/share/icons/gnome/48x48/apps'
]
EXTENSIONS = ['.svg', '.png', '.xpm']
ICON_CACHE = {}

def resolve_icon(icon_name):
    if not icon_name:
        return ''
    if icon_name in ICON_CACHE:
        return ICON_CACHE[icon_name]
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        ICON_CACHE[icon_name] = icon_name
        return icon_name
    
    variants = [icon_name, icon_name.lower()]
    if '.' in icon_name:
        variants.append(icon_name.split('.')[-1])
        variants.append(icon_name.split('.')[-1].lower())
    if 'telegram' in icon_name.lower():
        variants.extend(['org.telegram.desktop', 'telegram', 'telegram-desktop'])
    if 'vesktop' in icon_name.lower() or 'discord' in icon_name.lower():
        variants.extend(['vesktop', 'discord'])
    if 'code' in icon_name.lower() or 'vscode' in icon_name.lower():
        variants.extend(['vscode', 'code'])

    for name in variants:
        for p in SEARCH_PATHS:
            for ext in EXTENSIONS:
                f = os.path.join(p, name + ext)
                if os.path.exists(f):
                    ICON_CACHE[icon_name] = f
                    return f
            f = os.path.join(p, name)
            if os.path.exists(f):
                ICON_CACHE[icon_name] = f
                return f
    ICON_CACHE[icon_name] = ''
    return ''

def format_app_name(cls, initial_class):
    c = cls or initial_class or 'App'
    low = c.lower()
    if 'telegram' in low:
        return 'Telegram'
    if 'vesktop' in low or 'discord' in low:
        return 'Discord'
    if low == 'kitty':
        return 'Kitty'
    if low == 'firefox':
        return 'Firefox'
    if 'antigravity' in low:
        return 'Antigravity'
    if 'alacritty' in low:
        return 'Alacritty'
    if 'steam' in low:
        return 'Steam'
    if '.' in c:
        return c.split('.')[-1].capitalize()
    return c.capitalize()

def capture_window(addr, at, size):
    try:
        x, y = at
        w, h = size
        if w < 50 or h < 50:
            return
        geom = f"{x},{y} {w}x{h}"
        out_path = os.path.join(THUMB_DIR, f"{addr}.jpg")
        subprocess.run(["grim", "-g", geom, "-t", "jpeg", "-q", "60", out_path],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    try:
        mons_raw = subprocess.check_output(['hyprctl', 'monitors', '-j'], stderr=subprocess.DEVNULL)
        mons = json.loads(mons_raw.decode('utf-8'))
        active_ws_ids = {m.get('activeWorkspace', {}).get('id') for m in mons}

        res = subprocess.check_output(['hyprctl', 'clients', '-j'], stderr=subprocess.DEVNULL)
        clients = json.loads(res.decode('utf-8'))
    except Exception:
        print(json.dumps([]))
        return

    out = []
    for c in clients:
        if not c.get('mapped') or c.get('hidden') or not c.get('class'):
            continue
        cls = c.get('class', '')
        init_cls = c.get('initialClass', '')
        title = c.get('title', '') or cls
        addr = c.get('address', '')
        ws_id = c.get('workspace', {}).get('id', 1)
        at = c.get('at', [0, 0])
        size = c.get('size', [0, 0])

        if ws_id in active_ws_ids and size[0] > 50 and size[1] > 50:
            capture_window(addr, at, size)

        thumb_file = os.path.join(THUMB_DIR, f"{addr}.jpg")
        thumb_path = thumb_file if os.path.exists(thumb_file) and os.path.getsize(thumb_file) > 1000 else ""

        icon = resolve_icon(cls)
        if not icon and init_cls:
            icon = resolve_icon(init_cls)

        out.append({
            'address': addr,
            'class': cls,
            'appName': format_app_name(cls, init_cls),
            'title': title,
            'workspaceId': ws_id,
            'workspaceName': str(c.get('workspace', {}).get('name', str(ws_id))),
            'focusHistoryID': c.get('focusHistoryID', 999),
            'floating': bool(c.get('floating', False)),
            'fullscreen': bool(c.get('fullscreen', 0) != 0),
            'pinned': bool(c.get('pinned', False)),
            'iconPath': icon,
            'thumbPath': thumb_path
        })

    out.sort(key=lambda x: x['focusHistoryID'])
    print(json.dumps(out))

if __name__ == '__main__':
    main()
