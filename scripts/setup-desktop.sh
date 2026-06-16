#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

DESKTOP_DIR="$REAL_HOME/Desktop"

echo ""
echo "========================================="
echo " Desktop Provisioning"
echo "========================================="
echo "[*] Target user: $REAL_USER"
echo "[*] Desktop dir: $DESKTOP_DIR"
echo ""

mkdir -p "$DESKTOP_DIR"

# --------------------------------------------------
# Helper: write desktop entries safely
# --------------------------------------------------
write_desktop() {
    local name="$1"
    local content="$2"

    cat > "$DESKTOP_DIR/$name" <<EOF
$content
EOF

    chmod +x "$DESKTOP_DIR/$name"
}

# --------------------------------------------------
# Calc
# --------------------------------------------------
write_desktop "Calc.desktop" "
[Desktop Entry]
Name=Calc Spreadsheet
Exec=libreoffice --calc
Icon=libreoffice-calc
Type=Application
Terminal=false
"

# --------------------------------------------------
# Windows VM (RDP)
# --------------------------------------------------
write_desktop "Windows-VM.desktop" "
[Desktop Entry]
Name=Windows VM (RDP)
Exec=remmina
Icon=org.remmina.Remmina
Type=Application
Terminal=false
"

# --------------------------------------------------
# Homarr Portal
# --------------------------------------------------
PORTAL_URL="${PORTAL_URL:-https://home.onyxnethq.site}"

write_desktop "Homarr-Portal.desktop" "
[Desktop Entry]
Name=Homarr Portal
Exec=chromium $PORTAL_URL
Icon=chromium
Type=Application
Terminal=false
"

# --------------------------------------------------
# SSH Terminal
# --------------------------------------------------
write_desktop "SSH-Terminal.desktop" "
[Desktop Entry]
Name=SSH Terminal
Exec=gnome-terminal
Icon=utilities-terminal
Type=Application
Terminal=false
"

# --------------------------------------------------
# Steam Link (optional)
# --------------------------------------------------
if [[ -x /usr/bin/steamlink ]]; then
write_desktop "SteamLink.desktop" "
[Desktop Entry]
Name=Steam Link
Exec=/usr/bin/steamlink %u
Icon=steamlink
Terminal=false
Type=Application
Categories=Game;
MimeType=x-scheme-handler/steamlink;
"
fi

# --------------------------------------------------
# FIX OWNERSHIP (THIS IS IMPORTANT)
# --------------------------------------------------
sudo chown -R "$REAL_USER:$REAL_USER" "$DESKTOP_DIR"

echo ""
echo "[✓] Desktop provisioning complete"
echo "[✓] User: $REAL_USER"
echo "[✓] No destructive operations performed"