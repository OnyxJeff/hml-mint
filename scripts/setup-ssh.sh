#!/usr/bin/env bash
set -euo pipefail

echo
echo "========================================="
echo " Configuring Modular SSH"
echo "========================================="

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

SSH_DIR="$REAL_HOME/.ssh"
CONFIG_DIR="$SSH_DIR/config.d"
README_DIR="$REAL_HOME/Homelab-SSH"

mkdir -p "$SSH_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$README_DIR"

# --------------------------------------------------

# MAIN SSH CONFIG

# --------------------------------------------------

cat > "$SSH_DIR/config" <<'EOF'

# Homelab modular SSH configuration

Include config.d/*.conf
EOF

chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/config"

# --------------------------------------------------

# SSH KEYS

# --------------------------------------------------

KEYS_SOURCE="$REAL_HOME/hml-golden/ssh-config/keys"

if compgen -G "$KEYS_SOURCE/*" > /dev/null; then
    cp -f "$KEYS_SOURCE"/* "$SSH_DIR/"
    echo "[✓] SSH Keys copied"
else
    echo "[!] No keys found, skipping"
fi

# --------------------------------------------------

# COMPUTE NODES

# --------------------------------------------------

COMPUTE_SOURCE="$REAL_HOME/hml-golden/ssh-config/config/compute.conf"

if [[ -f "$COMPUTE_SOURCE" ]]; then
cp -f "$COMPUTE_SOURCE" "$CONFIG_DIR/compute.conf"
chmod 600 "$CONFIG_DIR/compute.conf"
echo "[✓] Installed compute.conf"
else
echo "[!] Missing compute.conf:"
echo "    $COMPUTE_SOURCE"
fi

# --------------------------------------------------

# README

# --------------------------------------------------

cat > "$README_DIR/README.txt" <<'EOF'
SSH Aliases Available:

Core:
ssh truenas
ssh aesir
ssh vanir

Compute:
ssh pp0
ssh pp1
ssh pp2
ssh pp3
ssh pp4
ssh pp5
ssh pp6
ssh workstation
EOF

# --------------------------------------------------

# OWNERSHIP

# --------------------------------------------------

if [[ "$(id -u)" -eq 0 ]]; then
chown -R "$REAL_USER:$REAL_USER" "$SSH_DIR"
chown -R "$REAL_USER:$REAL_USER" "$README_DIR"
fi

echo
echo "[✓] Modular SSH configuration installed."
echo "[i] Active SSH configs:"
find "$CONFIG_DIR" -name "*.conf" -type f
