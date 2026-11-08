-- Hyprland config (Lua, Hyprland 0.55+)
-- API reference: /usr/share/hypr/stubs/hl.meta.lua

---@module 'hl'

-- ── Écrans ──
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-5",  mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = "",      mode = "preferred",    position = "auto",   scale = 1 })

-- Monitors toggled off with SUPER + 1/2/3 (see display-mode.sh) for this session.
do
    local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    local run = os.getenv("XDG_RUNTIME_DIR")
    local f = sig and run and io.open(run .. "/hypr/" .. sig .. "/disabled-monitors", "r")
    if f then
        for name in f:lines() do
            if name ~= "" then hl.monitor({ output = name, disabled = true }) end
        end
        f:close()
    end
end

-- ── Autostart ──
hl.on("hyprland.start", function()
    hl.exec_cmd("env QT_MEDIA_BACKEND=ffmpeg qs -p ~/.config/quickshell/shell.qml")
    hl.exec_cmd("pkill dunst")
    hl.exec_cmd("pkill mako")
    hl.exec_cmd("pkill swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.config/quickshell/lock.sh")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("/usr/bin/waybar")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("~/.config/quickshell/wave-check.sh")
end)

-- ── Environnement ──
hl.env("PATH", "/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- ── Options ──
hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        },
    },

    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 1,
        layout      = "dwindle",
        col = {
            active_border   = "rgba(c8b89aee)",
            inactive_border = "rgba(1a1814aa)",
        },
    },

    decoration = {
        rounding = 0,
        blur   = { enabled = false },
        shadow = { enabled = false },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        -- pseudotile = true,
        preserve_split = true,
    },

    master = {
        new_status = "master",
        mfact      = 0.55,
    },
})

-- ── Animations ──
hl.curve("niercurve", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "niercurve" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "niercurve", style = "slidevert" })

-- ── Règles fenêtres Quickshell ──
hl.window_rule({
    name  = "quickshell",
    match = { class = "^(quickshell)$" },

    float     = true,
    pin       = true,
    no_blur   = true,
    no_shadow = true,
})

-- ══════════════════════════════════════════════════
-- RACCOURCIS
-- ══════════════════════════════════════════════════

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- ── Launcher (menu applications) ──
hl.bind("SUPER + space", exec("echo t >> /tmp/qs-menu"))   -- ouvre/ferme le menu
hl.bind("SUPER + Tab",   exec("qs ipc call ctrl toggle"))

-- ── Lockscreen Quickshell ──
hl.bind("SUPER + L", exec("~/.config/quickshell/lock.sh"), { release = true })

-- ── Player Quickshell ──
hl.bind("SUPER + Return",         exec("echo t >> /tmp/qs-toggle"))
hl.bind("SUPER + SHIFT + Return", exec("echo t >> /tmp/qs-front"))

-- ── Applications ──
hl.bind("SUPER + T", exec("/usr/bin/kitty"))
hl.bind("SUPER + E", exec("env QT_QPA_PLATFORMTHEME=kde /usr/bin/dolphin"))
hl.bind("SUPER + C", exec("/usr/bin/code"))
hl.bind("SUPER + M", exec("pgrep -x spotify >/dev/null || spotify"))
hl.bind("SUPER + R", exec("pkill qs"))
hl.bind("SUPER + P", exec("~/.config/quickshell/wallpaper.sh"))

-- ── Gestion des fenêtres ──
hl.bind("SUPER + Q",         hl.dsp.window.close())
hl.bind("SUPER + F",         hl.dsp.window.fullscreen())
hl.bind("SUPER + G",         hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + Escape",    hl.dsp.exit())
hl.bind("SUPER + D",         hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind("SUPER + W",         function() hl.config({ general = { layout = "master" } }) end)
hl.bind("SUPER + SHIFT + W", function() hl.config({ general = { layout = "dwindle" } }) end)

-- ── Écrans (1=HDMI-A-1, 2=DP-1, 3=DP-2) ──
for i = 1, 3 do
    hl.bind("SUPER + " .. i, exec("~/.config/hypr/display-mode.sh " .. i))
end

-- ── Focus ──
hl.bind("ALT + Tab",         hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- ── Focus / déplacement directionnel ──
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. dir,         hl.dsp.focus({ direction = dir }))
    hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- ── Special workspace ──
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + S",         hl.dsp.workspace.toggle_special("magic"))

-- ── Workspaces — ALT + [0-9] (switch) / ALT + SHIFT + [0-9] (move) ──
local wsm = "~/.config/hypr/workspace_manager.py "
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("ALT + " .. key,         exec(wsm .. i .. " switch"))
    hl.bind("ALT + SHIFT + " .. key, exec(wsm .. i .. " move"))
end

-- ── Scroll workspaces ──
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ── Step workspaces (by monitor count) ──
hl.bind("ALT + Next",  exec(wsm .. "next switch"))
hl.bind("ALT + Prior", exec(wsm .. "prev switch"))

-- ── Souris ──
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Audio ──
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- ── Luminosité ──
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"))

-- ── Capture d'écran ──
hl.bind("ALT + SHIFT + S", exec("hyprshot -m region"))
hl.bind("Print",           exec('grim -g "$(slurp)" ~/Screenshots/$(date +%Y%m%d_%H%M%S).png'))

-- ═══════════════════════════════════════════════════════════════════
-- User overrides — see user.lua
-- This file is created empty by the installer and is NEVER overwritten
-- by future updates. Put your monitor setup, custom binds, env vars,
-- theme tweaks, etc. there. Loaded last so it wins.
-- ═══════════════════════════════════════════════════════════════════
local ok, err = pcall(require, "user")
if not ok and not tostring(err):find("module 'user' not found", 1, true) then
    error(err)
end
