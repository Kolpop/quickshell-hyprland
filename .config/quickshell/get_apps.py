#!/usr/bin/env python3
import os
import glob
import json
import sys

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

def get_category(cat_str):
    if not cat_str:
        return 'Other'
    c = cat_str.lower()
    if any(k in c for k in ['network', 'webbrowser', 'email', 'chat', 'feed']):
        return 'Internet'
    if any(k in c for k in ['development', 'ide', 'debugger']):
        return 'Development'
    if any(k in c for k in ['audiovideo', 'audio', 'video', 'player', 'music']):
        return 'Media'
    if any(k in c for k in ['game']):
        return 'Games'
    if any(k in c for k in ['system', 'settings', 'monitor']):
        return 'System'
    if any(k in c for k in ['utility', 'texteditor', 'terminalemulator', 'terminal', 'filemanager', 'core']):
        return 'Utilities'
    return 'Other'

def main():
    dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]
    apps = []
    seen = set()

    for d in dirs:
        if not os.path.isdir(d):
            continue
        for f in glob.glob(d + '/**/*.desktop', recursive=True):
            try:
                with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
                    lines = fp.readlines()
                app = {}
                in_entry = False
                for line in lines:
                    line = line.strip()
                    if line == '[Desktop Entry]':
                        in_entry = True
                        continue
                    elif line.startswith('[') and line.endswith(']'):
                        in_entry = False
                        continue
                    if in_entry and '=' in line:
                        k, v = line.split('=', 1)
                        k = k.strip()
                        v = v.strip()
                        if k == 'Name' and 'name' not in app:
                            app['name'] = v
                        elif k == 'Exec' and 'exec' not in app:
                            # Strip file placeholders (%f, %u, etc.)
                            exec_clean = ' '.join([p for p in v.split() if not p.startswith('%')])
                            app['exec'] = exec_clean
                        elif k == 'Icon' and 'icon' not in app:
                            app['icon'] = v
                        elif k == 'Comment' and 'comment' not in app:
                            app['comment'] = v
                        elif k == 'GenericName' and 'genericName' not in app:
                            app['genericName'] = v
                        elif k == 'NoDisplay' and v.lower() == 'true':
                            app['nodisplay'] = True
                        elif k == 'Categories' and 'categories' not in app:
                            app['categories'] = v
                if app.get('nodisplay') or not app.get('name') or not app.get('exec'):
                    continue
                if app['name'] in seen:
                    continue
                seen.add(app['name'])
                app['iconPath'] = resolve_icon(app.get('icon', ''))
                app['category'] = get_category(app.get('categories', ''))
                app['description'] = app.get('comment') or app.get('genericName') or app.get('category', 'Application')
                apps.append(app)
            except Exception:
                pass

    apps.sort(key=lambda x: x['name'].lower())
    print(json.dumps(apps))

if __name__ == '__main__':
    main()
