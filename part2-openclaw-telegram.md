# Part 2: OpenClaw AI + Telegram Bot

**Manage your Raspberry Pi K3s cluster remotely via AI-powered chat**

## What You'll Build

By the end of this tutorial, you'll have:
- ✅ OpenClaw AI assistant installed on your Raspberry Pi
- ✅ Telegram bot connected to OpenClaw
- ✅ Remote cluster management via chat commands
- ✅ AI-powered kubectl operations
- ✅ Proactive monitoring and alerts

**Time**: ~30 minutes  
**Cost**: $0 (uses Anthropic Claude - pay per use, ~$0.01-0.05/day typical usage)  
**Skill Level**: Beginner-friendly

---

## Prerequisites

From **Part 1**, you should have:
- Raspberry Pi 5 running Raspberry Pi OS
- K3s cluster operational
- SSH access to your Pi

---

## What is OpenClaw?

OpenClaw is an AI assistant that runs on your infrastructure and can:
- Execute shell commands
- Read and write files
- Control Kubernetes clusters
- Browse the web
- Interact via Telegram, Discord, WhatsApp, etc.

Think of it as ChatGPT, but with hands - it can actually do things on your behalf.

---

## Step 1: Create Telegram Bot

### 1.1 Open Telegram and Find BotFather

1. Open Telegram on your phone or desktop
2. Search for **@BotFather** (official Telegram bot for creating bots)
3. Start a chat with BotFather

### 1.2 Create Your Bot

Send these commands to BotFather:

```
/newbot
```

BotFather will ask for a name and username:

**Bot Name** (display name, can be anything):
```
My K3s Assistant
```

**Bot Username** (must be unique and end with 'bot'):
```
my_k3s_assistant_bot
```

(Try variations if taken: `my_k3s_bot`, `k3s_pi_assistant_bot`, etc.)

### 1.3 Save Your Bot Token

BotFather will reply with something like:

```
Done! Congratulations on your new bot...

Use this token to access the HTTP API:
1234567890:ABCdefGHIjklMNOpqrsTUVwxyz1234567890

Keep your token secure and store it safely...
```

**Copy and save this token!** You'll need it in the next steps.

Example token format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz1234567890`

### 1.4 Note About User ID

You'll get your Telegram User ID automatically during the OpenClaw setup in Step 4. When you first message your bot, OpenClaw will detect and show your User ID.

---

## Step 2: Get Anthropic API Key

### 2.1 Sign Up for Anthropic

1. Go to: [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to **API Keys** section
4. Click **Create Key**
5. Name it: `openclaw-pi`
6. Copy the API key (starts with `sk-ant-api03-...`)

**Save this API key!**

### 2.2 Add Initial Credit

Anthropic requires a minimum balance:
1. Go to **Billing** → **Add Credit**
2. Add $5-10 to start (typical usage: $0.01-0.05/day)

---

## Step 3: Install OpenClaw

### 3.1 SSH into Your Pi

```bash
ssh user@pi5-node-0.local
```

### 3.2 Run Installation Script

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

The installer will:
- Install Node.js (if not already installed)
- Install OpenClaw globally via npm
- Create configuration directory at `~/.openclaw/`
- Set up workspace at `~/.openclaw/workspace/`

**Installation takes ~2-3 minutes on a Pi 5.**

### 3.3 Verify Installation

```bash
openclaw --version
```

You should see something like:
```
OpenClaw Gateway v1.x.x
```

---

## Step 4: Configure OpenClaw

### 4.1 Initialize Configuration

Run the setup wizard:

```bash
openclaw gateway init
```

The wizard will ask several questions. Here are the recommended answers:

**1. Model Provider:**
```
? Select AI model provider: Anthropic (Claude)
```

**2. Anthropic API Key:**
```
? Enter your Anthropic API key: sk-ant-api03-[YOUR_KEY_HERE]
```

Paste your API key from Step 2.1.

**3. Default Model:**
```
? Select default model: claude-sonnet-4-5-20250929 (recommended)
```

**4. Enable Telegram:**
```
? Enable Telegram integration? Yes
```

**5. Telegram Bot Token:**
```
? Enter your Telegram bot token: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz1234567890
```

Paste your bot token from Step 1.3.

**6. Allowed Telegram Users:**

The wizard will detect your User ID when you first message the bot. You can either:
- Leave it empty now and add it after first message
- Or enter your User ID if you already know it (e.g., `123456789`)

The setup will show you: "Detected new user: 123456789 (@yourusername)" when you first chat with the bot.

**7. Additional Channels:**
```
? Enable additional channels (Discord, WhatsApp, etc.)? No
```

(You can add more later.)

**8. Session Settings:**
```
? Enable file upload? Yes
? Enable image analysis? Yes
? Max context messages: 50
```

### 4.2 Verify Configuration

```bash
openclaw gateway config.get
```

This will display your configuration in JSON format. Verify:
- `anthropic.apiKey` is set
- `telegram.token` is set
- `telegram.allowedUsers` contains your User ID

---

## Step 5: Start OpenClaw

### 5.1 Start the Gateway

```bash
openclaw gateway start
```

You should see:
```
✓ Gateway started successfully
✓ Telegram bot connected: @my_k3s_assistant_bot
✓ Ready to receive messages
```

### 5.2 Enable Auto-Start on Boot

So OpenClaw starts automatically when your Pi reboots:

```bash
# Install as systemd service
openclaw gateway install

# Enable auto-start
sudo systemctl enable openclaw-gateway

# Check status
sudo systemctl status openclaw-gateway
```

---

## Step 6: Test Your Bot

### 6.1 Start a Chat

1. Open Telegram
2. Search for your bot username (e.g., `@my_k3s_assistant_bot`)
3. Click **Start** to begin the conversation

### 6.2 Send Your First Message

```
Hello! Who are you?
```

The bot should respond with something like:

> Hey! I'm your AI assistant running on your Raspberry Pi. I have access to your K3s cluster and can help you manage it. What would you like to do?

### 6.3 Test Cluster Access

```
Show me all running pods in my K3s cluster
```

The bot should execute `kubectl get pods --all-namespaces` and show you the results!

Example response:
```
Here are all the pods running in your cluster:

NAMESPACE     NAME                                      READY   STATUS
kube-system   coredns-...                               1/1     Running
kube-system   local-path-provisioner-...                1/1     Running
kube-system   metrics-server-...                        1/1     Running
kube-system   traefik-...                               1/1     Running
default       hello-...                                 1/1     Running
```

---

## Step 7: Explore AI Capabilities

### 7.1 Deploy an App via Chat

Try this:

```
Deploy an nginx web server with 2 replicas and expose it on port 80
```

OpenClaw will:
1. Create a deployment YAML
2. Apply it to your cluster
3. Create a service
4. Show you the results

### 7.2 Check Cluster Health

```
What's the status of my K3s cluster?
```

OpenClaw will check:
- Node status
- Pod health
- Resource usage
- Any errors or warnings

### 7.3 Troubleshoot Issues

```
The hello pod keeps crashing. Can you check the logs?
```

OpenClaw will:
1. Find the pod
2. Get the logs
3. Analyze the error
4. Suggest a fix

### 7.4 Update Deployments

```
Scale the hello deployment to 5 replicas
```

OpenClaw executes:
```bash
kubectl scale deployment hello --replicas=5
```

And confirms the change.

---

## Step 8: Set Up Proactive Monitoring

OpenClaw can check your cluster periodically and alert you to issues.

### 8.1 Create Monitoring Script

Tell OpenClaw via Telegram:

```
Create a monitoring script that checks cluster health every hour and alerts me if anything is wrong
```

OpenClaw will create a cron job that:
- Checks node status
- Monitors pod crashes
- Watches resource usage
- Alerts you via Telegram if issues detected

### 8.2 Test Monitoring

Manually trigger a check:

```
Run a cluster health check now
```

You'll get a report like:

```
🟢 Cluster Health Report

Nodes: 1/1 Ready
Pods: 6/6 Running
CPU Usage: 15%
Memory Usage: 42%
Disk Usage: 28%

Everything looks good!
```

---

## Understanding OpenClaw

### Architecture

```
Telegram App (on your phone)
    ↓ (HTTPS)
Telegram Bot API
    ↓ (webhooks/polling)
OpenClaw Gateway (on Pi)
    ↓ (AI API calls)
Anthropic Claude API
    ↓ (tool execution)
Your K3s Cluster
```

### How It Works

1. **You send a message** via Telegram
2. **OpenClaw receives it** and sends your request to Claude
3. **Claude decides** what tools/commands to use
4. **OpenClaw executes** the commands on your Pi
5. **Results are sent back** to you via Telegram

### Security Model

- **Bot token** is private (don't share it!)
- **User allowlist** restricts access to your Telegram ID only
- **API key** is stored locally on your Pi (never transmitted to Telegram)
- **Commands run** as your user account on the Pi
- **Full audit trail** in `~/.openclaw/logs/`

---

## Useful Commands

### Gateway Management

```bash
# Check status
openclaw gateway status

# View logs
openclaw gateway logs

# Restart gateway
openclaw gateway restart

# Stop gateway
openclaw gateway stop
```

### Configuration

```bash
# View full config
openclaw gateway config.get

# Edit config (will restart gateway)
openclaw gateway config.patch '{"telegram":{"polling":true}}'
```

### Workspace

Your agent's memory and files are stored at:
```bash
~/.openclaw/workspace/
```

Files:
- `MEMORY.md` - Long-term memory
- `memory/YYYY-MM-DD.md` - Daily logs
- `AGENTS.md` - Agent behavior rules
- `SOUL.md` - Personality configuration

---

## Troubleshooting

### Bot Not Responding

**Check gateway status:**
```bash
openclaw gateway status
```

If not running:
```bash
openclaw gateway start
```

**Check logs:**
```bash
openclaw gateway logs
```

Common issues:
- Invalid bot token → Re-run `openclaw gateway init`
- User ID not in allowlist → Check Telegram config
- Network issues → Verify Pi has internet access

### "Unauthorized" Error

Your Telegram User ID is not in the allowlist.

Fix:
```bash
openclaw gateway config.patch '{"telegram":{"allowedUsers":["123456789"]}}'
```

Replace `123456789` with your actual User ID.

### API Key Issues

If Claude isn't responding:

```bash
# Verify API key is set
openclaw gateway config.get | grep apiKey

# Update API key
openclaw gateway config.patch '{"anthropic":{"apiKey":"sk-ant-api03-..."}}'
```

### Out of Credits

If you run out of Anthropic credits:
1. Go to [Billing](https://console.anthropic.com/billing)
2. Add more credit
3. API calls will resume automatically

---

## Advanced: Multi-User Access

To allow additional Telegram users (family, team members):

### Get Their User ID

Have them message your bot once. You'll see in the logs:

```bash
openclaw gateway logs
```

Look for: `Unauthorized user attempted access: 987654321 (@theirusername)`

That's their User ID!

### Add to Allowlist

```bash
openclaw gateway config.patch '{"telegram":{"allowedUsers":["123456789","987654321"]}}'
```

Now both users can access the bot.

---

## What's Next?

In **Part 3**, we'll build:
- Multi-tenant DevOps AI platform (OpenLuffy)
- ArgoCD for GitOps continuous deployment
- Automated customer provisioning
- Multi-stack support (NodeJS, Python, Golang)
- Production CI/CD pipeline

---

## Security Best Practices

### 1. Protect Your Bot Token

Never commit your bot token to Git or share it publicly. Anyone with your token can control your bot.

### 2. Use User Allowlist

Always restrict access to specific Telegram User IDs. Don't leave the allowlist empty.

### 3. Review Logs Regularly

```bash
openclaw gateway logs
```

Check for unexpected commands or access attempts.

### 4. Rotate API Keys

Periodically rotate your Anthropic API key:
1. Create new key in console
2. Update OpenClaw config
3. Delete old key

### 5. Monitor Costs

Check Anthropic usage at: [console.anthropic.com/settings/usage](https://console.anthropic.com/settings/usage)

Set budget alerts to avoid surprises.

---

## Cost Analysis

### Typical Monthly Usage

**Light usage** (5-10 messages/day):
- ~$1-3/month

**Moderate usage** (20-30 messages/day + monitoring):
- ~$5-10/month

**Heavy usage** (50+ messages/day + automation):
- ~$15-30/month

### Cost Optimization Tips

1. **Use lower-tier models** for simple tasks (Haiku is cheaper than Sonnet)
2. **Batch questions** instead of multiple short messages
3. **Disable monitoring** when not needed
4. **Set budget alerts** in Anthropic console

Still way cheaper than cloud Kubernetes! ☁️💸

---

## Resources

- [**OpenClaw Documentation**](https://docs.openclaw.ai)
- [**OpenClaw GitHub**](https://github.com/openclaw/openclaw)
- [**OpenClaw Community Discord**](https://discord.com/invite/clawd)
- [**Anthropic Console**](https://console.anthropic.com/)
- [**BotFather**](https://t.me/BotFather)

---

*Tutorial by @LeBrick07 | Part 2 of 3 | Last Updated: 2026-02-16*
