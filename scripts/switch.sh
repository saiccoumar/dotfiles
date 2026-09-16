#!/usr/bin/env bash
# Switch the current graphical session between Hyprland and KDE Plasma.
#
# tty1 autologin normally launches Hyprland straight away (see
# ~/.config/fish/config.fish). This script logs out of whichever session is
# currently active and drops a one-shot flag telling the next login which
# session to start instead. Hyprland is always the default when the flag is
# absent, so switching back to it from Plasma needs no flag at all.
set -euo pipefail

FLAG_FILE="$HOME/.cache/next-wayland-session"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "Hyprland is active -> switching to KDE Plasma on next login."
    mkdir -p "$(dirname "$FLAG_FILE")"
    echo "plasma" >"$FLAG_FILE"
    exec hyprctl dispatch exit

elif [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] || pgrep -x plasmashell >/dev/null 2>&1; then
    echo "KDE Plasma is active -> switching to Hyprland on next login."
    rm -f "$FLAG_FILE"
    if command -v qdbus6 >/dev/null 2>&1 &&
        qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout >/dev/null 2>&1; then
        exit 0
    fi
    exec loginctl terminate-session "${XDG_SESSION_ID:?XDG_SESSION_ID not set}"

else
    echo "Could not detect an active Hyprland or Plasma session." >&2
    exit 1
fi
