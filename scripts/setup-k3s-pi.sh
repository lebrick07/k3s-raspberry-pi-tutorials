#!/usr/bin/env bash
set -euo pipefail

# ===== Raspberry Pi K3s Setup Script =====
# Automates Part 1: Raspberry Pi 5 + K3s + Hello World
# From SSH login to production-ready K3s cluster
#
# Prerequisites:
#   - Raspberry Pi OS 64-bit installed
#   - SSH access configured
#   - Internet connection (WiFi or Ethernet)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lebrick07/k3s-raspberry-pi-tutorials/main/scripts/setup-k3s-pi.sh | bash

# ===== Config =====
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.7.0}"
DEPLOY_HELLO_APP="${DEPLOY_HELLO_APP:-false}"  # Set to 'true' to deploy demo app

log() { echo -e "\n==> $*\n"; }

# ===== 0) Preflight =====
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Please run as a non-root user (e.g., pi or user). This script uses sudo when needed."
  exit 1
fi

# Verify ARM64 architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "ERROR: This script requires ARM64 architecture. Detected: $ARCH"
  echo "Please install Raspberry Pi OS 64-bit."
  exit 1
fi

log "Raspberry Pi K3s Setup - Part 1: System Preparation"
echo "This script will:"
echo "  1. Update system packages"
echo "  2. Install essential tools (Docker, Node.js, Python, AWS CLI, Terraform)"
echo "  3. Configure system for K3s (disable swap, enable cgroups)"
echo "  4. Reboot (required)"
echo "  5. Install K3s and configure kubectl"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ===== Phase 1: System Update =====
log "Phase 1/7: Updating system packages"
sudo apt-get update -y
sudo apt-get upgrade -y

# ===== Phase 2: Install Essential Tools =====
log "Phase 2/7: Installing essential tools"

# Git, curl, wget, unzip
sudo apt-get install -y git curl wget unzip

# Docker
log "Installing Docker"
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  rm /tmp/get-docker.sh
  sudo usermod -aG docker "$USER"
  log "Docker installed. You'll need to log out and back in for group changes to take effect."
else
  log "Docker already installed"
fi

# Node.js LTS
log "Installing Node.js LTS"
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  log "Node.js already installed ($(node --version))"
fi

# Python3 and pip
log "Installing Python3 and pip"
sudo apt-get install -y python3 python3-pip python3-venv

# AWS CLI
log "Installing AWS CLI (ARM64)"
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
else
  log "AWS CLI already installed ($(aws --version))"
fi

# Terraform
log "Installing Terraform ${TERRAFORM_VERSION} (ARM64)"
if ! command -v terraform &> /dev/null; then
  wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip" -O /tmp/terraform.zip
  unzip -q /tmp/terraform.zip -d /tmp/
  sudo mv /tmp/terraform /usr/local/bin/
  rm /tmp/terraform.zip
  sudo chmod +x /usr/local/bin/terraform
else
  log "Terraform already installed ($(terraform --version | head -1))"
fi

# ===== Phase 3: Disable Swap =====
log "Phase 3/7: Disabling swap (required for K3s)"
sudo swapoff -a || true
sudo dphys-swapfile swapoff || true
sudo dphys-swapfile uninstall || true
sudo systemctl disable dphys-swapfile || true

# Verify swap is disabled
if [[ $(swapon --show | wc -l) -eq 0 ]]; then
  log "Swap disabled successfully"
else
  log "WARNING: Swap is still enabled. K3s may not work correctly."
fi

# ===== Phase 4: Enable cgroups =====
log "Phase 4/7: Enabling cgroups (required for K3s)"

CMDLINE_FILE="/boot/firmware/cmdline.txt"
if [[ ! -f "$CMDLINE_FILE" ]]; then
  # Try alternative path for older Pi OS versions
  CMDLINE_FILE="/boot/cmdline.txt"
fi

if [[ -f "$CMDLINE_FILE" ]]; then
  # Backup original
  sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup"
  
  # Check if cgroups already enabled
  if grep -q "cgroup_enable=cpuset" "$CMDLINE_FILE"; then
    log "cgroups already enabled"
  else
    log "Adding cgroup parameters to $CMDLINE_FILE"
    sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' "$CMDLINE_FILE"
    log "cgroups enabled (reboot required)"
  fi
else
  log "WARNING: Could not find cmdline.txt. Skipping cgroup configuration."
fi

# ===== Phase 5: Prepare for K3s Installation =====
log "Phase 5/7: Creating K3s installation script for after reboot"

# Create a script that will run after reboot to install K3s
cat > /tmp/install-k3s-post-reboot.sh << 'EOFSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n==> $*\n"; }

log "Installing K3s"
if command -v k3s &> /dev/null; then
  log "K3s already installed ($(k3s --version | head -1))"
else
  curl -sfL https://get.k3s.io | sh -
  log "K3s installed successfully"
fi

log "Waiting for K3s to be ready"
sleep 10
sudo systemctl status k3s --no-pager || true

log "Configuring kubectl for non-root user"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config

log "Verifying K3s cluster"
kubectl get nodes

log "K3s installation complete!"
echo ""
echo "Your Kubernetes cluster is ready."
echo ""
echo "Next steps:"
echo "  - Deploy applications: kubectl create deployment hello --image=nginx"
echo "  - View cluster info: kubectl cluster-info"
echo "  - List all resources: kubectl get all --all-namespaces"
echo ""
echo "For the full Hello World tutorial, see:"
echo "  https://github.com/lebrick07/k3s-raspberry-pi-tutorials/blob/main/part1-k3s-hello-world.md"
echo ""

# Cleanup this script
rm -f ~/install-k3s-post-reboot.sh

EOFSCRIPT

chmod +x /tmp/install-k3s-post-reboot.sh
mv /tmp/install-k3s-post-reboot.sh ~/install-k3s-post-reboot.sh

# ===== Phase 6: Summary and Instructions =====
log "Phase 6/7: Pre-reboot setup complete!"

cat << 'EOF'

✅ System preparation complete!

What was done:
  ✓ System packages updated
  ✓ Docker installed and user added to docker group
  ✓ Node.js LTS installed
  ✓ Python3 and pip installed
  ✓ AWS CLI installed (ARM64)
  ✓ Terraform installed (ARM64)
  ✓ Swap disabled
  ✓ cgroups enabled
  ✓ K3s installation script prepared

What happens next:
  1. System will reboot (required for cgroup and Docker group changes)
  2. After reboot, SSH back in
  3. Run: ~/install-k3s-post-reboot.sh
  4. K3s will be installed and configured

EOF

# ===== Phase 7: Reboot Prompt =====
log "Phase 7/7: Reboot required"
echo "A reboot is required for:"
echo "  - cgroup configuration to take effect"
echo "  - Docker group membership to activate"
echo ""
read -p "Reboot now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  log "Rebooting in 5 seconds... (Ctrl+C to cancel)"
  sleep 5
  sudo reboot
else
  echo ""
  echo "Reboot manually when ready:"
  echo "  sudo reboot"
  echo ""
  echo "Then SSH back in and run:"
  echo "  ~/install-k3s-post-reboot.sh"
  echo ""
fi
