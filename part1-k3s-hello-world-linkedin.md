# Raspberry Pi initial setup + K3s installation and Hello World app deployment - Part 1

**I just deployed production-grade Kubernetes on a Raspberry Pi 5.**

Not a toy. **Real Kubernetes** - same API as AWS EKS, Google GKE, Azure AKS.

💰 **$307 one-time vs $1,908/year cloud**

---

## What I Built

✅ Full K3s cluster with Traefik ingress  
✅ Custom Flask app containerized with Docker  
✅ Multi-arch ARM64 images  
✅ Production kubectl workflows  

Legitimate Kubernetes on my desk, 15W power consumption.

---

## 🎓 Complete Tutorial

Copy-paste friendly. No manual editing. Full troubleshooting.

**👉 STEP-BY-STEP GUIDE:**  
**https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part1-k3s-hello-world**

**📖 Includes:**
- Exact hardware shopping list
- SSH + system prep (cgroups, swap)
- K3s one-command install
- Docker + Flask deployment
- kubectl workflows

---

## Why This Matters

Learning Kubernetes usually means:
- Cloud providers (expensive)
- Minikube (simulated)
- Docker Desktop (not production-like)

**K3s on Pi gives you:**

🎯 Real infrastructure - same as production clusters  
🎯 Full control - no quotas, rate limits, surprise bills  
🎯 ARM64 expertise - AWS Graviton, Apple Silicon  
🎯 Edge computing skills - IoT, local AI, hybrid cloud  

You're **running Kubernetes**, not playing with it.

---

## Performance

**Hardware:** Pi 5 16GB, quad-core ARM, 512GB SD, passive cooling

**Running:** K3s control plane, etcd, CoreDNS, Traefik, metrics, Flask app (2 replicas)

**Usage:** 15-20% CPU, 3.2GB RAM

**Capacity:** Room for 20-30+ more pods

---

## Cost Breakdown

**Pi setup:** $307 one-time + $2/month power  
**AWS EKS:** $159/month = $1,908/year

**ROI: 2 months**

Plus you own the hardware. No vendor lock-in.

---

## What You'll Learn

**Key technical challenge:** K3s uses containerd (not Docker daemon)

Build workflow:
```bash
docker build -t hello:latest .
docker save hello:latest | sudo k3s ctr images import -
```

**Skills you'll gain:**
- Basic Linux commands and system administration
- Production-grade Raspberry Pi setup
- Containerd vs Docker (runtime differences)
- Building Docker images from scratch
- Deploying Flask applications
- K3s vs full Kubernetes (when to use lightweight K8s)

---

## Series Roadmap

**Part 2:** OpenClaw AI - Installation and configuration + Telegram Bot setup  
**Part 3:** AI-powered multi-tenant DevOps - Building an automated provisioning powerhouse

---

**Tried Kubernetes on ARM64? What would you deploy?**

Comment below - happy to help! 🚀

---

#Kubernetes #K3s #RaspberryPi #EdgeComputing #DevOps #Docker #SelfHosted #HomeLab #ARM64 #CloudComputing #Containerization #SRE #GitOps #CNCF #CloudNative #OpenSource #DevOpsTools #Learning
