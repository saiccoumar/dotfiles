#!/usr/bin/env bash
# Manually start a Wayland session from a tty shell, e.g. right after
# scripts/switch.sh has logged you out of the other session.
set -euo pipefail

usage() {
    echo "usage: $0 --dm <hyprland|plasma>" >&2
    exit 1
}

dm=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dm)
            dm="${2:-}"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

case "$dm" in
    hyprland)
        exec start-hyprland
        ;;
    plasma)
        exec uwsm start -D KDE startplasma-wayland
        ;;
    *)
        usage
        ;;
esac
