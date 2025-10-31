# 🚀 Complete Oracle Cloud WhatsApp Bot Deployment Guide

## 📋 Overview

Deploy your WhatsApp notification system on Oracle Cloud's **Always Free Tier** - this gives you:
- ✅ **2 CPU cores + 12GB RAM** (Arm-based Ampere A1)
- ✅ **200GB persistent storage**
- ✅ **10TB monthly bandwidth**
- ✅ **24/7 uptime** (no sleep/auto-stop)
- ✅ **100% FREE forever**
- ✅ **Public IPv4 address**

**Better than fly.io**: More resources, no sleep issues, full control!

---

## ⏱️ Time Required

- **Phase 1**: Oracle Cloud Account Setup (20 min)
- **Phase 2**: Create VM Instance (30 min)
- **Phase 3**: Security Configuration (20 min)
- **Phase 4**: Server Preparation (30 min)
- **Phase 5**: WhatsApp Bot Deployment (30 min)
- **Phase 6**: Production Setup (30 min)
- **Phase 7**: Flutter Integration (15 min)

**Total: 2.5-3 hours for complete setup**

---

# PHASE 1: Oracle Cloud Account Setup (20 minutes)

## Step 1.1: Create Oracle Cloud Account

### Prerequisites:
- Valid email address
- Credit/debit card (for verification only - won't be charged)
- Phone number for verification

### Account Creation:
1. Go to: https://www.oracle.com/cloud/free/
2. Click **"Start for free"**
3. Fill in details:
   - **Country/Territory**: Your country
   - **Name**: Your full name
   - **Email**: Your email
   - **Verify email**: Check inbox for verification code

4. Enter **Account Information**:
   - **Cloud Account Name**: `edutrack-cloud` (or your choice)
   - **Home Region**: Choose closest to you (e.g., Mumbai, Singapore)
   - ⚠️ **Important**: Region cannot be changed later!

5. **Verify Identity**:
   - Enter phone number
   - Enter SMS verification code
   - Provide address details
   - Add credit/debit card (for verification - $0 charge)

6. Complete verification and wait for account activation (5-10 minutes)

### ✅ Success: You'll receive email "Your Oracle Cloud Account is Ready"

---

## Step 1.2: First Login & Dashboard

1. Go to: https://cloud.oracle.com/
2. Enter your **Cloud Account Name** from Step 1.1
3. Click **Continue**
4. Sign in with your email and password
5. You'll see the **Oracle Cloud Console Dashboard**

### Verify Free Tier:
- Top-right corner: Click your profile icon
- Check "Tenancy" shows "Free Tier"
- Verify "Always Free-eligible" resources are available

---

# PHASE 2: Create VM Instance (30 minutes)

## Step 2.1: Navigate to Compute Instances

1. In Oracle Cloud Console, click **☰ (hamburger menu)** → **Compute** → **Instances**
2. You'll see the Compute Instances page
3. Click **"Create Instance"** button

---

## Step 2.2: Configure Instance Basics

### Instance Name:
```
edutrack-whatsapp-bot
```

### Compartment:
- Leave as **"root"** (default)

### Placement:
- **Availability Domain**: Leave default
- **Fault Domain**: Leave default (optional)

---

## Step 2.3: Choose Image and Shape (CRITICAL!)

### Image:
1. Click **"Change Image"**
2. Select **"Canonical Ubuntu"**
3. Choose **"22.04"** (latest LTS)
4. Click **"Select Image"**

### Shape (This determines free tier eligibility):
1. Click **"Change Shape"**
2. **Instance Type**: Select **"Virtual Machine"**
3. **Shape Series**: Select **"Ampere"** (ARM-based)
4. **Shape Name**: Select **"VM.Standard.A1.Flex"**
5. Configure resources:
   - **OCPUs**: 2 (free tier allows up to 4)
   - **Memory (GB)**: 12 (free tier allows up to 24)
6. Click **"Select Shape"**

### ✅ Verify: You should see "Always Free-eligible" badge

---

## Step 2.4: Networking Configuration

### Primary VNIC Information:
- **Primary Network**: Leave default (automatically created VCN)
- **Subnet**: Leave default (public subnet)
- **Public IPv4 Address**: Select **"Assign a public IPv4 address"** ✅

### Advanced Options (expand if needed):
- Leave all defaults for now

---

## Step 2.5: Add SSH Keys (IMPORTANT!)

You need SSH keys to access your server securely.

### Option A: Generate SSH Keys (Recommended for beginners)

#### On Windows PowerShell:
```powershell
# Create .ssh directory if it doesn't exist
mkdir $HOME\.ssh -Force

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\oracle_cloud_key" -N '""'

# This creates:
# - Private key: C:\Users\YourName\.ssh\oracle_cloud_key
# - Public key: C:\Users\YourName\.ssh\oracle_cloud_key.pub
```

#### Get your public key content:
```powershell
Get-Content "$HOME\.ssh\oracle_cloud_key.pub"
```

### Option B: Use Existing SSH Key

If you already have SSH keys, use your existing public key.

### In Oracle Cloud Console:
1. Under **"Add SSH keys"** section
2. Select **"Paste public keys"**
3. Paste the content of your `.pub` file
4. Verify it starts with `ssh-rsa AAAAB3...`

⚠️ **CRITICAL**: Save your private key securely! You'll need it to access the server.

---

## Step 2.6: Boot Volume Configuration

### Boot Volume:
- **Size (GB)**: 50 (default, sufficient)
- **Backup Policy**: None (not needed for test)

---

## Step 2.7: Launch Instance

1. Review all settings
2. Click **"Create"** button
3. Wait for provisioning (2-5 minutes)
4. Instance status will change: Provisioning → Running 🟢

### ✅ Success Indicators:
- **State**: Running (green icon)
- **Public IP Address**: Shows an IP (e.g., 123.45.67.89)
- **Always Free**: Badge visible

### 📝 Save These Details:
- **Public IP Address**: _________________
- **Username**: `ubuntu` (default for Ubuntu)
- **SSH Key Location**: C:\Users\YourName\.ssh\oracle_cloud_key

---

# PHASE 3: Security Configuration (20 minutes)

## Step 3.1: Configure VCN Security Lists

Oracle Cloud has TWO layers of firewall:
1. **VCN Security Lists** (Cloud-level firewall)
2. **UFW** (Instance-level firewall - we'll configure later)

### Configure Cloud Firewall:

1. In your instance details page, click **"Subnet"** link
2. Click on the **Default Security List**
3. Click **"Add Ingress Rules"**

### Add Ingress Rule for HTTP:
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: `TCP`
- **Source Port Range**: Leave blank
- **Destination Port Range**: `80`
- **Description**: `HTTP for web access`
- Click **"Add Ingress Rules"**

### Add Ingress Rule for HTTPS:
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: `TCP`
- **Destination Port Range**: `443`
- **Description**: `HTTPS for secure web access`
- Click **"Add Ingress Rules"**

### Add Ingress Rule for WhatsApp Bot:
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: `TCP`
- **Destination Port Range**: `3000`
- **Description**: `WhatsApp Bot API`
- Click **"Add Ingress Rules"**

### ✅ Verify: You should see 4 ingress rules total:
1. SSH (22) - default
2. HTTP (80) - just added
3. HTTPS (443) - just added
4. WhatsApp Bot (3000) - just added

---

# PHASE 4: Server Preparation (30 minutes)

## Step 4.1: Connect to Your Instance via SSH

### From Windows PowerShell:

```powershell
# Replace with YOUR public IP address
$IP = "123.45.67.89"

# Connect using your SSH key
ssh -i "$HOME\.ssh\oracle_cloud_key" ubuntu@$IP
```

### First-time connection:
- You'll see: "The authenticity of host... can't be established"
- Type `yes` and press Enter
- You should now see: `ubuntu@edutrack-whatsapp-bot:~$`

### ✅ Success: You're now inside your Oracle Cloud server!

---

## Step 4.2: Update System Packages

```bash
# Update package lists
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential
```

**Wait**: This may take 5-10 minutes

---

## Step 4.3: Configure Instance Firewall (UFW)

```bash
# Enable UFW firewall
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 3000/tcp    # WhatsApp Bot

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status
```

**Expected output**: Status: active, with rules listed

---

## Step 4.4: Install Node.js 18+

```bash
# Add NodeSource repository for Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v18.x.x
npm --version   # Should show 9.x.x or higher
```

---

## Step 4.5: Install PM2 (Process Manager)

PM2 keeps your WhatsApp bot running 24/7 and auto-restarts if it crashes.

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version

# Configure PM2 to start on system boot
pm2 startup systemd
# Copy the command it outputs and run it (starts with sudo)

# Example output command to run:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

---

## Step 4.6: Install Dependencies for WhatsApp Bot

```bash
# Install Chromium and dependencies for WhatsApp Web
sudo apt install -y \
  chromium-browser \
  libgbm1 \
  libnss3 \
  libatk-bridge2.0-0 \
  libgtk-3-0 \
  libxss1 \
  libasound2

# Create directory for WhatsApp bot
mkdir -p ~/whatsapp-bot
cd ~/whatsapp-bot
```

---

# PHASE 5: WhatsApp Bot Deployment (30 minutes)

## Step 5.1: Transfer Bot Code to Server

### Option A: Using Git (Recommended if you have GitHub repo)

```bash
cd ~/whatsapp-bot
git clone https://github.com/your-username/edu-track.git .
cd whatsapp-edutrack-bot
```

### Option B: Using SCP from Your Windows PC

#### On your Windows PowerShell (NOT in SSH session):

```powershell
# Navigate to your project
cd C:\Users\User\Desktop\FlutterProjects\edu_track\whatsapp-edutrack-bot

# Replace with YOUR Oracle Cloud IP
$IP = "123.45.67.89"

# Transfer files to server
scp -i "$HOME\.ssh\oracle_cloud_key" -r * ubuntu@${IP}:~/whatsapp-bot/
```

### Option C: Manual File Creation (If transfers fail)

We'll create the essential files directly on the server in the next steps.

---

## Step 5.2: Create WhatsApp Bot Server File

If you transferred files, skip to Step 5.3. Otherwise, create server.js:

```bash
cd ~/whatsapp-bot
nano server.js
```

Paste this content (use Ctrl+Shift+V or right-click):

```javascript
const { Client, LocalAuth } = require('whatsapp-web.js');
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// WhatsApp Client with persistent session
const client = new Client({
  authStrategy: new LocalAuth({
    dataPath: './whatsapp-session'
  }),
  puppeteer: {
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--no-first-run',
      '--no-zygote',
      '--disable-gpu'
    ]
  }
});

let qrCode = null;
let isReady = false;

client.on('qr', (qr) => {
  console.log('📱 QR CODE RECEIVED');
  console.log('Please scan this QR code with WhatsApp:');
  console.log(qr);
  qrCode = qr;
});

client.on('ready', () => {
  console.log('✅ WhatsApp client is ready!');
  isReady = true;
  qrCode = null;
});

client.on('authenticated', () => {
  console.log('🔐 WhatsApp authenticated');
});

client.on('auth_failure', () => {
  console.error('❌ Authentication failed');
  isReady = false;
});

client.on('disconnected', () => {
  console.log('📱 WhatsApp disconnected');
  isReady = false;
});

// Initialize client
client.initialize();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    whatsapp_ready: isReady,
    timestamp: new Date().toISOString()
  });
});

// Get QR code endpoint
app.get('/qr-code', (req, res) => {
  if (qrCode) {
    res.json({ qr: qrCode });
  } else if (isReady) {
    res.json({ message: 'WhatsApp is already authenticated' });
  } else {
    res.json({ message: 'Waiting for QR code...' });
  }
});

// Send message endpoint
app.post('/send-message', async (req, res) => {
  try {
    const { phoneNumber, message } = req.body;

    if (!phoneNumber || !message) {
      return res.status(400).json({ 
        error: 'Phone number and message are required' 
      });
    }

    if (!isReady) {
      return res.status(503).json({ 
        error: 'WhatsApp client not ready' 
      });
    }

    // Format phone number
    let formattedNumber = phoneNumber.replace(/[\s\-\(\)]/g, '');
    if (!formattedNumber.startsWith('+')) {
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '+94' + formattedNumber.substring(1);
      } else if (!formattedNumber.startsWith('94')) {
        formattedNumber = '+94' + formattedNumber;
      } else {
        formattedNumber = '+' + formattedNumber;
      }
    }

    const whatsappNumber = formattedNumber.replace('+', '') + '@c.us';
    const sentMessage = await client.sendMessage(whatsappNumber, message);

    res.json({ 
      success: true,
      messageId: sentMessage.id.id,
      timestamp: new Date().toISOString()
    });

    console.log(`✅ Message sent to ${formattedNumber}`);

  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({ 
      error: 'Failed to send message',
      details: error.message 
    });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 WhatsApp Bot running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/health`);
});
```

Save: `Ctrl+X`, then `Y`, then `Enter`

---

## Step 5.3: Create package.json

```bash
nano package.json
```

Paste this content:

```json
{
  "name": "edutrack-whatsapp-bot",
  "version": "1.0.0",
  "description": "WhatsApp notification bot for EduTrack",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "whatsapp-web.js": "^1.21.0",
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
```

Save: `Ctrl+X`, then `Y`, then `Enter`

---

## Step 5.4: Install Dependencies

```bash
cd ~/whatsapp-bot
npm install
```

**Wait**: This may take 2-3 minutes

---

## Step 5.5: Test WhatsApp Bot

```bash
# Start the bot manually (for testing)
node server.js
```

**Expected output**:
```
🚀 WhatsApp Bot running on port 3000
📡 Health check: http://localhost:3000/health
📱 QR CODE RECEIVED
Please scan this QR code with WhatsApp:
█████████████████████████████████
█████████████████████████████████
█████████████████████████████████
...
```

### ✅ Success: You see the QR code in terminal

---

## Step 5.6: Get QR Code for Scanning

### Option A: View QR in Terminal (if visible)
- The QR code is displayed in the SSH terminal
- Open WhatsApp on your phone
- Go to: **Settings** → **Linked Devices** → **Link a Device**
- Scan the QR code from your terminal

### Option B: Get QR via API (if terminal doesn't show QR well)

#### From your Windows PowerShell (new window):
```powershell
# Replace with your Oracle Cloud IP
$IP = "123.45.67.89"

# Get QR code
curl http://${IP}:3000/qr-code
```

You'll see the QR code text. Use an online QR code generator to visualize it.

### ✅ After scanning: You should see in terminal:
```
🔐 WhatsApp authenticated
✅ WhatsApp client is ready!
```

### Stop the test:
Press `Ctrl+C` in the SSH terminal

---

# PHASE 6: Production Setup with PM2 (30 minutes)

## Step 6.1: Create PM2 Ecosystem File

```bash
cd ~/whatsapp-bot
nano ecosystem.config.js
```

Paste this content:

```javascript
module.exports = {
  apps: [{
    name: 'whatsapp-bot',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

Save: `Ctrl+X`, then `Y`, then `Enter`

---

## Step 6.2: Create Logs Directory

```bash
mkdir -p ~/whatsapp-bot/logs
```

---

## Step 6.3: Start Bot with PM2

```bash
cd ~/whatsapp-bot

# Start the bot with PM2
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs whatsapp-bot --lines 50
```

**Expected output**:
```
┌─────┬────────────────┬─────────┬─────────┬──────────┬────────┐
│ id  │ name           │ mode    │ status  │ cpu      │ memory │
├─────┼────────────────┼─────────┼─────────┼──────────┼────────┤
│ 0   │ whatsapp-bot   │ fork    │ online  │ 0%       │ 45 MB  │
└─────┴────────────────┴─────────┴─────────┴──────────┴────────┘
```

---

## Step 6.4: Save PM2 Configuration

```bash
# Save PM2 process list
pm2 save

# Verify startup script is configured
pm2 startup systemd
```

**This ensures your bot auto-starts after server reboots!**

---

## Step 6.5: Install and Configure Nginx (Optional but Recommended)

Nginx provides:
- Reverse proxy (cleaner URLs)
- SSL/HTTPS support
- Better security

```bash
# Install Nginx
sudo apt install -y nginx

# Stop default Nginx site
sudo systemctl stop nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/whatsapp-bot
```

Paste this configuration:

```nginx
server {
    listen 80;
    server_name _;  # Replace with your domain if you have one

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Save: `Ctrl+X`, then `Y`, then `Enter`

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## Step 6.6: Test Production Setup

### From your Windows PowerShell:

```powershell
# Replace with your Oracle Cloud IP
$IP = "123.45.67.89"

# Test health endpoint (via Nginx on port 80)
curl http://${IP}/health

# Expected: {"status":"ok","whatsapp_ready":true,"timestamp":"..."}
```

### ✅ Success: Health check returns OK status!

---

# PHASE 7: Flutter App Integration (15 minutes)

## Step 7.1: Update WhatsAppDirectService

In your Flutter app, open:
`lib/app/services/whatsapp_direct_service.dart`

Update the server URL:

```dart
class WhatsAppDirectService extends GetxService {
  // Replace with YOUR Oracle Cloud public IP
  static const String _whatsappServerUrl = 'http://123.45.67.89';
  // Or with Nginx: 'http://123.45.67.89'
  // With custom domain: 'https://whatsapp.yourdomain.com'
```

---

## Step 7.2: Test End-to-End

1. **Rebuild Flutter app**:
```powershell
cd C:\Users\User\Desktop\FlutterProjects\edu_track
flutter clean
flutter pub get
flutter run
```

2. **Test attendance marking**:
   - Open Flutter app
   - Scan student QR code
   - Mark attendance
   - Verify parent receives WhatsApp message

3. **Check Oracle Cloud logs**:
```bash
# In SSH session:
pm2 logs whatsapp-bot --lines 100
```

---

# 🎯 Verification Checklist

After completing all phases, verify:

## Oracle Cloud Instance:
- [ ] Instance is running (green status)
- [ ] Public IP is accessible
- [ ] Security lists allow ports 22, 80, 443, 3000

## Server Configuration:
- [ ] Can SSH into instance
- [ ] Node.js 18+ installed
- [ ] PM2 installed and configured
- [ ] UFW firewall configured

## WhatsApp Bot:
- [ ] Bot running with PM2
- [ ] WhatsApp authenticated (QR scanned)
- [ ] Health endpoint responds: `curl http://YOUR_IP/health`
- [ ] QR endpoint accessible: `curl http://YOUR_IP/qr-code`

## Production:
- [ ] PM2 configured to auto-start on reboot
- [ ] Nginx reverse proxy working (optional)
- [ ] Bot logs accessible: `pm2 logs whatsapp-bot`

## Flutter Integration:
- [ ] WhatsAppDirectService updated with Oracle Cloud IP
- [ ] End-to-end message delivery working
- [ ] Messages received by parents in <5 seconds

---

# 🚨 Common Issues & Solutions

See: `ORACLE_CLOUD_TROUBLESHOOTING.md`

---

# 📊 What You've Achieved

### Cost:
- **Oracle Cloud**: $0/month (forever with Always Free)
- **Total**: $0/month vs $1-15/month with Firebase polling

### Performance:
- **Resources**: 2 CPU cores, 12GB RAM
- **Message delivery**: <5 seconds
- **Uptime**: 99.9%+ (24/7 operation)

### Reliability:
- **Auto-restart**: PM2 handles crashes
- **Auto-start**: Bot starts on server reboot
- **Monitoring**: PM2 logs and health checks

**🎉 You now have a professional, free, 24/7 WhatsApp notification system running on Oracle Cloud!**