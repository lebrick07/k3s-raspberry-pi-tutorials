# OpenClaw Installation on Raspberry Pi

**One-command setup for OpenClaw on Raspberry Pi OS (64-bit).**

This guide provides a production-ready installation script for deploying OpenClaw on Raspberry Pi devices running Raspberry Pi OS 64-bit (tested on Raspberry Pi 4 and Raspberry Pi 5).

---

## Prerequisites

- **Raspberry Pi**: Pi 4 (4GB+ RAM) or Pi 5 (8GB+ recommended)
- **OS**: Raspberry Pi OS 64-bit (Bookworm or later)
- **SSH Access**: Enabled via `raspi-config` or SD card setup
- **Internet**: WiFi or Ethernet connection
- **User**: Default `pi` user (or any non-root user)

---

## Quick Start

SSH into your Raspberry Pi:

```bash
ssh pi@raspberrypi.local
# or
ssh pi@<pi-ip-address>
```

Then run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-pi.sh | bash
```

**That's it!** OpenClaw will be installed and ready to use.

---

## What the Script Does

1. **System Updates**: Updates `apt` and installs build prerequisites
2. **Architecture Check**: Verifies ARM64 (aarch64) architecture
3. **Node.js 22.x**: Installs Node.js 22.x LTS via NodeSource (ARM64 binaries)
4. **User-Local npm**: Configures npm to install global packages without `sudo`
5. **OpenClaw Installation**: Installs OpenClaw from npm (pinned version: `2026.2.21-2`)
6. **PATH Configuration**: Adds `~/.npm-global/bin` to both `~/.bashrc` and `~/.profile`
7. **OpenClaw Setup**: Runs `openclaw setup` to create initial configuration
8. **Gateway Mode**: Sets gateway mode to `local` by default (configurable via `GATEWAY_MODE` env var)
9. **Gateway Token**: Generates and configures a gateway token non-interactively
10. **Verification**: Runs `openclaw doctor` to validate the installation

---

## Configuration Options

The installation script supports environment variables for customization:

### Gateway Mode

By default, the script configures OpenClaw in `local` mode (listens on `localhost` only). To configure remote mode:

```bash
GATEWAY_MODE=remote curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-pi.sh | bash
```

**Modes:**
- `local` (default): Gateway listens on `localhost` only (most secure)
- `remote`: Gateway listens on all interfaces (requires firewall rules)

**Security note**: For remote access from your laptop/phone, prefer SSH tunneling or the Telegram bot integration.

### OpenClaw Version

Pin a specific version:

```bash
OPENCLAW_VERSION=2026.2.21-2 curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-pi.sh | bash
```

### npm Prefix

Change the installation directory:

```bash
NPM_PREFIX=/opt/openclaw curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-pi.sh | bash
```

---

## Installation Script

Save this as `install-openclaw-pi.sh` or copy-paste directly:

```bash
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
log "Installing Node.js 22.x via NodeSource (ARM64 support included)"
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

✅ OpenClaw installed and configured on Raspberry Pi.

Notes:
  - PATH persisted in ~/.bashrc and ~/.profile
  - gateway.mode set (local by default)
  - a gateway token was generated via openclaw doctor (if supported non-interactively)

Next:
  - Start gateway (local mode):  openclaw gateway start
  - Check status:                 openclaw gateway status
  - View logs:                    openclaw gateway logs

Raspberry Pi specific tips:
  - For K3s integration, see: https://github.com/lebrick07/k3s-raspberry-pi-tutorials
  - Consider setting up as a systemd service for auto-start on boot
  - Monitor CPU temperature: vcgencmd measure_temp

EOF
```

---

## Verifying the Installation

After the script completes, refresh your current shell:

```bash
source ~/.bashrc
```

Check OpenClaw is installed:

```bash
openclaw --version
# Expected: 2026.2.21-2

openclaw doctor
# Should show all green checks
```

---

## Starting OpenClaw Gateway

The installation script already ran `openclaw setup` and generated a gateway token. Simply start the gateway:

```bash
openclaw gateway start
```

Check gateway status:

```bash
openclaw gateway status
```

View gateway logs:

```bash
openclaw gateway logs
```

---

## Connecting Telegram Bot

Follow the Telegram bot setup from [Part 2: OpenClaw + Telegram Bot](./part2-openclaw-telegram.md).

Quick steps:

1. Create bot via [@BotFather](https://t.me/BotFather)
2. Get your Telegram user ID: [@userinfobot](https://t.me/userinfobot)
3. Configure OpenClaw:

```bash
openclaw config set channels.telegram.botToken "YOUR_BOT_TOKEN"
openclaw config set channels.telegram.allowedUsers "[YOUR_USER_ID]"
openclaw gateway restart
```

4. Send `/start` to your bot on Telegram

---

## Raspberry Pi Specific Configuration

### Auto-Start on Boot (systemd service)

Create a systemd service to start OpenClaw gateway automatically:

```bash
sudo nano /etc/systemd/system/openclaw-gateway.service
```

Paste this content:

```ini
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
Environment="PATH=/home/pi/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/pi/.npm-global/bin/openclaw gateway start --foreground
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl start openclaw-gateway
```

Check status:

```bash
sudo systemctl status openclaw-gateway
```

View logs:

```bash
sudo journalctl -u openclaw-gateway -f
```

### Performance Monitoring

Monitor CPU temperature (important for passive cooling):

```bash
vcgencmd measure_temp
```

Monitor CPU frequency:

```bash
vcgencmd measure_clock arm
```

Check throttling status:

```bash
vcgencmd get_throttled
```

### K3s Integration

If you're running K3s on your Pi (see [Part 1](./part1-k3s-hello-world.md)), OpenClaw can manage your cluster:

```bash
# Check cluster status
openclaw exec "kubectl get nodes"

# Deploy applications
openclaw exec "kubectl apply -f deployment.yaml"

# View pod logs
openclaw exec "kubectl logs -f pod-name"
```

---

## Hardware Recommendations

### Raspberry Pi 5 (Recommended)
- **16GB RAM**: $205
- **Power Supply (27W)**: $12
- **512GB MicroSD**: $70
- **Cooling**: Aluminum passive case ($20) or active fan ($8)
- **Total**: ~$307

### Raspberry Pi 4 (Budget)
- **8GB RAM**: $75
- **Power Supply**: $8
- **256GB MicroSD**: $35
- **Cooling**: Heatsink kit ($8)
- **Total**: ~$126

### Storage Considerations

For production workloads, consider:
- **USB 3.0 SSD**: Faster than MicroSD, more reliable
- **NVMe Hat** (Pi 5): Native NVMe support, best performance

---

## Troubleshooting

### Command not found: openclaw

Your PATH didn't refresh. Run:

```bash
source ~/.bashrc
```

Or log out and SSH back in.

### Permission denied during installation

Don't run the script as `root` or with `sudo`. Use the default `pi` user:

```bash
# ❌ Wrong
sudo ./install-openclaw-pi.sh

# ✅ Correct
./install-openclaw-pi.sh
```

### Node.js version too old

The script installs Node.js 22.x. If you see errors, ensure no older Node.js version is interfering:

```bash
which node
node -v

# Should be 22.12.0 or higher
```

### Gateway won't start

Check logs:

```bash
openclaw gateway logs
```

Restart gateway:

```bash
openclaw gateway restart
```

### Architecture warnings

If you see "WARNING: This script is optimized for ARM64", check your OS:

```bash
uname -m
# Should show: aarch64 or arm64
```

If it shows `armv7l`, you're running 32-bit Raspberry Pi OS. Install the 64-bit version for better performance.

### Out of memory errors

Raspberry Pi 4 with 4GB or less may struggle with large npm packages. Consider:
- Upgrading to 8GB model
- Using Raspberry Pi 5 with 16GB
- Increasing swap size temporarily:

```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## Upgrading OpenClaw

To upgrade to a newer version:

```bash
npm install -g openclaw@latest
openclaw gateway restart
```

Or pin a specific version:

```bash
npm install -g openclaw@2026.2.21-2
```

If using systemd service:

```bash
npm install -g openclaw@latest
sudo systemctl restart openclaw-gateway
```

---

## Next Steps

- **K3s Setup**: [Part 1: Raspberry Pi 5 + K3s + Hello World](./part1-k3s-hello-world.md)
- **Connect Telegram**: [Part 2: OpenClaw + Telegram Bot](./part2-openclaw-telegram.md)
- **Add Skills**: Explore OpenClaw skills and capabilities
- **Multi-Tenant Platform**: [Part 3: Multi-Tenant DevOps AI Platform](./README.md)
- **Systemd Service**: Auto-start OpenClaw on boot (see above)

---

## Repository

This guide is part of the **K3s + Raspberry Pi + OpenClaw Tutorial Series**:

- [Part 1: Raspberry Pi 5 + K3s + Hello World](./part1-k3s-hello-world.md)
- [Part 2: OpenClaw AI + Telegram Bot](./part2-openclaw-telegram.md)
- **Raspberry Pi OpenClaw Install** (this guide)
- [EC2 Ubuntu: OpenClaw Installation](./ec2-ubuntu-openclaw-install.md)

GitHub: [lebrick07/k3s-raspberry-pi-tutorials](https://github.com/lebrick07/k3s-raspberry-pi-tutorials)

---

## License

MIT License - see repository for details.

---

**Questions or issues?** Open an issue on [GitHub](https://github.com/lebrick07/k3s-raspberry-pi-tutorials/issues).
