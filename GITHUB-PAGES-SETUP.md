# Setting Up GitHub Pages for Tutorials

## Quick Setup

### 1. Create GitHub Repository

```bash
# Create a new public repo on GitHub: k3s-raspberry-pi-tutorials
# Or use an existing repo
```

### 2. Push Tutorials to GitHub

```bash
cd ~/.openclaw/workspace/tutorials

# Initialize git if not already done
git init

# Add remote (replace with your username)
git remote add origin https://github.com/lebrick07/k3s-raspberry-pi-tutorials.git

# Push
git add .
git commit -m "Initial commit: K3s on Raspberry Pi tutorials"
git push -u origin main
```

### 3. Enable GitHub Pages

1. Go to your repo: `https://github.com/lebrick07/k3s-raspberry-pi-tutorials`
2. Click **Settings** tab
3. Click **Pages** in left sidebar
4. Under **Source**: Select `main` branch and `/ (root)` folder
5. Click **Save**

GitHub will build your site in ~1 minute.

### 4. Access Your Tutorials

Your tutorials will be available at:
```
https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part1-k3s-hello-world
```

**Note**: GitHub Pages automatically renders `.md` files! No need to convert to HTML.

## Update LinkedIn Post

Replace `[LINK TO S3/BLOG HERE]` with:
```
https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part1-k3s-hello-world
```

## Adding More Tutorials

```bash
# Create new tutorial
vim part2-openclaw-telegram.md

# Commit and push
git add part2-openclaw-telegram.md
git commit -m "docs: Add Part 2 - OpenClaw + Telegram"
git push

# Automatically available at:
# https://lebrick07.github.io/k3s-raspberry-pi-tutorials/part2-openclaw-telegram
```

## Optional: Add Custom Domain

If you own a domain:

1. Add `CNAME` file to repo:
   ```bash
   echo "tutorials.yourdomain.com" > CNAME
   git add CNAME
   git commit -m "Add custom domain"
   git push
   ```

2. Add DNS record at your domain registrar:
   ```
   CNAME tutorials.yourdomain.com -> lebrick07.github.io
   ```

3. Enable HTTPS in GitHub Pages settings

## Optional: Create Index Page

Create `README.md` as homepage:

```markdown
# K3s on Raspberry Pi Tutorial Series

Learn how to deploy Kubernetes on a Raspberry Pi and build production-grade infrastructure.

## Tutorials

1. [Part 1: Raspberry Pi 5 + K3s + Hello World](part1-k3s-hello-world.md)
2. [Part 2: OpenClaw AI + Telegram Bot](part2-openclaw-telegram.md) *(coming soon)*
3. [Part 3: Multi-Tenant DevOps AI Platform](part3-multi-tenant-devops.md) *(coming soon)*

---

**Author**: @LeBrick07  
**GitHub**: https://github.com/lebrick07
```

This becomes your homepage: `https://lebrick07.github.io/k3s-raspberry-pi-tutorials/`

## Advantages of GitHub Pages

✅ **Free forever** (for public repos)  
✅ **Automatic markdown rendering** with GitHub styling  
✅ **Version control built-in** (git history)  
✅ **Easy updates** (just push to main)  
✅ **Custom domain support** (optional)  
✅ **HTTPS enabled** by default  
✅ **No server maintenance**  

Perfect for technical tutorials!
