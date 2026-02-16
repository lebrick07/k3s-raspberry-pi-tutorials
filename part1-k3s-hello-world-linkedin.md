# LinkedIn Post: Raspberry Pi initial setup + K3s installation and Hello World app deployment - Part 1

**I just deployed a production-grade Kubernetes cluster on a Raspberry Pi 5.**

Not a toy. Not a simulation. **Real Kubernetes** - same API as AWS EKS, Google GKE, Azure AKS.

💰 **Total cost: $307 one-time** (compare to $600-1200/year for cloud)

---

## What I Actually Built

✅ **Full K3s cluster** with Traefik ingress controller  
✅ **Custom Flask application** - built from scratch with Docker  
✅ **Multi-arch container images** (ARM64 optimized)  
✅ **NodePort service exposure** - accessible from any device on network  
✅ **kubectl-based deployments** - production workflows on a Pi  

**The result?** A legitimate Kubernetes environment running on my desk, consuming 15W of power.

---

## Why This Actually Matters

Everyone says "learn Kubernetes" but then points you to:
- Cloud providers (expensive, limited free tiers)
- Minikube (simulated, not real K8s)
- Docker Desktop (not production-like)

**This is different.**

Running K3s on a Pi gives you:

🎯 **Real infrastructure** - same architecture as production clusters  
🎯 **Actual kubectl experience** - not simplified tutorials  
🎯 **Full control** - no AWS quotas, no rate limits, no surprise bills  
🎯 **ARM64 expertise** - the future of computing (AWS Graviton, Apple Silicon)  
🎯 **Edge computing skills** - IoT, local AI, hybrid cloud patterns  

You're not "playing with Kubernetes" - you're **running Kubernetes.**

---

## The Technical Journey

**Hardware:**
- Raspberry Pi 5 (16GB RAM, quad-core ARM Cortex-A76)
- 512GB Extreme Pro SD card (fast I/O critical for etcd)
- Heavy-duty aluminum passive cooling (keeps temps under 60°C)
- WiFi connectivity (no ethernet required)

**Software stack:**
- Raspberry Pi OS 64-bit (Debian Bookworm)
- K3s v1.34+ (single-command install)
- Docker (for building images)
- containerd (K3s runtime)
- Python Flask + Gunicorn
- Essential dev tools (Node.js, Terraform, AWS CLI)

**Key technical challenge:** Understanding K3s uses containerd, not Docker daemon. Building images requires Docker, but K3s needs them imported:

```bash
docker build -t hello:latest .
docker save hello:latest | sudo k3s ctr images import -
```

This workflow is closer to real CI/CD pipelines than Docker Desktop's shared daemon.

---

## What You Learn

📚 **SSH key authentication** (no password logins)  
📚 **Linux system preparation** (cgroups, swap management)  
📚 **Container runtime differences** (Docker vs containerd)  
📚 **Kubernetes deployments** (pods, services, replica sets)  
📚 **Network routing** (NodePort, how ingress controllers work)  
📚 **Debugging containers** (logs, describe, events)  

Real skills. Production patterns. Not tutorials - actual infrastructure.

---

## Performance Reality Check

**Can a $300 device really run Kubernetes?**

Yes. Here's what I'm running simultaneously:
- K3s control plane (API server, scheduler, controller manager)
- etcd (cluster state)
- CoreDNS (service discovery)
- Traefik (ingress controller)
- Metrics server
- My Flask application (2 replicas)

**Resource usage:**
- CPU: 15-20% at idle, 40-50% under load
- Memory: 3.2GB / 16GB (plenty of headroom)
- Storage I/O: Excellent with Extreme Pro SD

Room for 20-30 more pods easily. This isn't a proof-of-concept - it's a functional cluster.

---

## Cost Breakdown vs Cloud

**My setup (one-time):**
- Pi 5 16GB: $205
- Power supply: $12
- 512GB SD: $70
- Cooling case: $20
- **Total: $307**

**Cloud equivalent (per month):**
- AWS EKS cluster: $73
- 2x t3.medium nodes: $60
- Load balancer: $16
- Data transfer: $10-50
- **Total: ~$159/month = $1,908/year**

My Pi pays for itself in 2 months. After that? **Free.**

Plus I own the hardware. No vendor lock-in. No surprise bills. No rate limits.

---

## What's Coming Next

This is **Part 1 of 3** in my series on building production infrastructure on ARM64:

**Part 2:** Installing OpenClaw AI assistant - manage the cluster via Telegram bot with natural language commands

**Part 3:** Building OpenLuffy - a multi-tenant DevOps AI platform with ArgoCD, GitHub Actions, and automated customer provisioning (NodeJS, Python, Golang stacks)

By the end, you'll have a complete B2B SaaS infrastructure running on a Pi.

---

## 🎓 Get The Complete Tutorial

Everything is copy-paste friendly. No manual file editing. Complete troubleshooting guide included.

**👉 STEP-BY-STEP GUIDE:**  
**https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part1-k3s-hello-world**

**📖 Includes:**
- Hardware shopping list
- SSH key setup
- System preparation (cgroups, swap, dev tools)
- K3s installation
- Docker image building
- Flask app deployment
- kubectl workflows
- Complete troubleshooting section

---

## Join The Conversation

🗨️ **Have you tried running Kubernetes on ARM64?**  
🗨️ **What would you deploy on a Pi cluster?**  
🗨️ **Interested in the AI-powered DevOps platform in Part 3?**

Drop a comment - I'm here to help if you want to build this!

---

**#Kubernetes #K3s #RaspberryPi #EdgeComputing #DevOps #Docker #SelfHosted #HomeLab #ARM64 #CloudComputing #Containerization #Orchestration #SRE #Platform Engineering #InfrastructureAsCode #GitOps #CNCF #CloudNative #OpenSource #TechTutorial #DevOpsTools #SystemsEngineering #Learning #CareerDevelopment #100DaysOfKubernetes**
