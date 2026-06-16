#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# Detect real user safely (LMDE-friendly)
# --------------------------------------------------
if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

REAL_HOME="$(eval echo "~$REAL_USER")"

WAYBAR_DIR="$REAL_HOME/.config/waybar"
AUTOSTART_DIR="$REAL_HOME/.config/autostart"

echo ""
echo "========================================="
echo " Waybar Setup (LMDE7 Cinnamon)"
echo "========================================="
echo "[*] User: $REAL_USER"
echo ""

mkdir -p "$WAYBAR_DIR"
mkdir -p "$AUTOSTART_DIR"

# --------------------------------------------------
# WAYBAR CONFIG
# --------------------------------------------------
cat > "$WAYBAR_DIR/config.jsonc" <<EOF
{
  "layer": "top",
  "position": "bottom",
  "height": 28,

  "modules-left": ["clock"],
  "modules-right": ["custom/tailscale"],

  "custom/tailscale": {
    "exec": "$WAYBAR_DIR/tailscale-status.sh",
    "interval": 5,
    "return-type": "json",
    "on-click": "$WAYBAR_DIR/tailscale-toggle.sh"
  },

  "clock": {
    "format": "{:%Y-%m-%d %H:%M}"
  }
}
EOF

# --------------------------------------------------
# WAYBAR STYLE
# --------------------------------------------------
cat > "$WAYBAR_DIR/style.css" <<'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: Sans;
    font-size: 12px;
    min-height: 0;
}

window#waybar {
    background: rgba(20, 20, 20, 0.92);
    color: #ffffff;
}

#clock {
    padding: 0 10px;
    margin: 2px 4px;
}

#custom-tailscale {
    padding: 0 10px;
    margin: 2px 4px;
    font-weight: bold;
}

#custom-tailscale.connected {
    color: #00ff88;
}

#custom-tailscale.disconnected {
    color: #ff5555;
}
EOF

# --------------------------------------------------
# TAILSCALE STATUS SCRIPT (LMDE-safe, no jq needed)
# --------------------------------------------------
cat > "$WAYBAR_DIR/tailscale-status.sh" <<'EOF'
#!/usr/bin/env bash

if ! command -v tailscale >/dev/null 2>&1; then
    echo '{"text":"Tailscale","class":"disconnected","tooltip":"Not installed"}'
    exit 0
fi

STATUS="$(tailscale status 2>/dev/null || true)"

if echo "$STATUS" | grep -qi "active"; then
    echo '{"text":"● Tailscale","class":"connected","tooltip":"Connected"}'
else
    echo '{"text":"● Tailscale","class":"disconnected","tooltip":"Disconnected"}'
fi
EOF

chmod +x "$WAYBAR_DIR/tailscale-status.sh"

# --------------------------------------------------
# TAILSCALE TOGGLE SCRIPT (LMDE Cinnamon safe)
# --------------------------------------------------
cat > "$WAYBAR_DIR/tailscale-toggle.sh" <<'EOF'
#!/usr/bin/env bash

if ! command -v tailscale >/dev/null 2>&1; then
    notify-send "Tailscale" "Not installed"
    exit 1
fi

# Prefer systemd (LMDE default)
if systemctl is-active --quiet tailscaled; then
    pkexec systemctl stop tailscaled
else
    pkexec systemctl start tailscaled
fi
EOF

chmod +x "$WAYBAR_DIR/tailscale-toggle.sh"

# --------------------------------------------------
# CINNAMON AUTOSTART
# --------------------------------------------------
cat > "$AUTOSTART_DIR/waybar.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Waybar
Exec=sh -c "sleep 2 && waybar"
X-GNOME-Autostart-enabled=true
NoDisplay=false
Comment=Start Waybar panel
EOF

# --------------------------------------------------
# FIX OWNERSHIP
# --------------------------------------------------
chown -R "$REAL_USER:$REAL_USER" "$WAYBAR_DIR" "$AUTOSTART_DIR"

echo ""
echo "[✓] Waybar configured successfully for LMDE7 Cinnamon"
echo ""
echo "NOTE:"
echo "- Waybar will start on login via Cinnamon autostart"
echo "- Tailscaled is controlled via systemd + pkexec"