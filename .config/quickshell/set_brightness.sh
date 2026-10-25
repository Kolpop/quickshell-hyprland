#!/bin/bash
# Brightness is now handled natively via Quickshell hardware-accelerated overlay
# to prevent Hyprland shader compilation lag and screen flickering.
hyprctl eval "hl.config({ decoration = { screen_shader = '' } })" 2>/dev/null
