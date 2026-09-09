Hyprland + Quickshell + Waybar rice for CachyOS




## Quick install

```
git clone https://github.com/saiccoumar/hypr-config.git
chmod +x install_sai.sh
./install_sai.sh
```

## What's included

- **Window manager**: Hyprland with custom keybinds (QWERTY layout)
- **Shell/widgets**: Quickshell with custom QML widgets (menu, lockscreen, wallpaper picker, notifications, weather, control centre)
- **Bar**: Waybar
- **Terminal**: Kitty
- **KDE apps**: Unit3 Gold colour scheme, applied by the installer

## Customization

Personal overrides go in `~/.config/hypr/user.conf` — this file is **never** overwritten by updates.

Example:
monitor = DP-1, 2560x1440@144, 0x0, 1
input { kb_layout = us }
bind = SUPER, B, exec, firefox

## Keybinds

| Key | Action |
|-----|--------|
| `SUPER + Space` | App menu |
| `SUPER + Tab` | Toggle Quickshell bar |
| `SUPER + L` | Lockscreen |
| `SUPER + Return` | Toggle weather widget |
| `SUPER SHIFT + Return` | Weather widget on top |
| `SUPER + T` | Terminal (kitty) |
| `SUPER + E` | File manager (dolphin) |
| `SUPER + C` | Editor (VS Code) |
| `SUPER + M` | Spotify (special workspace) |
| `SUPER + P` | Wallpaper picker |
| `SUPER + R` | Restart Quickshell |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + D` | Maximise (fullscreen 1) |
| `SUPER + G` | Toggle floating |
| `SUPER + S` | Scratchpad (special: magic) |
| `SUPER SHIFT + S` | Move window to scratchpad |
| `SUPER + W` / `SUPER SHIFT + W` | Master / dwindle layout |
| `SUPER + arrows` | Move focus |
| `SUPER SHIFT + arrows` | Move window |
| `SUPER + Escape` | Exit Hyprland |
| `ALT + Tab` | Cycle windows |
| `ALT + 1..0` | Switch workspace |
| `ALT SHIFT + 1..0` | Move window to workspace |
| `Print` | Region screenshot → `~/Screenshots` |
| `ALT SHIFT + S` | Region screenshot (hyprshot) |
