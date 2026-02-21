#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.21-2}"
NPM_PREFIX="${NPM_PREFIX:-$HOME/.npm-global}"
GATEWAY_MODE="${GATEWAY_MODE:-local}"  # local | remote

log() { echo -e "\n==> $*\n"; }

# ===== 0) Preflight =====
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Please run as a non-root user (e.g., pi). This script uses sudo when needed."
  exit 1
fi

# Verify ARM64 architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "WARNING: This script is optimized for ARM64 (aarch64). Detected: $ARCH"
  echo "Continuing anyway, but Node.js installation may differ..."
fi

log "Updating apt and installing prerequisites"
sudo apt-get update -y
sudo apt-get install -y \
  curl ca-certificates gnupg \
  git build-essential python3 make g++ cmake \
  unzip

# ===== 1) Install Node.js 22.x (NodeSource) =====
log "Ensuring Node.js >= 22.12.0 is installed"
NEED_NODE=1
if command -v node >/dev/null 2>&1; then
  if node -e 'const [maj,min]=process.versions.node.split(".").map(Number); process.exit((maj>22 || (maj===22 && min>=12))?0:1)'; then
    NEED_NODE=0
  fi
fi

if [[ "$NEED_NODE" -eq 1 ]]; then
  log "Installing Node.js 22.x via NodeSource (ARM64 support included)"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

log "Verifying Node/NPM versions"
node -v
npm -v

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
openclaw setup --yes || true

log "Setting gateway.mode = $GATEWAY_MODE"
openclaw config set gateway.mode "$GATEWAY_MODE"

# Recommended auth default
log "Setting gateway auth mode = token"
openclaw config set gateway.auth.mode token || true

# ===== 5) Generate gateway token (prefer non-interactive command) =====
log "Generating and configuring a gateway token"
if openclaw devices token --help >/dev/null 2>&1; then
  # Newer OpenClaw builds have explicit token commands
  openclaw devices token generate --name "pi-$(hostname)" --set-default || true
else
  # Fallback: doctor prompt (best-effort)
  printf "Yes\n" | openclaw doctor || true
fi

log "Final verification"
openclaw doctor || true

cat <<'EOF'

✅ OpenClaw installed and configured on Raspberry Pi.

Next:
  - Start gateway (local mode):  openclaw gateway
                                 (or: openclaw gateway start)
  - Check status:                openclaw gateway status
  - View logs:                   openclaw gateway logs

Raspberry Pi specific tips:
  - For K3s integration, see: https://github.com/lebrick07/k3s-raspberry-pi-tutorials
  - Consider setting up as a systemd service for auto-start on boot
  - Monitor CPU temperature: vcgencmd measure_temp

Tip: If 'openclaw' isn't found in a NEW SSH session:
  source ~/.profile
  source ~/.bashrc

EOF
