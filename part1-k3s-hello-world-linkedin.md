# LinkedIn Post: Raspberry Pi initial setup + K3s installation and Hello World app deployment - Part 1

**I just deployed Kubernetes on a Raspberry Pi 5. Here's how.**

🚀 **Total cost: $307** (one-time, no monthly cloud bills)

## What I Built

✅ Raspberry Pi 5 with K3s (lightweight Kubernetes)  
✅ Custom Flask app containerized with Docker  
✅ Full kubectl deployment workflow  
✅ Running production-grade orchestration on ARM64

## Why This Matters

Most people think Kubernetes requires expensive cloud infrastructure. Wrong.

A $300 Raspberry Pi gives you:
- Real Kubernetes API (same as AWS EKS)
- Full control over your infrastructure
- Perfect learning environment
- Zero ongoing costs

## The Setup

**Hardware:**
- Raspberry Pi 5 (16GB RAM)
- 512GB SD card
- Heavy-duty aluminum cooling case
- WiFi connection

**Stack:**
- K3s (installs in one command!)
- Docker (for building images)
- containerd (K3s runtime)
- Python Flask app

## Key Learning

The hardest part? **Understanding containerd vs Docker.**

K3s doesn't use Docker as its runtime. After building images with Docker, you have to import them into containerd:

```bash
docker save hello:latest | sudo k3s ctr images import -
```

Once you understand that, everything clicks.

## What's Next

**Part 2:** Installing OpenClaw AI assistant to manage this cluster via Telegram bot.

**Part 3:** Building a multi-tenant DevOps AI tool that provisions customer environments automatically.

---

**Full tutorial with code, troubleshooting, and step-by-step instructions:**  
👉 https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part1-k3s-hello-world

---

*Drop a comment if you want the full 3-part series or have questions about running Kubernetes on ARM64!*

**#Kubernetes #K3s #RaspberryPi #EdgeComputing #DevOps #Docker #SelfHosted #HomeLab #ARM64**
