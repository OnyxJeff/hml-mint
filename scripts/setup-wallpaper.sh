#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_DIR="$SCRIPT_DIR/../wallpapers"

DEFAULT_WALLPAPER="homelab-default.jpg"
SELECTED_WALL=""

PCMANFM_CONF_DIR="$REAL_HOME/.config/pcmanfm/LXDE-pi"
PCMANFM_CONF="$PCMANFM_CONF_DIR/desktop-items-0.conf"

DEST_DIR="$REAL_HOME/Pictures"

echo ""
echo "========================================="
echo " Wallpaper Setup (PCManFM Model - PiOS 13)"
echo "========================================="
echo ""

# --------------------------------------------------
# Resolve wallpaper
# --------------------------------------------------

if [[ -f "$WALLPAPER_DIR/$DEFAULT_WALLPAPER" ]]; then
    SELECTED_WALL="$WALLPAPER_DIR/$DEFAULT_WALLPAPER"
else
    SELECTED_WALL=$(find "$WALLPAPER_DIR" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.png" \) | sort | head -n 1)
fi

if [[ -z "$SELECTED_WALL" ]]; then
    echo "[✖] No wallpaper found"
    exit 1
fi

echo "[*] Using: $(basename "$SELECTED_WALL")"

# --------------------------------------------------
# Copy wallpaper
# --------------------------------------------------

mkdir -p "$DEST_DIR"

EXT="${SELECTED_WALL##*.}"
FINAL_WALL="$DEST_DIR/homelab-wallpaper.$EXT"

cp -f "$SELECTED_WALL" "$FINAL_WALL"

# --------------------------------------------------
# Ensure PCManFM config path exists
# --------------------------------------------------

mkdir -p "$PCMANFM_CONF_DIR"

# --------------------------------------------------
# Write PCManFM wallpaper config (AUTHORITATIVE)
# --------------------------------------------------

cat > "$PCMANFM_CONF" <<EOF
[*]
wallpaper=$FINAL_WALL
wallpaper_mode=stretch
show_wm_menu=0
desktop_bg=#000000
desktop_fg=#ffffff
desktop_shadow=0
desktop_font=Sans 10
EOF

# --------------------------------------------------
# Restart desktop wallpaper renderer safely
# --------------------------------------------------

echo "[*] Restarting PCManFM desktop (if running)..."

pkill pcmanfm || true
nohup sudo -u "$REAL_USER" pcmanfm --desktop --profile=LXDE-pi >/dev/null 2>&1 &

# --------------------------------------------------
# Permissions
# --------------------------------------------------

chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/Pictures"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/pcmanfm"

echo ""
echo "[✓] Wallpaper now controlled by PCManFM"
echo "[✓] Labwc no longer involved in wallpaper management"
echo "[✓] Changes persist across reboot"