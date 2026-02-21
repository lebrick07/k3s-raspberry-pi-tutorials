#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.21-2}"
NPM_PREFIX="${NPM_PREFIX:-$HOME/.npm-global}"
GATEWAY_MODE="${GATEWAY_MODE:-local}"  # local | remote

log() { echo -e "\n==> $*\n"; }

# ===== 0) Preflight =====
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Please run as a non-root user (e.g., ubuntu). This script uses sudo when needed."
  exit 1
fi

log "Updating apt and installing prerequisites"
sudo apt-get update -y
sudo apt-get install -y \
  curl ca-certificates gnupg \
  git build-essential python3 make g++ cmake \
  unzip

# ===== 1) Install Node.js 22.x (NodeSource) =====
log "Installing Node.js 22.x via NodeSource"
sudo apt-get remove -y nodejs >/dev/null 2>&1 || true
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

log "Verifying Node/NPM versions"
node -v
npm -v

# Enforce minimum node version (>=22.12.0)
node -e 'const [maj,min]=process.versions.node.split(".").map(Number); if (maj<22 || (maj===22 && min<12)) { console.error("Node must be >= 22.12.0. Current:", process.versions.node); process.exit(1);}'

# ===== 2) Configure user-global npm prefix =====
log "Configuring npm global prefix to $NPM_PREFIX (user-local)"
mkdir -p "$NPM_PREFIX/bin" "$NPM_PREFIX/lib/node_modules"
npm config set prefix "$NPM_PREFIX"
npm config set registry "https://registry.npmjs.org/"

# PATH for current session
export PATH="$NPM_PREFIX/bin:$PATH"
hash -r || true

# Persist PATH for both interactive shells (.bashrc) and login shells (.profile)
log "Persisting PATH in ~/.bashrc and ~/.profile"
PATH_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'
grep -qxF "$PATH_LINE" "$HOME/.bashrc" 2>/dev/null || echo "$PATH_LINE" >> "$HOME/.bashrc"
grep -qxF "$PATH_LINE" "$HOME/.profile" 2>/dev/null || echo "$PATH_LINE" >> "$HOME/.profile"

# Source now so this session is correct (harmless if already loaded)
# shellcheck disable=SC1090
source "$HOME/.bashrc" >/dev/null 2>&1 || true
hash -r || true

# ===== 3) Install OpenClaw (pin known-good version) =====
log "Installing OpenClaw @ ${OPENCLAW_VERSION}"
npm uninstall -g openclaw >/dev/null 2>&1 || true
npm install -g "openclaw@${OPENCLAW_VERSION}"

log "Verifying OpenClaw shim exists"
if [[ ! -e "$NPM_PREFIX/bin/openclaw" ]]; then
  echo "ERROR: openclaw shim not found at $NPM_PREFIX/bin/openclaw"
  echo "Contents of $NPM_PREFIX/bin:"
  ls -la "$NPM_PREFIX/bin" || true
  exit 1
fi

hash -r || true
openclaw --version

# ===== 4) Configure OpenClaw (setup + gateway mode) =====
log "Running OpenClaw setup (creates initial config)"
# If setup is already done, it should be safe to re-run; ignore non-zero if it exits early.
openclaw setup || true

log "Setting gateway.mode = $GATEWAY_MODE"
openclaw config set gateway.mode "$GATEWAY_MODE"

# ===== 5) Generate gateway token (non-interactive) =====
log "Generating and configuring a gateway token (non-interactive)"
# openclaw doctor prompts "Generate and configure a gateway token now?"
# We pipe "Yes" to accept. If doctor exits non-zero due to UI/cancel, don't fail the whole script.
printf "Yes\n" | openclaw doctor || true

log "Final verification"
openclaw doctor || true

cat <<'EOF'

✅ OpenClaw installed and configured.

Notes:
  - PATH persisted in ~/.bashrc and ~/.profile
  - gateway.mode set (local by default)
  - a gateway token was generated via openclaw doctor (if supported non-interactively)

Next:
  - Start gateway (local mode):  openclaw gateway start
  - If you chose remote mode, prefer SSH tunneling vs opening ports publicly.

EOF
