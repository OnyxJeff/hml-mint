#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# =========================
# CI MODE (VALIDATION)
# =========================
if [[ "${1:-}" == "--ci-mode" ]]; then
    echo "[CI MODE] Validating scripts only"

    bash -n scripts/firstboot.sh
    bash -n scripts/install-packages.sh
    bash -n scripts/setup-theme.sh
    bash -n scripts/setup-waybar.sh

    echo "[CI MODE] Syntax OK"
    exit 0
fi

# ============================
# CONFIG
# ============================

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"
REPO_URL="https://github.com/OnyxJeff/hml-mint.git"
REPO_NAME="hml-mint"
BASE_DIR="$REAL_HOME"
LOG_FILE="$REAL_HOME/hml-mint-bootstrap.log"

# Prevent Git credential prompts (IMPORTANT)
export GIT_TERMINAL_PROMPT=0

# Requesting sudo upfront (for better UX later)
if [[ $EUID -ne 0 ]]; then
    echo "Requesting sudo for full bootstrap execution..."
    exec sudo -E bash "$0" "$@"
fi

# keep sudo alive during script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ============================
# LOGGING
# ============================

exec > >(tee -a "$LOG_FILE") 2>&1

# ============================
# COLORS
# ============================

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

# ============================
# UI HELPERS
# ============================

TOTAL_STEPS=6
CURRENT_STEP=0

section() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${CYAN}[ $1 ]${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[ ${CURRENT_STEP} / ${TOTAL_STEPS} ]${NC} → $1"
}

ok() {
    echo -e "${GREEN}✔${NC} $1"
}

err() {
    echo -e "${RED}✖${NC} $1"
}

pause() {
    sleep 0.5
}

# ============================
# SPINNER (hardened)
# ============================

spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    echo -ne "${CYAN}$msg${NC} "

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 9); do
            printf "\b%s" "${spin:$i:1}"
            sleep 0.1
        done
    done

    printf "\b"
    echo -e "${GREEN}✔${NC}"
}

run_with_spinner() {
    local msg=$1
    shift

    # HARDENED: silence EVERYTHING
    "$@" > /dev/null 2>&1 &
    local pid=$!

    spinner "$pid" "$msg"
    wait "$pid"
}

# ============================
# START
# ============================

section "HML-MINT BOOTSTRAP"

echo -e "${CYAN}Log file:${NC} $LOG_FILE"
pause

# ============================
# STEP 1 - DEPENDENCIES
# ============================

section "SYSTEM CHECKS"

step "Checking dependencies"

# Single silent apt update (avoid spam)
run_with_spinner "Refreshing package index " bash -c '
    sudo apt-get update -qq
'

command -v git >/dev/null 2>&1 || {
    run_with_spinner "Installing git" bash -c '
        sudo apt-get install -y -qq git
    '
}

command -v curl >/dev/null 2>&1 || {
    run_with_spinner "Installing curl" bash -c '
        sudo apt-get install -y -qq curl
    '
}

sleep 2
ok "Dependencies ready"

# ============================
# STEP 2 - REPO SETUP
# ============================

section "REPOSITORY SETUP"

cd "$BASE_DIR"

step "Checking repository access"

if ! git ls-remote "$REPO_URL" >/dev/null 2>&1; then
    err "Cannot access repo: $REPO_URL"
    err "Likely: private repo, wrong URL, or missing access"
    exit 1
fi

step "Cloning repository"

if [ ! -d "$REPO_NAME" ]; then
    run_with_spinner "Cloning repository " git clone --depth 1 "$REPO_URL"
else
    step "Updating repository"
    cd "$REPO_NAME"
    run_with_spinner "Pulling latest changes " git pull --ff-only
    cd "$BASE_DIR"
fi

cd "$BASE_DIR/$REPO_NAME"

sleep 2
ok "Repository ready"

# ============================
# STEP 3 - VALIDATION
# ============================

section "VALIDATION"

step "Checking project structure"

if [ ! -f "scripts/firstboot.sh" ]; then
    err "Missing scripts/firstboot.sh"
    exit 1
fi

sleep 2
ok "Structure valid"

# ============================
# STEP 4 - FIRSTBOOT
# ============================

section "SYSTEM CONFIGURATION"

step "Running firstboot configuration"

FIRSTBOOT_LOG="$HOME/firstboot.log"

# Run firstboot directly (no spinner, no subshell)
bash scripts/firstboot.sh 2>&1 | tee "$FIRSTBOOT_LOG"
rc=${PIPESTATUS[0]}

if [[ $rc -ne 0 ]]; then
    err "firstboot.sh failed (exit $rc)"
    exit $rc
fi

sleep 2
ok "System configuration complete"

# ============================
# STEP 5 - REPO OWNERSHIP
# ============================

chmod 700 "$REAL_HOME/$REPO_NAME"

# ============================
# FINISH
# ============================

sleep 2
section "COMPLETE"

sleep 2
echo ""
echo -e "${GREEN}✔ Bootstrap finished successfully${NC}"
echo -e "${CYAN}✔ Log:${NC} $LOG_FILE"
echo ""
sleep 2
echo "Recommended next steps:"
sleep 1
echo "  1. Review the log file for any issues."
sleep 0.5
echo "  2. run: sudo tailscale set --operator=$REAL_USER"
sleep 0.5
echo "  3. run: tailscale up"
sleep 0.5
echo "  4. Authenticate to your tailnet"
sleep 0.5
echo "  5. Make sure to assign your exit node in Tailscale settings."
sleep 0.5
echo "  6. Reboot the system to apply all changes."
sleep 0.5
echo "  7. Enjoy your new Pi workstation!"
echo ""