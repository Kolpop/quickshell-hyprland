#!/usr/bin/env python3
"""
Material You Screenshot Processor
Crops base freeze frame, applies annotations (pen, arrow, rect, blur),
saves to ~/Pictures/Screenshots, and copies to wl-copy clipboard.
"""

import sys
import os
import json
import math
import argparse
import subprocess
from datetime import datetime
from PIL import Image, ImageDraw, ImageFilter

def parse_color(c, default=(255, 180, 169, 255)):
    if not c:
        return default
    if isinstance(c, (list, tuple)):
        return tuple(c)
    c = str(c).strip()
    if c.startswith('#'):
        c = c.lstrip('#')
        if len(c) == 6:
            r = int(c[0:2], 16)
            g = int(c[2:4], 16)
            b = int(c[4:6], 16)
            return (r, g, b, 255)
        elif len(c) == 8:
            r = int(c[0:2], 16)
            g = int(c[2:4], 16)
            b = int(c[4:6], 16)
            a = int(c[6:8], 16)
            return (r, g, b, a)
    return default

def main():
    parser = argparse.ArgumentParser(description="Save and annotate screenshot")
    parser.add_argument("--base", required=True, help="Base frozen image path")
    parser.add_argument("--crop", default="", help="Crop box: x,y,w,h (or empty for full screen)")
    parser.add_argument("--shapes", default="[]", help="JSON string of annotations")
    parser.add_argument("--out", default="", help="Output file path (optional)")
    args = parser.parse_args()

    if not os.path.exists(args.base):
        print(f"Error: base image {args.base} does not exist", file=sys.stderr)
        sys.exit(1)

    try:
        im = Image.open(args.base).convert("RGBA")
    except Exception as e:
        print(f"Error loading base image: {e}", file=sys.stderr)
        sys.exit(1)

    # 1. Parse annotations
    try:
        shapes = json.loads(args.shapes)
    except Exception:
        shapes = []

    # 2. Render shapes on base image
    # We create an overlay RGBA image for drawing with alpha blending
    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for item in shapes:
        stype = item.get("type", "")
        color = parse_color(item.get("color", "#ffb4a9"))
        width = int(item.get("width", 4))

        if stype == "pen":
            pts = item.get("points", [])
            if len(pts) >= 2:
                point_tuples = [(p[0], p[1]) for p in pts]
                draw.line(point_tuples, fill=color, width=width, joint="curve")
                radius = width // 2
                for p in point_tuples:
                    draw.ellipse([p[0] - radius, p[1] - radius, p[0] + radius, p[1] + radius], fill=color)

        elif stype == "arrow":
            x1 = float(item.get("x1", 0))
            y1 = float(item.get("y1", 0))
            x2 = float(item.get("x2", 0))
            y2 = float(item.get("y2", 0))
            draw.line([(x1, y1), (x2, y2)], fill=color, width=width)
            theta = math.atan2(y2 - y1, x2 - x1)
            arrow_len = max(18, width * 4.5)
            lx = x2 - arrow_len * math.cos(theta - math.pi / 6)
            ly = y2 - arrow_len * math.sin(theta - math.pi / 6)
            rx = x2 - arrow_len * math.cos(theta + math.pi / 6)
            ry = y2 - arrow_len * math.sin(theta + math.pi / 6)
            draw.polygon([(x2, y2), (lx, ly), (rx, ry)], fill=color)

        elif stype == "rect":
            x = float(item.get("x", 0))
            y = float(item.get("y", 0))
            w = float(item.get("w", 0))
            h = float(item.get("h", 0))
            x1, y1 = min(x, x + w), min(y, y + h)
            x2, y2 = max(x, x + w), max(y, y + h)
            draw.rounded_rectangle([(x1, y1), (x2, y2)], radius=10, outline=color, width=width)

        elif stype == "blur":
            x = float(item.get("x", 0))
            y = float(item.get("y", 0))
            w = float(item.get("w", 0))
            h = float(item.get("h", 0))
            x1, y1 = max(0, int(min(x, x + w))), max(0, int(min(y, y + h)))
            x2, y2 = min(im.width, int(max(x, x + w))), min(im.height, int(max(y, y + h)))
            if x2 > x1 and y2 > y1:
                # Apply blur directly to base image
                crop_region = im.crop((x1, y1, x2, y2))
                crop_blurred = crop_region.filter(ImageFilter.GaussianBlur(18))
                im.paste(crop_blurred, (x1, y1))

    # Composite overlay on top of base image
    im = Image.alpha_composite(im, overlay)

    # 3. Handle Crop
    if args.crop:
        try:
            parts = [float(v.strip()) for v in args.crop.split(",")]
            if len(parts) == 4:
                cx, cy, cw, ch = parts
                if cw > 10 and ch > 10:
                    x1 = max(0, int(min(cx, cx + cw)))
                    y1 = max(0, int(min(cy, cy + ch)))
                    x2 = min(im.width, int(max(cx, cx + cw)))
                    y2 = min(im.height, int(max(cy, cy + ch)))
                    if x2 > x1 and y2 > y1:
                        im = im.crop((x1, y1, x2, y2))
        except Exception as e:
            print(f"Warning: failed to crop: {e}", file=sys.stderr)

    # 4. Target path
    target_path = args.out
    if not target_path:
        out_dir = os.path.expanduser("~/Pictures/Screenshots")
        os.makedirs(out_dir, exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        target_path = os.path.join(out_dir, f"{timestamp}.png")
    else:
        target_path = os.path.expanduser(target_path)
        os.makedirs(os.path.dirname(os.path.abspath(target_path)), exist_ok=True)

    # Convert to RGB (or keep RGBA) and save PNG
    im.convert("RGB").save(target_path, "PNG", optimize=True)

    # 5. Copy to wl-copy clipboard
    try:
        with open(target_path, "rb") as f:
            subprocess.run(["wl-copy", "-t", "image/png"], input=f.read(), check=False)
    except Exception as e:
        print(f"Warning: wl-copy failed: {e}", file=sys.stderr)

    print(target_path)

if __name__ == "__main__":
    main()
