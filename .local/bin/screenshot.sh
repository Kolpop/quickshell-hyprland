#!/usr/bin/env bash
set -e

# Папка для сохранения скриншотов
SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

# 1. Получаем имя активного монитора
ACTIVE_MON="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null || true)"
if [[ -z "$ACTIVE_MON" ]]; then
    ACTIVE_MON="$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || true)"
fi

# 2. Мгновенная заморозка экрана (стоп-кадр grim)
FREEZE_FILE="/tmp/qs_freeze.png"
rm -f "$FREEZE_FILE"

if [[ -n "$ACTIVE_MON" ]]; then
    grim -o "$ACTIVE_MON" "$FREEZE_FILE"
else
    grim "$FREEZE_FILE"
fi

# 3. Открытие нативного Material You оверлея в Quickshell через IPC
PIPE="${XDG_RUNTIME_DIR:-/tmp}/qs.pipe"
if [[ -p "$PIPE" ]]; then
    echo "start_screenshot:$ACTIVE_MON" > "$PIPE"
else
    # Fallback на Satty если Quickshell не доступен
    if command -v satty >/dev/null 2>&1; then
        SATTY_BIN="satty"
    elif [[ -x "$HOME/.local/bin/satty" ]]; then
        SATTY_BIN="$HOME/.local/bin/satty"
    else
        SATTY_BIN=""
    fi
    if [[ -n "$SATTY_BIN" ]]; then
        TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
        "$SATTY_BIN" \
            --filename "$FREEZE_FILE" \
            --fullscreen current-screen \
            --initial-tool crop \
            --actions-on-enter "save-to-clipboard,save-to-file,exit" \
            --output-filename "$SCREENSHOTS_DIR/${TIMESTAMP}.png"
    fi
fi
