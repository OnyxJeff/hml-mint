#!/usr/bin/env bash

set -euo pipefail

echo ""
echo "========================================="
echo " Installing Tailscale"
echo "========================================="

# --------------------------------------------------
# SKIP IF ALREADY INSTALLED
# --------------------------------------------------

if command -v tailscale >/dev/null 2>&1; then
    echo "[✓] Tailscale already installed"
else
    echo "[*] Installing Tailscale..."

    curl -fsSL https://tailscale.com/install.sh -o /tmp/tailscale-install.sh

    if [[ ! -s /tmp/tailscale-install.sh ]]; then
        echo "[✗] Failed to download installer"
        exit 1
    fi

    sh /tmp/tailscale-install.sh

    echo "[✓] Tailscale installed"
fi

# --------------------------------------------------
# SYSTEM SERVICE
# --------------------------------------------------

echo "[*] Enabling tailscaled service..."

sudo systemctl enable tailscaled >/dev/null 2>&1 || {
    echo "[!] Failed to enable service"
    exit 1
}

sudo systemctl start tailscaled >/dev/null 2>&1 || {
    echo "[!] Failed to start service"
    exit 1
}

echo ""
echo "[✓] Tailscale setup complete (run 'tailscale up' if needed)"