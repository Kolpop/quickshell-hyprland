#!/usr/bin/env python3
"""
Quickshell IPC Pipe Server & Hyprland Event Daemon
- Reads commands from qs.pipe and pipes to Quickshell stdout.
- Background thread listens to Hyprland socket2:
  Automatically makes newly opened windows floating if the workspace has vxwm active.
"""

import os
import sys
import ctypes
import threading
import socket
import json
import time

# Принудительно завершаться при падении/перезапуске Quickshell
try:
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(1, 15)  # PR_SET_PDEATHSIG, SIGTERM
except Exception:
    pass

STATE_FILE = "/tmp/vxwm_workspace_state.json"

def send_hypr_cmd(cmd_str):
    try:
        sock_path = f"{os.environ.get('XDG_RUNTIME_DIR', '/run/user/1001')}/hypr/{os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')}/.socket.sock"
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(sock_path)
            s.sendall(cmd_str.encode("utf-8"))
    except Exception:
        pass

def hypr_socket2_listener():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1001")
    sock2_path = os.path.join(runtime, "hypr", sig, ".socket2.sock")

    while True:
        try:
            if not os.path.exists(sock2_path):
                time.sleep(1)
                continue
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(sock2_path)
                f = s.makefile("r", encoding="utf-8", errors="ignore")
                for line in f:
                    line = line.strip()
                    if line.startswith("openwindow>>"):
                        # openwindow>>[address],[workspaceName],[windowClass],[windowTitle]
                        payload = line[len("openwindow>>"):]
                        parts = payload.split(",")
                        if len(parts) >= 2:
                            addr = parts[0]
                            ws_name = parts[1]
                            try:
                                if os.path.exists(STATE_FILE):
                                    with open(STATE_FILE, "r") as sf:
                                        st = json.load(sf)
                                        active_ws = st.get("active_workspaces", {})
                                        is_vxwm = (ws_name in active_ws) or any(v.get("name") == ws_name for v in active_ws.values())
                                        if is_vxwm:
                                            # Автоматически делаем новое окно плавающим
                                            send_hypr_cmd(f'dispatch hl.dsp.window.float({{ action = "on", window = "address:0x{addr}" }})')
                            except Exception:
                                pass
        except Exception:
            time.sleep(1)

# Запуск фонового слушателя событий Hyprland
t = threading.Thread(target=hypr_socket2_listener, daemon=True)
t.start()

pipe_path = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "qs.pipe")

try:
    if os.path.exists(pipe_path):
        os.remove(pipe_path)
    os.mkfifo(pipe_path, 0o600)
except Exception as e:
    sys.stderr.write(f"Error creating FIFO {pipe_path}: {e}\n")
    sys.exit(1)

try:
    sys.stdout.reconfigure(line_buffering=True)
except Exception:
    pass

try:
    fd = os.open(pipe_path, os.O_RDWR)
except Exception as e:
    sys.stderr.write(f"Error opening FIFO: {e}\n")
    sys.exit(1)

buffer = ""

while True:
    try:
        chunk = os.read(fd, 4096)
        if not chunk:
            continue
        buffer += chunk.decode("utf-8", errors="ignore")
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            cmd = line.strip()
            if cmd:
                sys.stdout.write(cmd + "\n")
                sys.stdout.flush()
    except Exception as e:
        sys.stderr.write(f"Pipe read error: {e}\n")
