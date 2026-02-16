# K3s on Raspberry Pi Tutorial Series

**Deploy Kubernetes on a $300 ARM64 board and build production-grade infrastructure**

## 📚 Tutorial Series

### [Part 1: Raspberry Pi 5 + K3s + Hello World](part1-k3s-hello-world.md)
Learn how to set up a Raspberry Pi 5, install K3s, and deploy your first containerized Flask app.

**What you'll learn:**
- Raspberry Pi OS setup with SSH keys
- Installing essential dev tools (Docker, Node.js, Python, Terraform, AWS CLI)
- K3s installation and configuration
- Building Docker images and importing to containerd
- Deploying to Kubernetes with kubectl
- Exposing services via NodePort

**Time**: ~45 minutes | **Cost**: ~$307

---

### [Part 2: OpenClaw AI + Telegram Bot](part2-openclaw-telegram.md)
Install OpenClaw AI assistant on your Pi and manage your K3s cluster remotely via Telegram.

**What you'll learn:**
- Creating a Telegram bot with BotFather
- Installing OpenClaw with one command
- Configuring AI model (Anthropic Claude)
- Managing K3s cluster via chat commands
- AI-powered troubleshooting and deployments
- Setting up proactive monitoring

**Time**: ~30 minutes | **Cost**: ~$1-5/month (API usage)

---

### Part 3: Multi-Tenant DevOps AI Platform *(coming soon)*
Build a complete multi-tenant B2B SaaS platform that provisions customer environments automatically.

**What you'll learn:**
- ArgoCD for GitOps continuous deployment
- GitHub Actions with self-hosted runners
- Multi-environment setup (dev/preprod/prod)
- Customer provisioning automation
- Multi-stack support (NodeJS, Python, Golang)
- Secret management and security

---

## 🎯 Who Is This For?

- Developers learning Kubernetes
- DevOps engineers building home labs
- SREs experimenting with edge computing
- Anyone tired of AWS bills

## 💡 Why Raspberry Pi?

- **Real Kubernetes** (same API as AWS EKS)
- **$300 one-time cost** (no monthly bills)
- **ARM64 architecture** (future of computing)
- **Edge computing** (IoT, local AI, hybrid cloud)
- **Full control** (no rate limits, no vendor lock-in)

## 🛠️ Tech Stack

- **Hardware**: Raspberry Pi 5 (16GB RAM, 512GB storage)
- **OS**: Raspberry Pi OS (64-bit)
- **Kubernetes**: K3s (lightweight K8s distribution)
- **Container Runtime**: containerd (K3s default)
- **Ingress**: Traefik (K3s default)
- **CI/CD**: GitHub Actions + ArgoCD
- **AI Assistant**: OpenClaw

---

## 📖 About This Series

This is a hands-on, practical guide to building production-ready infrastructure on ARM64 hardware. No fluff, no theory - just real code, real deployments, and real lessons learned.

**Author**: [@LeBrick07](https://github.com/lebrick07)  
**License**: MIT  
**Contributions**: Issues and PRs welcome!

---

*Star ⭐ this repo if you find it useful!*
