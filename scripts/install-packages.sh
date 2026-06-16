#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

LOGFILE="/tmp/hml-install-packages.log"

APT_FLAGS=(
    -y
    -qq
    -o Dpkg::Use-Pty=0
    -o Acquire::Retries=3
    -o APT::Install-Recommends=false
)

# ============================
# LOGGING
# ============================

log() {
    echo "[packages] $1"
}

fail() {
    echo ""
    echo "[ERROR] $1"
    echo ""
    echo "----- LAST 40 LOG LINES -----"
    tail -40 "$LOGFILE" || true
    echo "-----------------------------"
    exit 1
}

# ============================
# WAIT FOR SYSTEM
# ============================

wait_for_system() {
    log "waiting for system initialization..."

    while [[ "$(systemctl is-system-running 2>/dev/null || true)" == "starting" ]]; do
        sleep 5
    done

    log "system initialization complete"
}

# ============================
# WAIT FOR APT LOCKS
# ============================

wait_for_apt() {
    log "waiting for apt/dpkg lock..."

    while \
        sudo lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo lsof /var/lib/dpkg/lock >/dev/null 2>&1 || \
        sudo lsof /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo lsof /var/cache/apt/archives/lock >/dev/null 2>&1
    do
        sleep 5
    done

    log "apt is available"
}

# ============================
# START
# ============================

: > "$LOGFILE"

wait_for_system
wait_for_apt

# ============================
# REPAIR PACKAGE STATE
# ============================

log "repairing package state..."

sudo dpkg --configure -a >>"$LOGFILE" 2>&1 || true
sudo apt-get install -f "${APT_FLAGS[@]}" >>"$LOGFILE" 2>&1 || true

wait_for_apt

# ============================
# UPDATE
# ============================

log "updating repositories..."

sudo apt-get update >>"$LOGFILE" 2>&1 \
    || fail "apt update failed"

wait_for_apt

# ============================
# UPGRADE
# ============================

log "upgrading installed packages..."

sudo apt-get upgrade "${APT_FLAGS[@]}" >>"$LOGFILE" 2>&1 \
    || fail "apt upgrade failed"

wait_for_apt

# ============================
# INSTALL
# ============================

log "installing workstation packages..."

sudo apt-get install "${APT_FLAGS[@]}" \
    libreoffice-calc \
    remmina \
    remmina-plugin-rdp \
    remmina-plugin-secret \
    remmina-plugin-vnc \
    chromium \
    lsb-release \
    git \
    curl \
    wget \
    tmux \
    htop \
    btop \
    openssh-server \
    gnome-terminal \
    papirus-icon-theme \
    lxappearance \
    network-manager \
    jq \
    waybar \
    wofi \
    unclutter \
    xterm \
    ca-certificates \
    gnupg \
    dbus-user-session \
    rclone \
    nextcloud-desktop \
    fuse3 \
    steam-installer \
    >>"$LOGFILE" 2>&1 \
    || fail "package installation failed"

wait_for_apt

# ============================
# VS Code Installation
# ============================

log "installing VS Code..."

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get update >>"$LOGFILE" 2>&1 \
    || fail "VS Code apt update failed"

sudo apt-get install "${APT_FLAGS[@]}" code >>"$LOGFILE" 2>&1 \
    || fail "VS Code installation failed"

wait_for_apt

# ============================
# CLEANUP
# ============================

log "cleaning up..."

sudo apt-get autoremove -y >>"$LOGFILE" 2>&1 || true
sudo apt-get autoclean -y >>"$LOGFILE" 2>&1 || true
sudo apt-get clean >>"$LOGFILE" 2>&1 || true

# ============================
# COMPLETE
# ============================

log "complete"