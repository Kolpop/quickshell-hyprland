#!/usr/bin/env python3
import os
import sys
import time
import socket
import subprocess
import json
import ctypes

# Принудительно завершаться при падении/перезапуске Quickshell
try:
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(1, 15)  # PR_SET_PDEATHSIG, SIGTERM
except Exception:
    pass

THUMB_DIR = "/tmp/qs_thumbs"
os.makedirs(THUMB_DIR, exist_ok=True)

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

def capture_active():
    try:
        res = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.DEVNULL)
        win = json.loads(res.decode("utf-8"))
        addr = win.get("address", "")
        at = win.get("at", [0, 0])
        size = win.get("size", [0, 0])
        if addr and size[0] > 0 and size[1] > 0:
            capture_window(addr, at, size)
    except Exception:
        pass

def main():
    # Initial capture
    capture_active()

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    sock_path = ""
    candidates = [
        f"/run/user/{os.getuid()}/hypr/{sig}/.socket2.sock",
        f"/tmp/hypr/{sig}/.socket2.sock"
    ]
    for c in candidates:
        if os.path.exists(c):
            sock_path = c
            break

    if not sock_path:
        # Fallback to periodic capture
        while True:
            time.sleep(2)
            capture_active()
        return

    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            buf = ""
            last_capture = 0
            while True:
                data = s.recv(4096)
                if not data:
                    break
                buf += data.decode("utf-8", errors="ignore")
                lines = buf.split("\n")
                buf = lines.pop()
                for line in lines:
                    line = line.strip()
                    if line.startswith("activewindowv2>>") or line.startswith("workspace>>") or line.startswith("focusedmon>>"):
                        now = time.time()
                        if now - last_capture > 0.3:
                            time.sleep(0.08)  # slight delay for compositor render
                            capture_active()
                            last_capture = time.time()
        except Exception:
            time.sleep(1)

if __name__ == "__main__":
    main()
