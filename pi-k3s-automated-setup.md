# Automated Raspberry Pi K3s Setup

**One-command setup from fresh Raspberry Pi OS to production-ready K3s cluster.**

This guide automates **Part 1: Raspberry Pi 5 + K3s + Hello World** with a single script. Perfect for quickly setting up multiple Pi nodes or recreating your environment.

---

## What This Script Does

Automates the entire manual setup from [Part 1](./part1-k3s-hello-world.md):

### Phase 1: System Update
- Updates all system packages
- Upgrades existing packages

### Phase 2: Essential Tools Installation
- **Docker** (latest stable)
- **Node.js LTS** (via NodeSource)
- **Python3** and pip
- **AWS CLI** (ARM64 build)
- **Terraform** (ARM64 build)
- Git, curl, wget, unzip

### Phase 3: Swap Configuration
- Disables swap immediately
- Disables swap permanently (dphys-swapfile)
- Verifies swap is disabled

### Phase 4: cgroups Configuration
- Backs up `/boot/firmware/cmdline.txt`
- Adds cgroup parameters for K3s
- Handles both new (`/boot/firmware/`) and old (`/boot/`) paths

### Phase 5: K3s Preparation
- Creates post-reboot installation script
- Prepares kubectl configuration

### Phase 6: Reboot
- Prompts for reboot (required for cgroups + Docker group)

### Phase 7: K3s Installation (after reboot)
- Installs K3s via official script
- Configures kubectl for non-root user
- Verifies cluster is operational

**Total time**: ~15 minutes (10 min setup + reboot + 5 min K3s install)

---

## Prerequisites

### Hardware
- Raspberry Pi 4 (4GB+ RAM) or Raspberry Pi 5 (8GB+ recommended)
- MicroSD card with Raspberry Pi OS 64-bit installed
- Stable internet connection

### Software
- **Raspberry Pi OS 64-bit** (Bookworm or later)
- **SSH access** configured during imaging
- **User account** created (default: `pi` or `user`)

### Before Running the Script

Use **Raspberry Pi Imager** to flash your SD card:

1. **Download Raspberry Pi Imager**: https://www.raspberrypi.com/software/
2. **Flash SD card**:
   - Device: Raspberry Pi 5 (or Pi 4)
   - OS: Raspberry Pi OS (64-bit)
   - Storage: Your SD card
3. **Configure settings** (⚙️ icon):
   - ✅ Enable SSH (with password or key)
   - Set hostname: `pi5-node-0` (or your preference)
   - Username: `user` (or `pi`)
   - Password: (choose strong password)
   - ✅ Configure WiFi (SSID + password)
   - Set locale (timezone, keyboard)
4. **Write** and wait for completion
5. **Boot your Pi** and wait 1-2 minutes

---

## Quick Start

### Step 1: SSH into your Pi

```bash
ssh user@pi5-node-0.local
# or
ssh user@<pi-ip-address>
```

### Step 2: Run the setup script

```bash
curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/setup-k3s-pi.sh | bash
```

The script will:
1. Prompt for confirmation
2. Install all tools and configure system
3. Ask if you want to reboot now

### Step 3: Reboot

When prompted, press `y` to reboot immediately:

```
Reboot now? (y/N) y
```

Or reboot manually later:

```bash
sudo reboot
```

### Step 4: Complete K3s installation (after reboot)

Wait 1-2 minutes after reboot, then SSH back in:

```bash
ssh user@pi5-node-0.local
```

Run the post-reboot script:

```bash
~/install-k3s-post-reboot.sh
```

This will:
- Install K3s
- Configure kubectl
- Verify cluster is ready

**Done!** Your K3s cluster is operational.

---

## Verification

Check your cluster:

```bash
kubectl get nodes
```

Expected output:
```
NAME          STATUS   ROLES                  AGE   VERSION
pi5-node-0    Ready    control-plane,master   30s   v1.34.4+k3s1
```

Check installed tools:

```bash
docker --version
node --version
python3 --version
aws --version
terraform --version
kubectl version --short
```

---

## Configuration Options

### Custom Terraform Version

```bash
TERRAFORM_VERSION=1.8.0 curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/setup-k3s-pi.sh | bash
```

### Skip Reboot Prompt

The script will ask before rebooting. To automate:

1. Run the script
2. When prompted "Reboot now? (y/N)", press `N`
3. Reboot manually when ready: `sudo reboot`
4. SSH back in and run `~/install-k3s-post-reboot.sh`

---

## What to Do After Setup

### 1. Deploy Your First App

Follow the [Part 1 tutorial](./part1-k3s-hello-world.md#step-4-build-a-hello-world-app) to build and deploy a Hello World Flask app.

Quick version:

```bash
# Create and deploy nginx
kubectl create deployment hello --image=nginx
kubectl expose deployment hello --type=NodePort --port=80

# Get the NodePort
kubectl get svc hello
# Note the port (e.g., 80:31234/TCP)

# Get your Pi's IP
hostname -I | awk '{print $1}'

# Access in browser: http://<pi-ip>:<nodeport>
```

### 2. Install OpenClaw AI Assistant

Manage your K3s cluster via Telegram:

```bash
curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/install-openclaw-pi.sh | bash
```

See [Part 2: OpenClaw + Telegram Bot](./part2-openclaw-telegram.md) for full setup.

### 3. Deploy ArgoCD for GitOps

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 4. Set Up Persistent Storage

K3s includes local-path provisioner by default:

```bash
kubectl get storageclass
# You'll see: local-path (default)
```

Create a PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### 5. Enable HTTPS with cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

---

## Manual Installation Alternative

If you prefer manual step-by-step installation, follow the full tutorial:

**[Part 1: Raspberry Pi 5 + K3s + Hello World](./part1-k3s-hello-world.md)**

The manual approach gives you more control and understanding of each step.

---

## Troubleshooting

### Script fails during Docker installation

**Error**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**: This is expected. The script adds your user to the `docker` group, but you need to log out and back in (or reboot) for it to take effect. The reboot step handles this automatically.

### K3s fails to install after reboot

**Error**: `kubectl: command not found`

**Solution**: Make sure you ran the post-reboot script:

```bash
~/install-k3s-post-reboot.sh
```

If the script is missing, re-run the main setup script (it's idempotent).

### "cgroup" errors in K3s logs

**Check cmdline.txt**:

```bash
cat /boot/firmware/cmdline.txt
```

Should contain:
```
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

If missing, add manually:

```bash
sudo nano /boot/firmware/cmdline.txt
# Add the parameters to the END of the existing line (do not create new line!)
# Save and reboot
sudo reboot
```

### Swap still enabled

Verify swap is disabled:

```bash
sudo swapon --show  # Should show nothing
free -h             # Swap line should show 0
```

If swap is still on:

```bash
sudo swapoff -a
sudo systemctl disable dphys-swapfile
sudo reboot
```

### Node shows "NotReady"

Wait 1-2 minutes for CoreDNS and other components to start. Then check:

```bash
kubectl get pods -n kube-system
```

All pods should be Running. If not:

```bash
sudo systemctl restart k3s
kubectl get nodes --watch
```

### Out of memory during installation

If you're running on Pi 4 with 4GB or less:

1. Close other applications
2. Increase swap temporarily:

```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

3. Run the script
4. Disable swap again after K3s is installed

---

## Uninstalling

### Uninstall K3s

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

### Remove all installed tools

```bash
# Docker
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker

# Node.js
sudo apt-get remove -y nodejs

# AWS CLI
sudo rm /usr/local/bin/aws
sudo rm -rf /usr/local/aws-cli

# Terraform
sudo rm /usr/local/bin/terraform

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean
```

---

## Script Source Code

The setup script is open source and available at:

**https://github.com/lebrick07/k3s-raspberry-pi-tutorials/blob/main/scripts/setup-k3s-pi.sh**

Review the code before running (recommended for security):

```bash
curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/setup-k3s-pi.sh
```

---

## Next Steps

- **Install OpenClaw**: [Raspberry Pi OpenClaw Installation](./pi-openclaw-install.md)
- **Telegram Bot**: [Part 2: OpenClaw + Telegram Bot](./part2-openclaw-telegram.md)
- **Multi-Tenant Platform**: [Part 3: Multi-Tenant DevOps AI Platform](./README.md)
- **Manual Tutorial**: [Part 1: Full Step-by-Step Guide](./part1-k3s-hello-world.md)

---

## Repository

This guide is part of the **K3s + Raspberry Pi + OpenClaw Tutorial Series**:

GitHub: [lebrick07/k3s-raspberry-pi-tutorials](https://github.com/lebrick07/k3s-raspberry-pi-tutorials)

---

## License

MIT License - see repository for details.

---

**Questions or issues?** Open an issue on [GitHub](https://github.com/lebrick07/k3s-raspberry-pi-tutorials/issues).
