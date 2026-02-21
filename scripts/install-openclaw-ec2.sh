#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.21-2}"
NPM_PREFIX="${NPM_PREFIX:-$HOME/.npm-global}"

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
# remove older apt-provided nodejs if present (won't error if not installed)
sudo apt-get remove -y nodejs >/dev/null 2>&1 || true
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

log "Verifying Node/NPM versions"
node -v
npm -v

# Enforce minimum node version (>=22.12.0)
node -e 'const [maj,min]=process.versions.node.split(".").map(Number); if (maj<22 || (maj===22 && min<12)) { console.error("Node must be >= 22.12.0. Current:", process.versions.node); process.exit(1);}'

# ===== 2) Configure user-global npm prefix =====
log "Configuring npm global prefix to $NPM_PREFIX (user-local, no sudo installs)"
mkdir -p "$NPM_PREFIX/bin" "$NPM_PREFIX/lib/node_modules"
npm config set prefix "$NPM_PREFIX"
npm config set registry "https://registry.npmjs.org/"

# PATH for current session
export PATH="$NPM_PREFIX/bin:$PATH"
hash -r || true

# Make PATH persistent for future SSH sessions
log "Persisting PATH in ~/.bashrc"
if ! grep -q 'export PATH="\$HOME/.npm-global/bin:\$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
fi

# ===== 3) Install OpenClaw (pin the known-good version) =====
log "Installing OpenClaw @ ${OPENCLAW_VERSION}"
# ensure any placeholder package is removed
npm uninstall -g openclaw >/dev/null 2>&1 || true
npm install -g "openclaw@${OPENCLAW_VERSION}"

log "Verifying OpenClaw binary exists"
if [[ ! -x "$NPM_PREFIX/bin/openclaw" && ! -L "$NPM_PREFIX/bin/openclaw" ]]; then
  echo "ERROR: openclaw shim not found at $NPM_PREFIX/bin/openclaw"
  echo "Contents of $NPM_PREFIX/bin:"
  ls -la "$NPM_PREFIX/bin" || true
  exit 1
fi

hash -r || true
openclaw --version

# ===== 4) Run doctor (optional but helpful) =====
log "Running: openclaw doctor"
openclaw doctor || true

log "DONE. OpenClaw is installed. New SSH sessions will have PATH set via ~/.bashrc"
echo "Tip: If you're in the same shell and PATH didn't refresh, run: source ~/.bashrc"
