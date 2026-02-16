# Part 1: Raspberry Pi 5 + K3s + Hello World

**Deploy your first Kubernetes app on a $300 ARM64 board**

## What You'll Build

By the end of this tutorial, you'll have:
- ✅ Raspberry Pi 5 running 64-bit Raspberry Pi OS
- ✅ K3s Kubernetes cluster operational
- ✅ Hello World web app accessible via browser
- ✅ Understanding of kubectl basics and ingress routing

**Time**: ~45 minutes  
**Cost**: ~$307 (or ~$257 with 128GB SD)  
**Skill Level**: Beginner-friendly (basic terminal knowledge required)

---

## Hardware Requirements

### What You Need

- **Raspberry Pi 5** (8GB or 16GB RAM recommended)
- **MicroSD card** (64GB minimum, 128GB recommended, 512GB if you want headroom)
- **Power supply** (27W USB-C official adapter)
- **Case with cooling** (passive or active cooling recommended for K3s)
- **WiFi connection** (or ethernet if preferred)

### Shopping List

- Raspberry Pi 5 (16GB): $205
- Official 27W USB-C PSU: ~$12
- SanDisk Extreme Pro 512GB microSD: ~$70 (or 128GB for ~$20)
- Heavy-Duty Aluminum Passive Cooling Case: ~$20

**Total: ~$307 (or ~$257 with 128GB SD card)**

---

## Step 1: Set Up Raspberry Pi OS

### 1.1 Generate SSH Key (Optional but Recommended)

On your laptop/desktop, generate an SSH key pair if you don't already have one:

```bash
# Check if you already have an SSH key
ls ~/.ssh/id_ed25519.pub

# If not, generate one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Press Enter for default location
# Set a passphrase (or leave empty for no passphrase)

# View your public key
cat ~/.ssh/id_ed25519.pub
```

Copy the output (starts with `ssh-ed25519 AAAA...`). You'll need this in the next step.

### 1.2 Flash the SD Card

Download and install **Raspberry Pi Imager**: https://www.raspberrypi.com/software/

1. Insert your microSD card into your computer
2. Open Raspberry Pi Imager
3. Click **"Choose Device"** → Select Raspberry Pi 5
4. Click **"Choose OS"** → Raspberry Pi OS (64-bit) - Full desktop recommended
5. Click **"Choose Storage"** → Select your microSD card
6. Click the **⚙️ Settings** icon (bottom right)

**OS Customization Settings:**
- ✅ Enable SSH
  - Choose **"Allow public-key authentication only"**
  - Paste your public key from step 1.1 (or use password authentication if you prefer)
- Set hostname: `pi5-node-0` (or your preference)
- Username: `user`
- Password: (choose a strong password - needed even with SSH keys for sudo)
- ✅ Configure WiFi
  - SSID: your WiFi network name
  - Password: your WiFi password
  - WiFi country: your country code (e.g., US)
- Set locale settings (timezone, keyboard layout)

7. Click **"Save"** then **"Write"**
8. Wait for the flash process to complete (~5-10 minutes)

**Note**: If using SSH key authentication, you won't need to type a password when SSHing in!

### 1.3 First Boot

1. Insert the microSD card into your Raspberry Pi 5
2. Install Pi in your aluminum cooling case
3. Connect power supply (Pi will boot automatically)
4. Wait 1-2 minutes for first boot and WiFi connection

### 1.4 SSH Into Your Pi

Once the Pi finishes booting (1-2 minutes), you can SSH using the hostname you configured:

```bash
ssh user@pi5-node-0.local
```

Type `yes` when asked about fingerprint. If you used SSH key authentication, you'll log right in. Otherwise, enter your password.

**Note**: The `.local` hostname works via mDNS - no need to find the IP address!

---

## Step 2: Prepare the System

### 2.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

This may take 5-10 minutes depending on how many packages need updating.

### 2.2 Install Essential Tools

```bash
# Install git (usually pre-installed, but let's make sure)
sudo apt install -y git curl wget unzip

# Install Docker (for building images)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version

# Install Node.js (LTS version via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
node --version
npm --version

# Install Python 3 and pip (usually pre-installed on Pi OS)
sudo apt install -y python3 python3-pip python3-venv

# Verify Python installation
python3 --version
pip3 --version

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Verify AWS CLI
aws --version

# Install Terraform (use latest ARM64 binary)
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_arm64.zip
unzip terraform_1.7.0_linux_arm64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.7.0_linux_arm64.zip

# Verify Terraform
terraform --version
```

**Important**: Log out and back in now for Docker group changes to take effect:

```bash
exit
```

Then SSH back in:

```bash
ssh user@pi5-node-0.local
```

Verify Docker works without sudo:

```bash
docker ps
```

If you see "permission denied", you didn't log out/in yet.

### 2.3 Disable Swap

Kubernetes requires swap to be disabled for optimal performance and stability.

```bash
# Disable swap immediately
sudo swapoff -a

# Disable swap permanently
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

# Verify swap is off (should show no output)
sudo swapon --show
free -h  # Swap line should show 0
```

### 2.4 Enable cgroups

K3s requires cgroups to be enabled for container resource management. Run this automated script:

```bash
# Backup original cmdline.txt
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup

# Add cgroup parameters to the end of the existing line
sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt

# Verify it was added correctly
cat /boot/firmware/cmdline.txt
```

You should see the cgroup parameters at the end of the line. If something went wrong, restore the backup:
```bash
sudo cp /boot/firmware/cmdline.txt.backup /boot/firmware/cmdline.txt
```

### 2.5 Reboot

```bash
sudo reboot
```

Wait 1-2 minutes, then SSH back in:

```bash
ssh user@pi5-node-0.local
```

---

## Step 3: Install K3s

K3s is a lightweight Kubernetes distribution perfect for edge computing and single-node clusters.

### 3.1 Install K3s

```bash
curl -sfL https://get.k3s.io | sh -
```

This single command:
- Downloads K3s binary
- Installs as a systemd service
- Configures kubectl
- Deploys CoreDNS and Traefik ingress controller
- Enables auto-start on boot

**Installation takes ~2-3 minutes**

### 3.2 Verify Installation

```bash
# Check K3s service status
sudo systemctl status k3s

# Check cluster info
sudo kubectl get nodes
```

Expected output:
```
NAME          STATUS   ROLES                  AGE   VERSION
pi5-node-0    Ready    control-plane,master   30s   v1.34.4+k3s1
```

### 3.3 Configure kubectl for Non-Root User

```bash
# Copy kubectl config
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Test kubectl access
kubectl get nodes
```

Now you can run `kubectl` without `sudo`!

---

## Step 4: Build a Hello World App

### 4.1 Create a Flask Application

Create a project directory and a simple Flask app:

```bash
mkdir ~/hello-app
cd ~/hello-app

# Create the Flask app
cat > app.py << 'EOF'
from flask import Flask
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    hostname = socket.gethostname()
    return f"""
    <html>
        <head><title>Hello from Kubernetes!</title></head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>🎉 Hello from Kubernetes on Raspberry Pi!</h1>
            <p><strong>Container hostname:</strong> {hostname}</p>
            <p>This Flask app is running in a K3s cluster.</p>
        </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Create requirements file
cat > requirements.txt << 'EOF'
flask==3.0.0
EOF
```

### 4.2 Create a Dockerfile

```bash
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
EOF
```

### 4.3 Build the Docker Image

```bash
# Build the image locally
docker build -t hello:latest .
```

This builds an ARM64 image locally on your Pi.

### 4.4 Import Image into K3s

K3s uses `containerd` instead of Docker as its container runtime. Import the image:

```bash
docker save hello:latest | sudo k3s ctr images import -
```

Verify the image is available:

```bash
sudo k3s ctr images ls | grep hello
```

---

## Step 5: Deploy to Kubernetes

### 5.1 Create the Deployment

```bash
# Create deployment
kubectl create deployment hello --image=hello:latest

# Patch to use local image (no pull from registry)
kubectl patch deployment hello -p '{"spec":{"template":{"spec":{"containers":[{"name":"hello","image":"hello:latest","imagePullPolicy":"Never"}]}}}}'
```

The `imagePullPolicy: Never` tells K3s to use the local image we imported.

### 5.2 Expose the Service

```bash
# Expose as NodePort service
kubectl expose deployment hello --type=NodePort --port=5000
```

### 5.3 Verify Deployment

```bash
# Check pods
kubectl get pods

# Check service
kubectl get svc hello
```

Expected output:
```
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
hello   NodePort   10.43.xxx.xxx   <none>        5000:xxxxx/TCP   10s
```

Note the port mapping: `5000:31972/TCP` means port 5000 inside the container is exposed on port 31972 on the node.

---

## Step 6: Access Your App

### 6.1 Find the NodePort

```bash
kubectl get svc hello
```

Look for the port mapping like `5000:31972/TCP`. The second number (31972) is your NodePort.

### 6.2 Get Your Pi's IP Address

```bash
hostname -I | awk '{print $1}'
```

Example output: `10.0.0.67`

### 6.3 Open in Browser

Navigate to: **http://10.0.0.67:31972** (replace with your IP and NodePort)

You should see:
```
🎉 Hello from Kubernetes on Raspberry Pi!

Container hostname: hello-xxxxxxxxx-xxxxx

This Flask app is running in a K3s cluster.
```

🎉 **Congratulations!** You've built a Docker image, imported it into K3s, and deployed your first Kubernetes app on a Raspberry Pi!

---

## Understanding What You Built

### Architecture

```
Browser (http://10.0.0.67:31972)
    ↓
NodePort Service (exposes port on host)
    ↓
hello Deployment
    ↓
hello Pod (1 replica)
    ↓
Flask app container (port 5000)
```

### Key Components

**Dockerfile**: Instructions to build a container image  
**Docker**: Builds images locally  
**containerd**: K3s container runtime (not Docker)  
**Deployment**: Defines desired state (1 replica pod)  
**Service (NodePort)**: Exposes pod on a high port (30000-32767) on the node  
**imagePullPolicy: Never**: Uses local image instead of pulling from registry  

### Why This Matters

- **Real Kubernetes**: Same API as AWS EKS, Google GKE, Azure AKS
- **Learn Docker & Kubernetes**: Build, deploy, and manage containers hands-on
- **Cost-Effective**: $300 one-time vs $50-100/month for cloud
- **Full Control**: Local cluster for experimenting without cloud bills or limits

---

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>
```

Common issues:
- **ImagePullBackOff**: Image not found in containerd - verify with `sudo k3s ctr images ls | grep hello`
- **CrashLoopBackOff**: Container crashing - check logs with `kubectl logs <pod-name>`

### Can't Access the App

1. **Verify service**: `kubectl get svc hello` - should show NodePort assigned
2. **Check pod is running**: `kubectl get pods` - STATUS should be `Running`
3. **Test from Pi itself**: `curl http://localhost:<nodeport>`
4. **Verify Docker group**: Log out and back in after adding user to docker group

### Image Not Found in containerd

If you get `ImagePullBackOff`:

```bash
# List images in containerd
sudo k3s ctr images ls

# If hello:latest is missing, re-import
docker save hello:latest | sudo k3s ctr images import -
```

### K3s Service Not Starting

```bash
# Check systemd status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f

# Restart service
sudo systemctl restart k3s
```

**Common fix**: If cgroups weren't enabled, K3s won't start properly. Verify `/boot/firmware/cmdline.txt` has the cgroup parameters.

---

## Useful kubectl Commands

```bash
# View all resources
kubectl get all

# Delete deployment and service
kubectl delete deployment hello
kubectl delete service hello

# Scale deployment
kubectl scale deployment hello --replicas=3

# Watch pods in real-time
kubectl get pods -w

# View logs from all pods
kubectl logs -l app=hello

# Get cluster info
kubectl cluster-info

# View node resources
kubectl top node  # (requires metrics-server)
```

---

## Clean Up

To remove the hello app:

```bash
kubectl delete deployment hello
kubectl delete service hello
```

To remove the Docker image:

```bash
docker rmi hello:latest
sudo k3s ctr images rm docker.io/library/hello:latest
```

To completely uninstall K3s:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## What's Next?

In **Part 2**, we'll cover:
- Installing OpenClaw AI assistant on your Pi
- Configuring Telegram bot for remote management
- Using OpenClaw to monitor and manage your K3s cluster
- Setting up proactive alerts and automation

---

## 🎉 LinkedIn Post

**I just deployed Kubernetes on a Raspberry Pi 5 and built my first containerized app.**

Here's what I learned:

🚀 **K3s makes Kubernetes accessible** - Single command installation, batteries included  
💰 **$300 one-time cost vs $50-100/month cloud bills** - Perfect for learning and edge workloads  
🌐 **Real Kubernetes API** - Same kubectl commands as AWS EKS or Google GKE  
🐳 **containerd is different from Docker** - Had to import images after building  
🔥 **Passive cooling works great** - Heavy-duty aluminum case keeps temps stable  

**Why this matters:**

Edge computing is the future. Running production-grade Kubernetes on a $300 device opens up incredible possibilities:
- Learn Kubernetes without AWS bills
- Build home lab infrastructure
- IoT and edge computing projects
- Self-hosted applications with real orchestration

**The stack:**
- Raspberry Pi 5 (16GB RAM, 512GB storage)
- K3s (lightweight Kubernetes)
- Docker (for building images)
- Python Flask app (custom built)

**The process:**
1. Built a Flask app locally
2. Created Docker image
3. Imported to K3s containerd
4. Deployed with kubectl
5. Exposed via NodePort service

**Next up:** Installing OpenClaw AI assistant to manage this cluster via Telegram.

Full tutorial: Part 2 coming soon!

---

**#Kubernetes #K3s #RaspberryPi #EdgeComputing #DevOps #CloudComputing #ARM64 #SelfHosted #HomeLab**

---

## Resources

- **K3s Documentation**: https://docs.k3s.io
- **Raspberry Pi OS**: https://www.raspberrypi.com/software/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Traefik Docs**: https://doc.traefik.io/traefik/

---

*Tutorial by @LeBrick07 | Last Updated: 2026-02-16*
