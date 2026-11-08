#!/bin/sh
# SUPER + 1/2/3 toggles one specific monitor on/off.
# Useful because the NanoKVM PCIe card exposes virtual monitors
# (HDMI-A-1, DP-1) with no physical screen at the desk, so windows that land
# there are invisible until toggled off. All monitors are enabled on boot.
#
# Lua config mode: monitor rules only take effect from the config, so the
# toggled-off monitors are kept in a per-session list that hyprland.lua reads,
# then the config is reloaded. The list lives in the Hyprland instance dir, so
# every new session starts with all monitors enabled.

case "$1" in
    1) MON="HDMI-A-1" ;;
    2) MON="DP-1" ;;
    3) MON="DP-2" ;;
    *) echo "usage: $0 [1|2|3]" >&2; exit 1 ;;
esac

: "${HYPRLAND_INSTANCE_SIGNATURE:?not running under Hyprland}"
STATE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/$HYPRLAND_INSTANCE_SIGNATURE/disabled-monitors"
touch "$STATE"

if grep -qxF "$MON" "$STATE"; then
    grep -vxF "$MON" "$STATE" > "$STATE.tmp"; mv "$STATE.tmp" "$STATE"
else
    echo "$MON" >> "$STATE"
fi

hyprctl reload >/dev/null
