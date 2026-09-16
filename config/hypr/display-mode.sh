#!/bin/sh
# SUPER + 1/2/3 toggles one specific monitor on/off.
# Useful because the NanoKVM PCIe card exposes virtual monitors
# (HDMI-A-1, DP-1) with no physical screen at the desk, so windows that land
# there are invisible until toggled off. All monitors are enabled on boot.

case "$1" in
    1) MON="HDMI-A-1" ;;
    2) MON="DP-1" ;;
    3) MON="DP-2" ;;
    *) echo "usage: $0 [1|2|3]" >&2; exit 1 ;;
esac

if hyprctl monitors -j | jq -e --arg m "$MON" 'any(.[]; .name == $m)' >/dev/null; then
    hyprctl keyword monitor "$MON,disable"
else
    hyprctl keyword monitor "$MON,preferred,auto,1"
fi
