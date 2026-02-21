# OpenClaw Installation on AWS EC2 Ubuntu

**One-command setup for OpenClaw on a fresh Ubuntu EC2 instance.**

This guide provides a production-ready installation script for deploying OpenClaw on AWS EC2 instances running Ubuntu (tested on Ubuntu 22.04 LTS and 24.04 LTS).

---

## Prerequisites

- **EC2 Instance**: Ubuntu 22.04 LTS or 24.04 LTS (t2.micro or larger)
- **Security Group**: Port 22 (SSH) open to your IP
- **IAM Role** (optional): For AWS integrations
- **Non-root user**: The script must run as a regular user (e.g., `ubuntu`), not `root`

---

## Quick Start

SSH into your EC2 instance as the default `ubuntu` user:

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

Then run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-ec2.sh | bash
```

**That's it!** OpenClaw will be installed and ready to use.

---

## What the Script Does

1. **System Updates**: Updates `apt` and installs build prerequisites
2. **Node.js 22.x**: Installs the latest Node.js 22.x LTS via NodeSource
3. **User-Local npm**: Configures npm to install global packages without `sudo`
4. **OpenClaw Installation**: Installs OpenClaw from npm (pinned version: `2026.2.21-2`)
5. **PATH Configuration**: Adds `~/.npm-global/bin` to `~/.bashrc` for future sessions
6. **Verification**: Runs `openclaw doctor` to validate the installation

---

## Installation Script

Save this as `install-openclaw-ec2.sh` or copy-paste directly:

```bash
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

Initialize the workspace and start the gateway:

```bash
openclaw init
openclaw gateway start
```

Check gateway status:

```bash
openclaw gateway status
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

## Security Best Practices

### EC2 Security Group

- **SSH (22)**: Restrict to your IP only
- **No public ports**: OpenClaw runs locally; use SSH tunneling for remote access

### SSH Tunneling (Optional)

If you need to access OpenClaw gateway API remotely:

```bash
ssh -i your-key.pem -L 8080:localhost:8080 ubuntu@your-ec2-ip
```

Then access `http://localhost:8080` on your local machine.

### Environment Variables

Store sensitive data in environment variables, not config files:

```bash
export OPENCLAW_BOT_TOKEN="your_bot_token"
openclaw config set channels.telegram.botToken "$OPENCLAW_BOT_TOKEN"
```

---

## Troubleshooting

### Command not found: openclaw

Your PATH didn't refresh. Run:

```bash
source ~/.bashrc
```

Or log out and SSH back in.

### Permission denied during installation

Don't run the script as `root` or with `sudo`. Use the default `ubuntu` user:

```bash
# ❌ Wrong
sudo ./install-openclaw-ec2.sh

# ✅ Correct
./install-openclaw-ec2.sh
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

---

## Next Steps

- **Connect Telegram**: [Part 2: OpenClaw + Telegram Bot](./part2-openclaw-telegram.md)
- **Add Skills**: Explore OpenClaw skills and capabilities
- **Automate**: Set up systemd service for auto-start on boot
- **Integrate**: Connect to GitHub, AWS, or other services

---

## Repository

This guide is part of the **K3s + Raspberry Pi + OpenClaw Tutorial Series**:

- [Part 1: Raspberry Pi 5 + K3s + Hello World](./part1-k3s-hello-world.md)
- [Part 2: OpenClaw AI + Telegram Bot](./part2-openclaw-telegram.md)
- **EC2 Ubuntu OpenClaw Install** (this guide)

GitHub: [lebrick07/k3s-raspberry-pi-tutorials](https://github.com/lebrick07/k3s-raspberry-pi-tutorials)

---

## License

MIT License - see repository for details.

---

**Questions or issues?** Open an issue on [GitHub](https://github.com/lebrick07/k3s-raspberry-pi-tutorials/issues).
