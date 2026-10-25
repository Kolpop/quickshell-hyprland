#!/usr/bin/env python3
"""JSON helper for the cliphist-backed Quickshell clipboard UI."""

import json
import os
import re
import subprocess
import sys

# Keep the existing path because QML components reference it directly.
THUMB_DIR = os.environ.get("QS_CLIP_THUMB_DIR", "/tmp/qs_clip_thumbs")
os.makedirs(THUMB_DIR, mode=0o700, exist_ok=True)
BINARY_PATTERN = re.compile(
    r"^\[\[ binary data ([\d.]+\s*\w+)\s+(\w+)(?:\s+(\d+x\d+))? \]\]"
)
VALID_IMAGE_FORMATS = {"png", "jpg", "jpeg", "webp"}


def run(args, **kwargs):
    """Run a helper command with a timeout and consistent error reporting."""
    return subprocess.run(args, timeout=5, **kwargs)


def get_items(limit=70):
    try:
        proc = run(
            ["cliphist", "-preview-width", "400", "list"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"clipboard: unable to read cliphist: {exc}", file=sys.stderr)
        return []

    items = []
    for line in proc.stdout.splitlines()[:max(0, limit)]:
        if not line or "\t" not in line:
            continue
        item_id, content = line.split("\t", 1)
        item_id = item_id.strip()
        if not item_id.isdecimal():
            continue

        match = BINARY_PATTERN.match(content)
        if match:
            size_str, image_format, dimensions = match.groups()
            image_format = image_format.lower()
            image_path = ""
            if image_format in VALID_IMAGE_FORMATS:
                candidate = os.path.join(THUMB_DIR, f"{item_id}.{image_format}")
                try:
                    if not os.path.isfile(candidate) or os.path.getsize(candidate) == 0:
                        with open(candidate, "wb") as output:
                            run(
                                ["cliphist", "decode", item_id], stdout=output,
                                stderr=subprocess.PIPE, check=True,
                            )
                    image_path = candidate
                except (OSError, subprocess.SubprocessError) as exc:
                    print(f"clipboard: failed to decode item {item_id}: {exc}", file=sys.stderr)
            items.append({
                "id": item_id, "type": "image",
                "preview": f"Screenshot ({dimensions or size_str})",
                "imagePath": image_path, "size": size_str,
                "dims": dimensions or "", "rawLine": line,
            })
        else:
            text_preview = content.replace("\t", " ").strip()
            if text_preview:
                items.append({
                    "id": item_id, "type": "text", "preview": text_preview,
                    "imagePath": "", "size": f"{len(text_preview)} chars",
                    "dims": "", "rawLine": line,
                })
    return items


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if len(args) > 1 and args[0] in {"--copy", "--delete"}:
        item_id = args[1]
        if not item_id.isdecimal():
            print("clipboard: invalid item id", file=sys.stderr)
            return 2
        try:
            if args[0] == "--copy":
                decoded = run(
                    ["cliphist", "decode", item_id], stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, check=True,
                )
                run(["wl-copy"], input=decoded.stdout, check=True)
            else:
                listing = run(
                    ["cliphist", "list"], stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, text=True, check=True,
                )
                entry = next(
                    (line for line in listing.stdout.splitlines()
                     if line.startswith(item_id + "\t")), None
                )
                if entry:
                    run(
                        ["cliphist", "delete"], input=entry + "\n",
                        text=True, check=True,
                    )
                for ext in VALID_IMAGE_FORMATS:
                    try:
                        os.remove(os.path.join(THUMB_DIR, f"{item_id}.{ext}"))
                    except FileNotFoundError:
                        pass
        except (OSError, subprocess.SubprocessError) as exc:
            print(f"clipboard: {args[0][2:]} failed: {exc}", file=sys.stderr)
            return 1
        return 0

    if args and args[0] == "--clear":
        try:
            run(["cliphist", "wipe"], check=True)
            for name in os.listdir(THUMB_DIR):
                path = os.path.join(THUMB_DIR, name)
                if os.path.isfile(path):
                    os.remove(path)
        except (OSError, subprocess.SubprocessError) as exc:
            print(f"clipboard: clear failed: {exc}", file=sys.stderr)
            return 1
        return 0

    print(json.dumps(get_items(70), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
