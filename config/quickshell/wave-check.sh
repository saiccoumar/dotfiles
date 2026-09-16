#!/usr/bin/env bash
# ═════════════════════════════════════════════════════════════════════
# wave-check.sh
# Vérifie au démarrage Hyprland que les vidéos de la vague de pixels
# (reveal + hide) sont présentes, pour CHAQUE résolution de moniteur
# connecté. Si non, les génère en bloquant.
#
# Usage :
#   - Lancer manuellement : ./wave-check.sh
#   - Au démarrage : exec-once = ~/.config/quickshell/wave-check.sh
# ═════════════════════════════════════════════════════════════════════

set -e

# ── Parse arguments ──
FORCE=0
for arg in "$@"; do
    if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
        FORCE=1
    fi
done

# ── Paths génériques (respecte XDG) ──
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

QS_DIR="$CONFIG_HOME/quickshell"
VIDEOS_DIR="$QS_DIR/videos"
LOG_DIR="$CACHE_HOME/quickshell"
LOG_FILE="$LOG_DIR/wave-check.log"

# Scripts générateurs
REVEAL_SCRIPT="$QS_DIR/pixel_wave.py"
HIDE_SCRIPT="$QS_DIR/pixel-wave-close-video.py"
LAST_FRAME_SCRIPT="$QS_DIR/ext_last_fr.py"

# ── Préparation ──
mkdir -p "$VIDEOS_DIR" "$LOG_DIR"

# ── Résolutions de tous les moniteurs connectés ──
# Un jeu de vidéos (reveal/hide/last_frame) est généré par résolution
# distincte, pour que chaque écran (ex: ultrawide + CRT 4:3) ait sa
# propre vidéo au bon ratio, au lieu de réutiliser celle du moniteur
# focus au démarrage.
RESOLUTIONS=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.width)x\(.height)"' 2>/dev/null | sort -u)
if [[ -z "$RESOLUTIONS" ]]; then
    RESOLUTIONS="1920x1080"
fi

FOCUSED_RES=$(hyprctl monitors -j 2>/dev/null | jq -r '(map(select(.focused)) + .)[0] | "\(.width)x\(.height)"' 2>/dev/null)
if [[ -z "$FOCUSED_RES" || "$FOCUSED_RES" == "null" ]]; then
    FOCUSED_RES=$(echo "$RESOLUTIONS" | head -n1)
fi

# Redirection stdout + stderr vers le log (avec timestamp)
exec > >(while IFS= read -r line; do printf '[%s] %s\n' "$(date +%H:%M:%S)" "$line"; done >> "$LOG_FILE") 2>&1

echo "═══════════════════════════════════════════════════════════"
echo "wave-check.sh — démarrage"
echo "  videos dir : $VIDEOS_DIR"
echo "  résolutions détectées : $(echo "$RESOLUTIONS" | tr '\n' ' ')"
echo "═══════════════════════════════════════════════════════════"

# ── Vérification présence des scripts ──
missing_scripts=()
[[ -f "$REVEAL_SCRIPT" ]] || missing_scripts+=("$REVEAL_SCRIPT")
[[ -f "$HIDE_SCRIPT"   ]] || missing_scripts+=("$HIDE_SCRIPT")
[[ -f "$LAST_FRAME_SCRIPT" ]] || missing_scripts+=("$LAST_FRAME_SCRIPT")
if (( ${#missing_scripts[@]} > 0 )); then
    echo "❌ Script(s) générateur(s) manquant(s) :"
    printf '   - %s\n' "${missing_scripts[@]}"
    echo "Abandon."
    exit 1
fi

# ── Génération par résolution ──
while IFS= read -r RES; do
    [[ -z "$RES" ]] && continue
    WAVE_W="${RES%x*}"
    WAVE_H="${RES#*x}"

    REVEAL_VIDEO="$VIDEOS_DIR/wave_reveal_${RES}.mp4"
    HIDE_VIDEO="$VIDEOS_DIR/wave_hide_${RES}.mp4"
    LAST_FRAME="$VIDEOS_DIR/wave_last_frame_${RES}.png"

    if [[ -f "$REVEAL_VIDEO" ]] && [[ $FORCE -eq 0 ]]; then
        echo "✓ wave_reveal_${RES}.mp4 existe déjà"
    else
        echo "↻ génération wave_reveal_${RES}.mp4… ($WAVE_W x $WAVE_H)"
        python "$REVEAL_SCRIPT" -w "$WAVE_W" -H "$WAVE_H" -o "$REVEAL_VIDEO"
        if [[ -f "$REVEAL_VIDEO" ]]; then
            echo "✓ wave_reveal_${RES}.mp4 généré"
        else
            echo "❌ échec génération wave_reveal_${RES}.mp4"
            exit 2
        fi
    fi

    if [[ -f "$HIDE_VIDEO" ]] && [[ $FORCE -eq 0 ]]; then
        echo "✓ wave_hide_${RES}.mp4 existe déjà"
    else
        echo "↻ génération wave_hide_${RES}.mp4… ($WAVE_W x $WAVE_H)"
        python "$HIDE_SCRIPT" -w "$WAVE_W" -H "$WAVE_H" -o "$HIDE_VIDEO"
        if [[ -f "$HIDE_VIDEO" ]]; then
            echo "✓ wave_hide_${RES}.mp4 généré"
        else
            echo "❌ échec génération wave_hide_${RES}.mp4"
            exit 3
        fi
    fi

    if [[ -f "$LAST_FRAME" ]] && [[ $FORCE -eq 0 ]]; then
        echo "✓ wave_last_frame_${RES}.png existe déjà"
    else
        echo "↻ génération wave_last_frame_${RES}.png…"
        python "$LAST_FRAME_SCRIPT" "$REVEAL_VIDEO"
        if [[ -f "$LAST_FRAME" ]]; then
            echo "✓ wave_last_frame_${RES}.png généré"
        else
            echo "❌ échec génération wave_last_frame_${RES}.png"
            exit 4
        fi
    fi
done <<< "$RESOLUTIONS"

# ── Copie vers les noms génériques (rétrocompatibilité) ──
# WallpaperPicker.qml (et tout autre consommateur qui ignore la résolution)
# continue d'utiliser wave_reveal.mp4 / wave_hide.mp4 / wave_last_frame.png,
# qui pointent vers la résolution du moniteur focus.
if [[ $FORCE -eq 1 ]] || [[ ! -f "$VIDEOS_DIR/wave_reveal.mp4" ]]; then
    cp -f "$VIDEOS_DIR/wave_reveal_${FOCUSED_RES}.mp4" "$VIDEOS_DIR/wave_reveal.mp4"
fi
if [[ $FORCE -eq 1 ]] || [[ ! -f "$VIDEOS_DIR/wave_hide.mp4" ]]; then
    cp -f "$VIDEOS_DIR/wave_hide_${FOCUSED_RES}.mp4" "$VIDEOS_DIR/wave_hide.mp4"
fi
if [[ $FORCE -eq 1 ]] || [[ ! -f "$VIDEOS_DIR/wave_last_frame.png" ]]; then
    cp -f "$VIDEOS_DIR/wave_last_frame_${FOCUSED_RES}.png" "$VIDEOS_DIR/wave_last_frame.png"
fi

echo "═══════════════════════════════════════════════════════════"
echo "wave-check.sh — terminé"
echo "═══════════════════════════════════════════════════════════"
