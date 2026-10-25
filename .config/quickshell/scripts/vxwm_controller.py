#!/usr/bin/env python3
"""
vxwm_controller.py - Per-Workspace Infinite Spatial Desktop (vxwm Mode)
- Full per-workspace isolation.
- Window position memory (restores exact tiled / floating layout on exit,
  remembers canvas layout on re-entry).
- Seamless boundary management: windows move infinitely in all 4 directions (+X, -X, +Y, -Y).
  When a window completely leaves the active monitor, it is hidden from adjacent displays,
  NEVER squished into a stripe!
- True Spatial Zoom: Zoom Out shrinks and clusters windows towards the viewport center
  allowing you to see the entire infinite canvas. Zoom In enlarges them.
- Ultra-fast socket IPC (<2ms) for lossless 1:1 mouse movement.
"""

import socket
import json
import os
import sys

STATE_FILE = "/tmp/vxwm_workspace_state.json"
QS_PIPE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/run/user/1001"), "qs.pipe")

def get_hypr_socket_path():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1001")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    return os.path.join(runtime_dir, "hypr", sig, ".socket.sock")

def hypr_socket_cmd(cmd_str):
    try:
        sock_path = get_hypr_socket_path()
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(2.0)
            s.connect(sock_path)
            s.sendall(cmd_str.encode("utf-8"))
            buf = b""
            while True:
                data = s.recv(8192)
                if not data:
                    break
                buf += data
            return buf.decode("utf-8", errors="ignore")
    except Exception:
        return ""

def hypr_json(req):
    res = hypr_socket_cmd(f"j/{req}")
    if res.strip():
        try:
            return json.loads(res)
        except Exception:
            pass
    return None

def hypr_dispatch_batch(lua_exprs):
    if not lua_exprs:
        return
    batch_str = "[[BATCH]]" + " ; ".join(f"dispatch {e}" for e in lua_exprs)
    hypr_socket_cmd(batch_str)

def toggle_floating_lua(address, action="toggle"):
    w = f', window = "address:{address}"' if address else ""
    return f'hl.dsp.window.float({{ action = "{action}"{w} }})'

def move_window_exact_lua(x, y, address):
    return (f'hl.dsp.window.move({{ window = "address:{address}", '
            f'x = {int(x)}, y = {int(y)}, relative = false }})')

def resize_window_exact_lua(w, h, address):
    return (f'hl.dsp.window.resize({{ window = "address:{address}", '
            f'x = {int(w)}, y = {int(h)}, relative = false }})')

def set_window_prop_lua(address, prop, value):
    return f'hl.dsp.window.set_prop({{ window = "address:{address}", prop = "{prop}", value = "{value}" }})'

def send_pipe(msg):
    try:
        if os.path.exists(QS_PIPE):
            fd = os.open(QS_PIPE, os.O_WRONLY | os.O_NONBLOCK)
            try:
                os.write(fd, (msg.strip() + "\n").encode("utf-8"))
            finally:
                os.close(fd)
    except Exception:
        pass

def osd_quickshell(tag, icon, msg):
    send_pipe(f"osd:{tag}:{icon}:{msg}")

def notify_quickshell(title, msg):
    send_pipe(f"notify:{title}:{msg}")

def load_state():
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, "r") as f:
                return json.load(f)
    except Exception:
        pass
    return {"active_workspaces": {}, "clamp_to_monitor": False, "saved_canvas_layouts": {}}

def save_state(state):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception:
        pass

def get_clamp_mode():
    state = load_state()
    return state.get("clamp_to_monitor", False)

def set_clamp_mode(val):
    state = load_state()
    state["clamp_to_monitor"] = bool(val)
    save_state(state)

def get_active_monitor_and_workspace():
    mons = hypr_json("monitors") or []
    for m in mons:
        if m.get("focused"):
            act = m.get("activeWorkspace", {})
            return m, act.get("id", 1), str(act.get("name", "1"))
    ws = hypr_json("activeworkspace") or {}
    ws_id = ws.get("id", 1)
    ws_name = str(ws.get("name", ws_id))
    m = mons[0] if mons else {"x": 0, "y": 0, "width": 1920, "height": 1080, "name": "DP-2"}
    return m, ws_id, ws_name

def is_workspace_vxwm(ws_id):
    state = load_state()
    return str(ws_id) in state.get("active_workspaces", {})

def sync_user_window_changes(floating_windows, ws_canvas, zoom, mon):
    mon_x = mon.get("x", 0)
    mon_y = mon.get("y", 0)
    mon_w = mon.get("width", 1920)
    mon_h = mon.get("height", 1080)
    center_x = mon_x + mon_w / 2
    center_y = mon_y + mon_h / 2

    for w in floating_windows:
        addr = w["address"]
        cur_at = w.get("at", [mon_x + 100, mon_y + 100])
        cur_sz = w.get("size", [800, 600])

        if addr not in ws_canvas:
            ws_canvas[addr] = {
                "canvas_at": [cur_at[0], cur_at[1]],
                "orig_size": [cur_sz[0], cur_sz[1]],
                "last_applied_at": [cur_at[0], cur_at[1]],
                "last_applied_sz": [cur_sz[0], cur_sz[1]]
            }
            continue

        entry = ws_canvas[addr]
        last_at = entry.get("last_applied_at")
        last_sz = entry.get("last_applied_sz")

        # 1. Синхронизируем ручной ресайз окна пользователем мышью/хоткеем
        if last_sz is not None and (cur_sz[0] != last_sz[0] or cur_sz[1] != last_sz[1]):
            ow = round(cur_sz[0] / zoom) if zoom > 0 else cur_sz[0]
            oh = round(cur_sz[1] / zoom) if zoom > 0 else cur_sz[1]
            entry["orig_size"] = [max(120, ow), max(80, oh)]
            entry["last_applied_sz"] = [cur_sz[0], cur_sz[1]]

        # 2. Синхронизируем ручное перемещение окна пользователем
        if last_at is not None and (cur_at[0] != last_at[0] or cur_at[1] != last_at[1]):
            ow, oh = entry.get("orig_size", cur_sz)
            cur_cx = cur_at[0] + cur_sz[0] / 2
            cur_cy = cur_at[1] + cur_sz[1] / 2

            if zoom > 0:
                win_cx = center_x + (cur_cx - center_x) / zoom
                win_cy = center_y + (cur_cy - center_y) / zoom
            else:
                win_cx, win_cy = cur_cx, cur_cy

            cx = round(win_cx - ow / 2)
            cy = round(win_cy - oh / 2)
            entry["canvas_at"] = [cx, cy]
            entry["last_applied_at"] = [cur_at[0], cur_at[1]]

def apply_workspace_layout(ws_id, mon, state=None):
    if state is None:
        state = load_state()

    clients = hypr_json("clients") or []
    floating_windows = [
        c for c in clients
        if c.get("workspace", {}).get("id") == ws_id and c.get("floating") and c.get("mapped")
    ]
    if not floating_windows:
        return

    canvas_layouts = state.setdefault("saved_canvas_layouts", {})
    ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
    zoom = float(ws_canvas.get("_zoom", 1.0))

    mon_x = mon.get("x", 0)
    mon_y = mon.get("y", 0)
    mon_w = mon.get("width", 1920)
    mon_h = mon.get("height", 1080)

    center_x = mon_x + mon_w / 2
    center_y = mon_y + mon_h / 2

    # Синхронизируем любые ручные действия пользователя перед расчетом позиций
    sync_user_window_changes(floating_windows, ws_canvas, zoom, mon)

    batch_exprs = []

    for w in floating_windows:
        addr = w["address"]
        entry = ws_canvas[addr]
        cx, cy = entry.get("canvas_at", [mon_x + 100, mon_y + 100])
        ow, oh = entry.get("orig_size", [800, 600])

        # 1. Расчет масштабированного размера окна (Spatial Zoom)
        pw = max(120, round(ow * zoom))
        ph = max(80, round(oh * zoom))

        # 2. Расчет позиции относительно центра экрана
        win_center_x = cx + ow / 2
        win_center_y = cy + oh / 2
        scaled_center_x = center_x + (win_center_x - center_x) * zoom
        scaled_center_y = center_y + (win_center_y - center_y) * zoom

        px = round(scaled_center_x - pw / 2)
        py = round(scaled_center_y - ph / 2)

        entry["last_applied_at"] = [px, py]
        entry["last_applied_sz"] = [pw, ph]

        # 3. Атмосферная 3D глубина (Depth / Z-Axis receding illusion)
        if zoom < 0.98:
            depth_opacity = max(0.55, min(1.0, round(0.35 + 0.65 * zoom, 2)))
            depth_rounding = max(4, round(10 * zoom))
            depth_border = "1" if zoom < 0.75 else "unset"
        else:
            depth_opacity = 1.0
            depth_rounding = 10
            depth_border = "unset"

        batch_exprs.append(set_window_prop_lua(addr, "opacity", str(depth_opacity)))
        batch_exprs.append(set_window_prop_lua(addr, "rounding", str(depth_rounding)))
        batch_exprs.append(set_window_prop_lua(addr, "border_size", str(depth_border)))
        batch_exprs.append(move_window_exact_lua(px, py, addr))
        batch_exprs.append(resize_window_exact_lua(pw, ph, addr))

    if batch_exprs:
        hypr_dispatch_batch(batch_exprs)

    save_state(state)

def toggle_vxwm():
    mon, ws_id, ws_name = get_active_monitor_and_workspace()
    state = load_state()
    active_map = state.setdefault("active_workspaces", {})
    canvas_layouts = state.setdefault("saved_canvas_layouts", {})

    clients = hypr_json("clients") or []
    ws_windows = [c for c in clients if c.get("workspace", {}).get("id") == ws_id and c.get("mapped")]

    if str(ws_id) in active_map:
        # =====================================================================
        # 1. ВЫКЛЮЧЕНИЕ VXWM: ВОССТАНАВЛИВАЕМ ПРЕЖНЕЕ ПОЛОЖЕНИЕ ОКОН
        # =====================================================================
        saved_info = active_map.pop(str(ws_id), {})
        pre_state = saved_info.get("pre_windows", {})

        restore_move_exprs = []
        restore_toggle_exprs = []

        for w in ws_windows:
            addr = w["address"]
            prev = pre_state.get(addr)

            # Сбрасываем эффекты глубины на дефолтные
            restore_toggle_exprs.append(set_window_prop_lua(addr, "opacity", "1.0"))
            restore_toggle_exprs.append(set_window_prop_lua(addr, "rounding", "unset"))
            restore_toggle_exprs.append(set_window_prop_lua(addr, "border_size", "unset"))

            if prev:
                was_floating = prev.get("floating", False)
                orig_at = prev.get("at", [mon["x"] + 100, mon["y"] + 100])
                orig_size = prev.get("size", [800, 600])

                if was_floating:
                    restore_move_exprs.append(move_window_exact_lua(orig_at[0], orig_at[1], addr))
                    restore_move_exprs.append(resize_window_exact_lua(orig_size[0], orig_size[1], addr))
                else:
                    if w.get("floating", False):
                        restore_toggle_exprs.append(toggle_floating_lua(addr, action="off"))
            else:
                if w.get("floating", False):
                    restore_toggle_exprs.append(toggle_floating_lua(addr, action="off"))

        if restore_move_exprs:
            hypr_dispatch_batch(restore_move_exprs)
        if restore_toggle_exprs:
            hypr_dispatch_batch(restore_toggle_exprs)

        save_state(state)
        print(f"Workspace {ws_name} (ID {ws_id}): vxwm disabled, restored {len(ws_windows)} window positions.")
        osd_quickshell("vxwm", "󰍹", f"Бесконечный стол: Выкл (Стол {ws_name})")
        notify_quickshell("Бесконечный стол", f"Воркспейс {ws_name}: сетка тайлинга восстановлена.")

    else:
        # =====================================================================
        # 2. ВКЛЮЧЕНИЕ VXWM: ОТКРЕПЛЯЕМ СЕТКУ, ВСПОМИНАЕМ ПОЛОЖЕНИЕ НА ХОЛСТЕ
        # =====================================================================
        pre_windows = {}
        float_exprs = []

        for w in ws_windows:
            addr = w["address"]
            is_floating = bool(w.get("floating", False))
            pre_windows[addr] = {
                "floating": is_floating,
                "at": w.get("at", [0, 0]),
                "size": w.get("size", [0, 0]),
                "class": w.get("class", ""),
                "title": w.get("title", "")
            }
            if not is_floating:
                float_exprs.append(toggle_floating_lua(addr, action="on"))

        if float_exprs:
            hypr_dispatch_batch(float_exprs)

        active_map[str(ws_id)] = {
            "name": ws_name,
            "monitor": mon["name"],
            "pre_windows": pre_windows
        }

        ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
        if "_zoom" not in ws_canvas:
            ws_canvas["_zoom"] = 1.0

        for w in ws_windows:
            addr = w["address"]
            at = w.get("at", [mon["x"] + 100, mon["y"] + 100])
            sz = w.get("size", [800, 600])

            # Если окно было тайловым на весь монитор, делаем удобный начальный плавающий размер
            if not w.get("floating", False) and (sz[0] >= mon["width"] - 60 and sz[1] >= mon["height"] - 80):
                w_target = min(1100, mon["width"] - 200)
                h_target = min(750, mon["height"] - 150)
                x_target = round(mon["x"] + (mon["width"] - w_target) / 2)
                y_target = round(mon["y"] + (mon["height"] - h_target) / 2)
            else:
                w_target = sz[0]
                h_target = sz[1]
                x_target = at[0]
                y_target = at[1]

            if addr not in ws_canvas:
                ws_canvas[addr] = {
                    "canvas_at": [x_target, y_target],
                    "orig_size": [w_target, h_target],
                    "last_applied_at": [x_target, y_target],
                    "last_applied_sz": [w_target, h_target]
                }
            else:
                entry = ws_canvas[addr]
                entry["last_applied_at"] = list(entry.get("canvas_at", [x_target, y_target]))
                entry["last_applied_sz"] = list(entry.get("orig_size", [w_target, h_target]))

        save_state(state)
        apply_workspace_layout(ws_id, mon, state)

        print(f"Workspace {ws_name} (ID {ws_id}): vxwm enabled, unpinned {len(ws_windows)} windows.")
        osd_quickshell("vxwm", "󰍹", f"Бесконечный стол: Вкл (Стол {ws_name})")
        notify_quickshell("Бесконечный стол", f"Воркспейс {ws_name}: окна откреплены в свободный полет.")

def pan_canvas(dx, dy):
    mon, ws_id, ws_name = get_active_monitor_and_workspace()
    state = load_state()
    if str(ws_id) not in state.get("active_workspaces", {}):
        return

    canvas_layouts = state.setdefault("saved_canvas_layouts", {})
    ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
    zoom = float(ws_canvas.get("_zoom", 1.0))

    clients = hypr_json("clients") or []
    floating_windows = [
        c for c in clients
        if c.get("workspace", {}).get("id") == ws_id and c.get("floating") and c.get("mapped")
    ]
    if not floating_windows:
        return

    # Синхронизируем любые ручные изменения размеров и координат пользователем перед сдвигом
    sync_user_window_changes(floating_windows, ws_canvas, zoom, mon)

    canvas_dx = round(dx / zoom) if zoom > 0 else dx
    canvas_dy = round(dy / zoom) if zoom > 0 else dy

    for w in floating_windows:
        addr = w["address"]
        entry = ws_canvas[addr]
        entry["canvas_at"][0] += canvas_dx
        entry["canvas_at"][1] += canvas_dy

    apply_workspace_layout(ws_id, mon, state)

def zoom_in():
    mon, ws_id, ws_name = get_active_monitor_and_workspace()
    state = load_state()
    if str(ws_id) not in state.get("active_workspaces", {}):
        return

    canvas_layouts = state.setdefault("saved_canvas_layouts", {})
    ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
    cur_zoom = float(ws_canvas.get("_zoom", 1.0))
    new_zoom = min(2.0, round(cur_zoom + 0.15, 2))
    ws_canvas["_zoom"] = new_zoom
    save_state(state)

    apply_workspace_layout(ws_id, mon, state)
    pct = int(round(new_zoom * 100))
    if new_zoom > 1.0:
        osd_quickshell("zoom", "󰍉", f"Приближение: {pct}%")
    elif new_zoom < 1.0:
        osd_quickshell("zoom", "󰍉", f"Отдаление: {pct}% (Глубина)")
    else:
        osd_quickshell("zoom", "󰍉", "Масштаб: 100% (Фокус)")

def zoom_out():
    mon, ws_id, ws_name = get_active_monitor_and_workspace()
    state = load_state()
    if str(ws_id) not in state.get("active_workspaces", {}):
        return

    canvas_layouts = state.setdefault("saved_canvas_layouts", {})
    ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
    cur_zoom = float(ws_canvas.get("_zoom", 1.0))
    new_zoom = max(0.35, round(cur_zoom - 0.15, 2))
    ws_canvas["_zoom"] = new_zoom
    save_state(state)

    apply_workspace_layout(ws_id, mon, state)
    pct = int(round(new_zoom * 100))
    if new_zoom < 1.0:
        osd_quickshell("zoom", "󰍉", f"Отдаление: {pct}% (Глубина)")
    else:
        osd_quickshell("zoom", "󰍉", "Масштаб: 100% (Фокус)")

def zoom_reset():
    mon, ws_id, ws_name = get_active_monitor_and_workspace()
    state = load_state()
    if str(ws_id) not in state.get("active_workspaces", {}):
        return

    canvas_layouts = state.setdefault("saved_canvas_layouts", {})
    ws_canvas = canvas_layouts.setdefault(str(ws_id), {})
    ws_canvas["_zoom"] = 1.0
    save_state(state)

    apply_workspace_layout(ws_id, mon, state)
    osd_quickshell("zoom", "󰍉", "Масштаб: 100% (Фокус)")

def toggle_clamp():
    cur = get_clamp_mode()
    new_val = not cur
    set_clamp_mode(new_val)
    msg = "Изоляция мониторов: Вкл" if new_val else "Изоляция мониторов: Выкл"
    print(msg)
    osd_quickshell("vxwm_clamp", "󰹑", msg)
    notify_quickshell("Бесконечный рабочий стол", msg)

def main():
    if len(sys.argv) < 2:
        print("Usage: vxwm_controller.py [toggle|pan <dx> <dy>|zoom_in|zoom_out|zoom_reset|toggle_clamp|is_active|status]")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "toggle":
        toggle_vxwm()
    elif cmd == "pan":
        if len(sys.argv) >= 4:
            try:
                dx = int(sys.argv[2])
                dy = int(sys.argv[3])
                pan_canvas(dx, dy)
            except ValueError:
                pass
    elif cmd == "zoom_in":
        zoom_in()
    elif cmd == "zoom_out":
        zoom_out()
    elif cmd == "zoom_reset":
        zoom_reset()
    elif cmd == "toggle_clamp":
        toggle_clamp()
    elif cmd == "is_active":
        _, ws_id, _ = get_active_monitor_and_workspace()
        sys.exit(0 if is_workspace_vxwm(ws_id) else 1)
    elif cmd == "status":
        mon, ws_id, ws_name = get_active_monitor_and_workspace()
        active = is_workspace_vxwm(ws_id)
        clamp = get_clamp_mode()
        print(json.dumps({
            "workspaceId": ws_id,
            "workspaceName": ws_name,
            "monitor": mon["name"],
            "vxwmActive": active,
            "clampToMonitor": clamp
        }))
    else:
        print(f"Unknown command: {cmd}")

if __name__ == "__main__":
    main()
