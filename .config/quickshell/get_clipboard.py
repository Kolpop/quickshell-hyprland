#!/usr/bin/env python3
import sys
import os
import re
import subprocess
import json

THUMB_DIR = '/tmp/qs_clip_thumbs'
os.makedirs(THUMB_DIR, exist_ok=True)

def get_items(limit=70):
    try:
        proc = subprocess.run(
            ['cliphist', '-preview-width', '400', 'list'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        lines = proc.stdout.splitlines()
    except Exception:
        return []

    items = []
    re_binary = re.compile(r"^\[\[ binary data ([\d\.]+\s*\w+)\s+(\w+)(?:\s+(\d+x\d+))? \]\]")

    for line in lines[:limit]:
        if not line or '\t' not in line:
            continue
        parts = line.split('\t', 1)
        item_id = parts[0].strip()
        content = parts[1] if len(parts) > 1 else ""

        bin_match = re_binary.match(content)
        if bin_match:
            size_str = bin_match.group(1)
            fmt = bin_match.group(2)
            dims = bin_match.group(3) or ""
            img_path = os.path.join(THUMB_DIR, f"{item_id}.{fmt}")

            if not os.path.exists(img_path) or os.path.getsize(img_path) == 0:
                try:
                    with open(img_path, 'wb') as f:
                        subprocess.run(['cliphist', 'decode', item_id], stdout=f, check=True, timeout=2)
                except Exception:
                    img_path = ""

            items.append({
                "id": item_id,
                "type": "image",
                "preview": f"Screenshot ({dims or size_str})",
                "imagePath": img_path,
                "size": size_str,
                "dims": dims,
                "rawLine": line
            })
        else:
            # Text item
            clean_text = content.replace('\t', ' ').strip()
            if not clean_text:
                continue
            items.append({
                "id": item_id,
                "type": "text",
                "preview": clean_text,
                "imagePath": "",
                "size": f"{len(clean_text)} chars",
                "dims": "",
                "rawLine": line
            })

    return items

def main():
    if len(sys.argv) > 2 and sys.argv[1] == '--copy':
        item_id = sys.argv[2]
        cmd = f"cliphist decode {item_id} | wl-copy"
        subprocess.run(cmd, shell=True)
        return

    if len(sys.argv) > 2 and sys.argv[1] == '--delete':
        item_id = sys.argv[2]
        try:
            p_list = subprocess.run(['cliphist', 'list'], stdout=subprocess.PIPE, text=True)
            for l in p_list.stdout.splitlines():
                if l.startswith(item_id + '\t'):
                    subprocess.run(['cliphist', 'delete'], input=l + '\n', text=True)
                    break
            # Remove cached thumb if exists
            for ext in ['png', 'jpg', 'jpeg', 'webp']:
                p = os.path.join(THUMB_DIR, f"{item_id}.{ext}")
                if os.path.exists(p):
                    try:
                        os.remove(p)
                    except Exception:
                        pass
        except Exception:
            pass
        return

    if len(sys.argv) > 1 and sys.argv[1] == '--clear':
        subprocess.run(['cliphist', 'wipe'])
        try:
            for f in os.listdir(THUMB_DIR):
                os.remove(os.path.join(THUMB_DIR, f))
        except Exception:
            pass
        return

    items = get_items(70)
    print(json.dumps(items, ensure_ascii=False))

if __name__ == '__main__':
    main()
