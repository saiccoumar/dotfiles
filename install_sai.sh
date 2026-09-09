#!/usr/bin/env bash
set -euo pipefail

# Simple dependency installer for my Hyprland setup.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_AUR=true
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)-$$"
CONFIG_DIRS=(hypr quickshell waybar kitty dunst)
PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
WALLPAPER_DIR="$PICTURES_DIR/wallpapers"
SCREENSHOT_DIR="$HOME/Screenshots"

for arg in "$@"; do
    case "$arg" in
        --no-aur)
            INSTALL_AUR=false
            ;;
        --help|-h)
            echo "Usage: ./install_sai.sh [--no-aur]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: ./install_sai.sh [--no-aur]" >&2
            exit 1
            ;;
    esac
done

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root."
    exit 1
fi

if ! command -v pacman >/dev/null; then
    echo "pacman was not found. This script is meant for Arch Linux."
    exit 1
fi

if ! command -v sudo >/dev/null; then
    echo "sudo is required."
    exit 1
fi

package_list() {
    grep -vE '^\s*(#|$)' "$1"
}

copy_configs() {
    mkdir -p "$CONFIG_HOME"

    for name in "${CONFIG_DIRS[@]}"; do
        local source_dir="$SCRIPT_DIR/config/$name"
        local target_dir="$CONFIG_HOME/$name"

        if [[ ! -d "$source_dir" ]]; then
            continue
        fi

        if [[ -e "$target_dir" ]]; then
            mkdir -p "$BACKUP_DIR"
            echo "Backing up $target_dir to $BACKUP_DIR/$name"
            cp -a "$target_dir" "$BACKUP_DIR/$name"
        else
            mkdir -p "$target_dir"
        fi

        echo "Copying $name config..."
        cp -a "$source_dir/." "$target_dir/"
    done


    find "$CONFIG_HOME/hypr" "$CONFIG_HOME/quickshell" "$CONFIG_HOME/waybar" \
        -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true

    if [[ ! -f "$CONFIG_HOME/hypr/user.conf" ]]; then
        echo "Creating empty Hyprland user override file..."
        touch "$CONFIG_HOME/hypr/user.conf"
    fi

    if [[ -d "$BACKUP_DIR" ]]; then
        echo "Old configs were backed up to $BACKUP_DIR"
    fi
}

apply_kde_colors() {
    local scheme="$SCRIPT_DIR/config/kde/Unit3Gold.colors"
    local script="$SCRIPT_DIR/scripts/apply-kde-colors.py"
    [[ -f "$scheme" && -f "$script" ]] || return 0
    echo "Applying Unit3 Gold KDE colour scheme..."
    python3 "$script" "$scheme"
}

install_pam_files() {
    for source_file in "$SCRIPT_DIR/config/system/pam.d/"*; do
        if [[ ! -f "$source_file" ]]; then
            continue
        fi

        name="$(basename "$source_file")"
        target_file="/etc/pam.d/$name"

        if [[ -f "$target_file" ]]; then
            echo "Backing up $target_file to $BACKUP_DIR/$name.pam"
            mkdir -p "$BACKUP_DIR"
            cp -a "$target_file" "$BACKUP_DIR/$name.pam"
        fi

        echo "Installing PAM file: $target_file"
        sudo install -D -m 644 "$source_file" "$target_file"
    done
}

setup_user_dirs() {
    # hyprland.conf writes screenshots here (Print / ALT+SHIFT+S)
    mkdir -p "$SCREENSHOT_DIR" "$WALLPAPER_DIR"
}

enable_services() {
    echo "Enabling services..."
    sudo systemctl enable --now NetworkManager.service 2>/dev/null || echo "  NetworkManager: skipped."
    sudo systemctl enable --now bluetooth.service 2>/dev/null || echo "  bluetooth: skipped."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null \
        || echo "  pipewire: skipped (fine if started with the session)."
}

copy_wallpapers() {
    local source_dir="$SCRIPT_DIR/assets/wallpapers"

    if [[ ! -d "$source_dir" ]]; then
        return
    fi

    mkdir -p "$WALLPAPER_DIR"
    echo "Copying wallpapers to $WALLPAPER_DIR..."
    cp -a "$source_dir/." "$WALLPAPER_DIR/"
}

echo "Checking sudo access..."
sudo -v

echo "Installing base tools..."
sudo pacman -S --needed --noconfirm base-devel git

if $INSTALL_AUR; then
    if command -v yay >/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null; then
        AUR_HELPER="paru"
    else
        echo "Installing yay for AUR packages..."
        tmp_dir="$(mktemp -d)"
        git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
        (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp_dir"
        AUR_HELPER="yay"
    fi
fi

PACMAN_PACKAGES="$SCRIPT_DIR/packages/pacman.txt"
AUR_PACKAGES="$SCRIPT_DIR/packages/aur.txt"

if [[ -f "$PACMAN_PACKAGES" ]]; then
    mapfile -t packages < <(package_list "$PACMAN_PACKAGES")
    echo "Installing pacman packages..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
else
    echo "Missing package list: $PACMAN_PACKAGES"
    exit 1
fi

if $INSTALL_AUR && [[ -f "$AUR_PACKAGES" ]]; then
    mapfile -t aur_packages < <(package_list "$AUR_PACKAGES")
    echo "Installing AUR packages..."
    "$AUR_HELPER" -S --needed --noconfirm "${aur_packages[@]}"
elif ! $INSTALL_AUR; then
    echo "Skipping AUR packages."
fi

copy_configs
apply_kde_colors
setup_user_dirs
copy_wallpapers
install_pam_files
enable_services

echo "Done. Log out and back into Hyprland to apply."
