# Oracle Cloud Free Tier Deployment Guide for Baileys WhatsApp Bot

## 🎯 Executive Summary

**Yes, Oracle Cloud Free Tier is MORE than enough for your WhatsApp bot!**

Your Baileys WhatsApp bot can run 24/7 on Oracle Cloud's **Always Free** tier with excellent performance. Oracle's free tier is one of the most generous in the industry.

### Why Oracle Cloud Free Tier is Perfect for This Project:

✅ **24/7 Uptime** - Your bot will run continuously without interruption  
✅ **Free Forever** - No time limit, truly free tier (not a trial)  
✅ **Generous Resources** - 4 ARM CPUs + 24GB RAM (way more than needed)  
✅ **Fast Network** - More than adequate for WhatsApp messaging  
✅ **200GB Storage** - Plenty for your bot and auth data  
✅ **Reliable** - Enterprise-grade infrastructure  

---

## 📊 Resource Analysis

### Your Bot Requirements:
- **CPU**: ~0.1-0.3 cores (Node.js is lightweight)
- **RAM**: ~200-500MB (Baileys is memory efficient)
- **Storage**: ~2-5GB (Node.js + dependencies + auth data)
- **Network**: Very minimal (text messages only)

### Oracle Free Tier Provides:
- **ARM Compute**: 4 OCPUs + 24GB RAM (VM.Standard.A1.Flex)
  - OR 2x AMD VMs with 1GB RAM each (VM.Standard.E2.1.Micro)
- **Storage**: 200GB Block Volume
- **Network**: 10TB outbound data/month
- **Load Balancer**: 1 flexible load balancer (10 Mbps)

### Verdict:
You're using **less than 5%** of available resources. You could run 20+ bots on one free tier instance!

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Oracle Cloud (Free Tier)                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Compute Instance (Ubuntu 22.04)               │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  PM2 Process Manager (Auto-restart & Monitor)   │  │  │
│  │  │  ┌───────────────┐    ┌──────────────────────┐  │  │  │
│  │  │  │ server-baileys│    │  firebase-bridge.js  │  │  │  │
│  │  │  │    (Port 3000)│◄───┤   (Monitors Queue)  │  │  │  │
│  │  │  └───────┬───────┘    └──────────▲───────────┘  │  │  │
│  │  │          │                       │              │  │  │
│  │  │          │ WhatsApp Web          │ Firestore    │  │  │
│  │  │          │ Connection            │ Listener     │  │  │
│  │  └──────────┼───────────────────────┼──────────────┘  │  │
│  └─────────────┼───────────────────────┼─────────────────┘  │
│                │                       │                    │
│    ┌───────────▼───────────┐          │                    │
│    │   Security Rules      │          │                    │
│    │   Port 3000 (HTTPS)   │          │                    │
│    └───────────────────────┘          │                    │
└────────────────────────────────────────┼────────────────────┘
                                         │
                ┌────────────────────────▼──────────────────┐
                │         Firebase Firestore                │
                │  whatsappQueue → Pending Messages         │
                └───────────────────────────────────────────┘
                                         ▲
                                         │
                ┌────────────────────────┴──────────────────┐
                │     Flutter App (Android/iOS)             │
                │   Marks Attendance → Queues WhatsApp Msg  │
                └───────────────────────────────────────────┘
```

---

## 📋 Detailed Implementation Plan

### Phase 1: Oracle Cloud Account Setup (15 minutes)

#### Step 1.1: Create Oracle Cloud Account
1. Go to https://www.oracle.com/cloud/free/
2. Click "Start for free"
3. Fill in your details:
   - **Email**: Use a valid email (you'll need to verify)
   - **Country**: Select Sri Lanka
   - **Phone**: Provide valid phone number
   - **Credit Card**: Required for verification (NO charges for free tier)
4. Choose your home region (closest to Sri Lanka):
   - **Recommended**: `ap-mumbai-1` (India West - Mumbai)
   - Alternative: `ap-singapore-1` (Singapore)
5. Complete email and phone verification
6. Wait for account provisioning (2-5 minutes)

#### Step 1.2: Initial Console Setup
1. Log into Oracle Cloud Console
2. Note your:
   - **Tenancy Name**
   - **Home Region**
   - **Username**
3. Set up Multi-Factor Authentication (optional but recommended)

---

### Phase 2: Create Virtual Cloud Network (VCN) (10 minutes)

#### Step 2.1: Create VCN Using Wizard
1. In Oracle Console, navigate to: **Networking** → **Virtual Cloud Networks**
2. Click **"Start VCN Wizard"**
3. Select **"Create VCN with Internet Connectivity"**
4. Click **"Start VCN Wizard"**
5. Configure:
   ```
   VCN Name: edutrack-whatsapp-vcn
   Compartment: (root)
   VCN CIDR Block: 10.0.0.0/16
   Public Subnet CIDR: 10.0.0.0/24
   Private Subnet CIDR: 10.0.1.0/24
   ```
6. Click **"Next"** → **"Create"**
7. Wait for VCN creation (1-2 minutes)

#### Step 2.2: Configure Security List (Open Required Ports)
1. In your VCN, go to **Security Lists** → **Default Security List**
2. Click **"Add Ingress Rules"** and add:

   **Rule 1: SSH Access**
   ```
   Source CIDR: 0.0.0.0/0
   IP Protocol: TCP
   Source Port Range: All
   Destination Port Range: 22
   Description: SSH access
   ```

   **Rule 2: HTTP Access**
   ```
   Source CIDR: 0.0.0.0/0
   IP Protocol: TCP
   Source Port Range: All
   Destination Port Range: 80
   Description: HTTP access
   ```

   **Rule 3: HTTPS Access**
   ```
   Source CIDR: 0.0.0.0/0
   IP Protocol: TCP
   Source Port Range: All
   Destination Port Range: 443
   Description: HTTPS access
   ```

   **Rule 4: WhatsApp Bot Port (Optional - for testing)**
   ```
   Source CIDR: 0.0.0.0/0
   IP Protocol: TCP
   Source Port Range: All
   Destination Port Range: 3000
   Description: WhatsApp bot API (temporary)
   ```

3. Click **"Add Ingress Rules"**

---

### Phase 3: Create Compute Instance (10 minutes)

#### Step 3.1: Launch Instance
1. Navigate to: **Compute** → **Instances**
2. Click **"Create Instance"**
3. Configure:

   **Basic Information:**
   ```
   Name: edutrack-whatsapp-bot
   Compartment: (root)
   Availability Domain: (any - default is fine)
   ```

   **Image and Shape:**
   - Click **"Change Image"**
   - Select: **Ubuntu 22.04** (Always Free Eligible)
   - Click **"Select Image"**
   
   - Click **"Change Shape"**
   - Select **"Ampere"** (ARM-based)
   - Select: **VM.Standard.A1.Flex**
   - Configure:
     ```
     OCPUs: 2 (or 4 if you want)
     Memory: 12GB (or 24GB if you want)
     ```
   - Click **"Select Shape"**

   **Networking:**
   ```
   Virtual Cloud Network: edutrack-whatsapp-vcn
   Subnet: Public Subnet (edutrack-whatsapp-vcn)
   Assign Public IPv4 Address: ✅ Yes
   ```

   **Add SSH Keys:**
   - Choose: **"Generate a key pair for me"**
   - Click **"Save Private Key"** (save as `oracle-edutrack-ssh.key`)
   - Click **"Save Public Key"** (optional, save as `oracle-edutrack-ssh.pub`)

   **Boot Volume:**
   ```
   Boot Volume Size: 50 GB (default is fine)
   ```

4. Click **"Create"**
5. Wait for instance to provision (2-3 minutes)
6. **Note the Public IP Address** (e.g., `132.145.XX.XX`)

---

### Phase 4: Configure Ubuntu Instance (20 minutes)

#### Step 4.1: Connect to Instance via SSH

**On Windows (PowerShell):**
```powershell
# Set correct permissions for SSH key
icacls "oracle-edutrack-ssh.key" /inheritance:r
icacls "oracle-edutrack-ssh.key" /grant:r "${env:USERNAME}:(R)"

# Connect to instance
ssh -i oracle-edutrack-ssh.key ubuntu@YOUR_PUBLIC_IP
```

**On Mac/Linux:**
```bash
chmod 400 oracle-edutrack-ssh.key
ssh -i oracle-edutrack-ssh.key ubuntu@YOUR_PUBLIC_IP
```

#### Step 4.2: Initial System Setup
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git nano ufw

# Configure firewall (Ubuntu's built-in firewall)
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 3000/tcp    # WhatsApp Bot API
sudo ufw enable            # Enable firewall
sudo ufw status            # Verify rules
```

#### Step 4.3: Install Node.js 18.x (LTS)
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js and npm
sudo apt install -y nodejs

# Verify installation
node --version    # Should show v18.x.x
npm --version     # Should show 9.x.x or higher

# Install PM2 globally (process manager)
sudo npm install -g pm2

# Verify PM2 installation
pm2 --version
```

---

### Phase 5: Deploy WhatsApp Bot (15 minutes)

#### Step 5.1: Clone Your Bot Code

**Option A: Using Git (Recommended)**
```bash
# Install Git if not already installed
sudo apt install -y git

# Clone your repository (replace with your repo URL)
cd ~
git clone https://github.com/mind-flayers/edu-track.git
cd edu-track/whatsapp-edutrack-bot
```

**Option B: Manual Upload (Alternative)**
```bash
# On your local machine (Windows PowerShell)
# Compress your bot folder
cd C:\Users\User\Desktop\FlutterProjects\edu_track
tar -czf whatsapp-bot.tar.gz whatsapp-edutrack-bot

# Upload to Oracle Cloud
scp -i oracle-edutrack-ssh.key whatsapp-bot.tar.gz ubuntu@YOUR_PUBLIC_IP:~/

# On Oracle Cloud instance
cd ~
tar -xzf whatsapp-bot.tar.gz
cd whatsapp-edutrack-bot
```

#### Step 5.2: Install Dependencies
```bash
cd ~/edu-track/whatsapp-edutrack-bot

# Install Node.js dependencies
npm install

# Verify installation
ls node_modules | wc -l    # Should show many packages installed
```

#### Step 5.3: Upload Service Account Key
```bash
# On your local Windows machine
scp -i oracle-edutrack-ssh.key "C:\Users\User\Desktop\FlutterProjects\edu_track\whatsapp-edutrack-bot\service-account-key.json" ubuntu@YOUR_PUBLIC_IP:~/edu-track/whatsapp-edutrack-bot/
```

#### Step 5.4: Configure Environment
```bash
cd ~/edu-track/whatsapp-edutrack-bot

# Create .env file (optional, for additional config)
nano .env
```

Add (if needed):
```env
PORT=3000
NODE_ENV=production
```

---

### Phase 6: Setup PM2 for 24/7 Operation (10 minutes)

#### Step 6.1: Create PM2 Ecosystem File
```bash
cd ~/edu-track/whatsapp-edutrack-bot
nano ecosystem.config.js
```

Add this configuration:
```javascript
module.exports = {
  apps: [
    {
      name: 'whatsapp-bot',
      script: 'server-baileys.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: 'logs/error.log',
      out_file: 'logs/output.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      time: true
    },
    {
      name: 'firebase-bridge',
      script: 'firebase-bridge.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: 'logs/bridge-error.log',
      out_file: 'logs/bridge-output.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      time: true
    }
  ]
};
```

#### Step 6.2: Create Logs Directory
```bash
mkdir -p logs
```

#### Step 6.3: Start Services with PM2
```bash
# Start both services
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs in real-time
pm2 logs

# View specific app logs
pm2 logs whatsapp-bot
pm2 logs firebase-bridge
```

#### Step 6.4: Configure PM2 to Start on Boot
```bash
# Generate startup script
pm2 startup

# This will output a command - COPY AND RUN IT
# It will look like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Save current PM2 process list
pm2 save

# Test reboot (optional)
sudo reboot

# After reboot, SSH back in and check
pm2 status    # Should show your apps running
```

---

### Phase 7: Authenticate WhatsApp (5 minutes)

#### Step 7.1: View QR Code for WhatsApp Authentication
```bash
cd ~/edu-track/whatsapp-edutrack-bot

# View logs to see QR code
pm2 logs whatsapp-bot

# You should see a QR code in ASCII art
```

#### Step 7.2: Scan QR Code
1. Open WhatsApp on your phone
2. Go to **Settings** → **Linked Devices**
3. Tap **"Link a Device"**
4. Scan the QR code from your terminal

#### Step 7.3: Verify Connection
```bash
# Check logs for successful connection
pm2 logs whatsapp-bot

# You should see:
# ✅ WhatsApp connected successfully!
# 🎯 Bot is ready to send messages

# Test the bot
curl http://localhost:3000/health

# Should return:
# {"status":"online","whatsapp_ready":true,...}
```

---

### Phase 8: Test End-to-End (5 minutes)

#### Step 8.1: Test from Flutter App
1. Open your Flutter app on Android
2. Scan a student QR code
3. Mark attendance
4. Check if WhatsApp message is sent to parent

#### Step 8.2: Monitor Logs
```bash
# Watch both services in real-time
pm2 logs

# Check Firebase Bridge
# You should see:
# 📤 Processing message...
# ✅ Message sent successfully...

# Check WhatsApp Bot
# You should see:
# 📤 Sending message to 9477...
# ✅ Message sent successfully to 9477...
```

#### Step 8.3: Test Direct API Call
```bash
# Test sending a message directly
curl -X POST http://localhost:3000/send-message \
  -H "Content-Type: application/json" \
  -d '{
    "number": "94757593737",
    "message": "🎉 EduTrack WhatsApp Bot is now running 24/7 on Oracle Cloud!"
  }'
```

---

### Phase 9: Production Hardening (Optional - 15 minutes)

#### Step 9.1: Setup Nginx Reverse Proxy (Optional)
```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/whatsapp-bot
```

Add:
```nginx
server {
    listen 80;
    server_name YOUR_PUBLIC_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Test
curl http://YOUR_PUBLIC_IP/health
```

#### Step 9.2: Setup Let's Encrypt SSL (If you have a domain)
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace yourdomain.com)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

#### Step 9.3: Setup Log Rotation
```bash
# PM2 handles log rotation, but configure it
pm2 install pm2-logrotate

# Configure (optional)
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

---

## 🔐 Security Best Practices

### 1. SSH Security
```bash
# Disable password authentication (use key-only)
sudo nano /etc/ssh/sshd_config

# Change these lines:
PasswordAuthentication no
PermitRootLogin no

# Restart SSH
sudo systemctl restart sshd
```

### 2. Firewall Rules
```bash
# Keep only essential ports open
sudo ufw status

# Remove port 3000 if using Nginx
sudo ufw delete allow 3000/tcp
```

### 3. Regular Updates
```bash
# Setup automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### 4. Backup Auth Data
```bash
# Backup WhatsApp auth_info regularly
cd ~/edu-track/whatsapp-edutrack-bot
tar -czf auth_backup_$(date +%Y%m%d).tar.gz auth_info/

# Download to local machine
# On your Windows machine:
scp -i oracle-edutrack-ssh.key ubuntu@YOUR_PUBLIC_IP:~/edu-track/whatsapp-edutrack-bot/auth_backup_*.tar.gz .
```

---

## 📊 Monitoring & Maintenance

### Daily Monitoring Commands
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs --lines 100

# Check system resources
htop  # or: top

# Check disk usage
df -h

# Check memory usage
free -h

# Check network status
netstat -tuln | grep 3000
```

### PM2 Useful Commands
```bash
# Restart a specific app
pm2 restart whatsapp-bot

# Restart all apps
pm2 restart all

# Stop an app
pm2 stop whatsapp-bot

# Delete an app from PM2
pm2 delete whatsapp-bot

# View detailed info
pm2 info whatsapp-bot

# Monitor in real-time
pm2 monit

# Flush logs
pm2 flush
```

### Update Bot Code
```bash
# Pull latest changes (if using Git)
cd ~/edu-track/whatsapp-edutrack-bot
git pull

# Install any new dependencies
npm install

# Restart services
pm2 restart all

# Check logs
pm2 logs
```

---

## 🚨 Troubleshooting

### Problem 1: Instance Not Accessible
```bash
# Check if instance is running in Oracle Console
# Check Security List rules
# Check Ubuntu firewall
sudo ufw status

# Check if SSH service is running
sudo systemctl status sshd
```

### Problem 2: WhatsApp Not Connecting
```bash
# Check if bot is running
pm2 status

# View logs
pm2 logs whatsapp-bot

# Delete old auth_info and re-authenticate
pm2 stop whatsapp-bot
rm -rf auth_info/
pm2 start whatsapp-bot
pm2 logs  # Scan new QR code
```

### Problem 3: Firebase Bridge Not Working
```bash
# Check if service account key exists
ls -l service-account-key.json

# Check Firebase Bridge logs
pm2 logs firebase-bridge

# Test Firebase connection
node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
console.log('✅ Firebase connected');
"
```

### Problem 4: Out of Memory
```bash
# Check memory usage
free -h

# Check PM2 memory limits
pm2 info whatsapp-bot

# Restart apps to clear memory
pm2 restart all
```

### Problem 5: Messages Not Sending
```bash
# Check bot health
curl http://localhost:3000/health

# Check if WhatsApp is ready
pm2 logs whatsapp-bot | grep "ready"

# Check pending messages in Firestore
# (Use Firebase Console)

# Manually trigger a message
curl -X POST http://localhost:3000/send-message \
  -H "Content-Type: application/json" \
  -d '{"number":"94757593737","message":"Test"}'
```

---

## 💰 Cost Analysis

### Oracle Cloud Free Tier Costs:
- **Compute Instance**: $0.00 (Always Free)
- **Block Storage**: $0.00 (Always Free - 200GB included)
- **Outbound Data**: $0.00 (10TB/month included)
- **Public IP**: $0.00 (Included with instance)

### Total Monthly Cost: **$0.00**

### What Happens After 30-Day Trial:
- **Free tier continues indefinitely**
- No charges as long as you stay within free tier limits
- Your bot will keep running 24/7 for free

---

## 🎉 Success Checklist

After following this guide, you should have:

- ✅ Oracle Cloud account created
- ✅ VCN and security rules configured
- ✅ Ubuntu instance running 24/7
- ✅ Node.js and PM2 installed
- ✅ WhatsApp bot deployed and running
- ✅ Firebase bridge monitoring queue
- ✅ WhatsApp authenticated and connected
- ✅ PM2 auto-start on boot configured
- ✅ Firewall and security configured
- ✅ Monitoring and logging set up
- ✅ End-to-end testing completed

---

## 📞 Support & Resources

### Oracle Cloud Resources:
- **Documentation**: https://docs.oracle.com/iaas/
- **Free Tier FAQ**: https://www.oracle.com/cloud/free/faq/
- **Support**: https://www.oracle.com/support/

### Your Bot Resources:
- **Baileys Documentation**: https://whiskeysockets.github.io/Baileys/
- **PM2 Documentation**: https://pm2.keymetrics.io/
- **Firebase Admin SDK**: https://firebase.google.com/docs/admin/setup

### Community:
- **Baileys Discord**: https://discord.gg/WeJM5FP9GG
- **Oracle Cloud Community**: https://community.oracle.com/

---

## 🚀 Next Steps

1. **Setup monitoring alerts** - Configure PM2 Plus or use Oracle Cloud monitoring
2. **Setup domain name** - Point a domain to your public IP (optional)
3. **Configure SSL certificate** - Use Let's Encrypt for HTTPS (optional)
4. **Setup automated backups** - Backup auth_info daily
5. **Document your deployment** - Keep notes on your specific configuration
6. **Test failover** - Simulate crashes and verify auto-restart
7. **Setup health check endpoint** - For external monitoring services

---

## 📝 Notes

- **Auth Data Persistence**: Your `auth_info` folder contains WhatsApp session data. Back it up regularly!
- **Firestore Limits**: Firebase free tier allows 50,000 reads/day - more than enough
- **Oracle Idle Policy**: Keep CPU usage >20% to avoid instance reclamation (your bot will do this naturally)
- **WhatsApp Limits**: WhatsApp may ban accounts for excessive messaging - implement rate limiting
- **Instance Reboot**: After maintenance reboots, PM2 auto-starts your bot

---

**🎊 Congratulations! Your WhatsApp bot is now running 24/7 on Oracle Cloud for FREE! 🎊**
