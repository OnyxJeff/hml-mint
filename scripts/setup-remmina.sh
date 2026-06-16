#!/usr/bin/env bash

set -euo pipefail

echo ""
echo "========================================="
echo " Setting up Remmina RDP Profiles"
echo "========================================="

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

mkdir -p "$REAL_HOME/.local/share/remmina"
mkdir -p "$REAL_HOME/Desktop"

# --------------------------------------------------
# SimulationCraft VM
# --------------------------------------------------

echo "copying Remmina profile for SimulationCraft VM..."
cp -rv $REAL_HOME/hml-golden/remmina-profiles/. $REAL_HOME/.local/share/remmina/

# --------------------------------------------------
# Fixing Ownership
# --------------------------------------------------

sudo chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"
sudo chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local"

# --------------------------------------------------
# Done
# --------------------------------------------------

echo ""
echo "[✓] Remmina profiles installed."