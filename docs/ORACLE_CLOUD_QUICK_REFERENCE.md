# ⚡ Oracle Cloud WhatsApp Bot - Quick Reference

## 🚀 Quick Start Commands

### Initial Setup (First Time Only)

```bash
# 1. Connect to server
ssh -i "$HOME\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP

# 2. Update system
sudo apt update && sudo apt upgrade -y

# 3. Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 4. Install PM2
sudo npm install -g pm2

# 5. Configure UFW firewall
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 3000/tcp
sudo ufw --force enable

# 6. Install WhatsApp dependencies
sudo apt install -y chromium-browser libgbm1 libnss3 libatk-bridge2.0-0 libgtk-3-0

# 7. Create bot directory
mkdir -p ~/whatsapp-bot && cd ~/whatsapp-bot
```

---

## 📦 Deploy Bot (Copy-Paste Script)

### Full Automated Setup Script

Save this as `setup.sh` on your Oracle Cloud server:

```bash
#!/bin/bash
echo "🚀 Setting up WhatsApp Bot on Oracle Cloud..."

# Navigate to bot directory
cd ~/whatsapp-bot

# Create package.json
cat > package.json << 'EOF'
{
  "name": "edutrack-whatsapp-bot",
  "version": "1.0.0",
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
EOF

# Install dependencies
echo "📦 Installing npm packages..."
npm install

# Create PM2 ecosystem config
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'whatsapp-bot',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    time: true
  }]
};
EOF

# Create logs directory
mkdir -p logs

# Configure PM2 startup
pm2 startup systemd | tail -1 | bash
pm2 save

echo "✅ Setup complete!"
echo "📋 Next steps:"
echo "1. Upload server.js to ~/whatsapp-bot/"
echo "2. Run: pm2 start ecosystem.config.js"
echo "3. Run: curl http://localhost:3000/qr-code"
echo "4. Scan QR code with WhatsApp"
```

**Run it:**
```bash
chmod +x setup.sh
./setup.sh
```

---

## 📝 Essential Daily Commands

### Check Bot Status
```bash
pm2 status
```

### View Bot Logs
```bash
# Last 50 lines
pm2 logs whatsapp-bot --lines 50

# Live monitoring
pm2 logs whatsapp-bot
```

### Restart Bot
```bash
pm2 restart whatsapp-bot
```

### Stop Bot
```bash
pm2 stop whatsapp-bot
```

### Start Bot
```bash
pm2 start whatsapp-bot
# Or
pm2 start ~/whatsapp-bot/ecosystem.config.js
```

### Check Health
```bash
curl http://localhost:3000/health
```

### Get QR Code
```bash
curl http://localhost:3000/qr-code
```

---

## 🔥 Emergency Commands

### Bot Not Responding
```bash
pm2 restart whatsapp-bot
pm2 logs whatsapp-bot
```

### Complete Bot Reset
```bash
pm2 delete whatsapp-bot
rm -rf ~/whatsapp-bot/whatsapp-session
pm2 start ~/whatsapp-bot/ecosystem.config.js
```

### Server Reboot
```bash
sudo reboot
# Wait 2-3 minutes, then reconnect
```

### Check What's Using Port 3000
```bash
sudo lsof -i :3000
```

### Kill Process on Port 3000
```bash
sudo kill -9 $(sudo lsof -t -i:3000)
```

---

## 🌐 Nginx Commands (If Installed)

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Test Nginx Configuration
```bash
sudo nginx -t
```

### View Nginx Logs
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 📊 Monitoring Commands

### System Resources
```bash
# CPU and Memory
htop

# Disk usage
df -h

# Memory usage
free -h

# Processes
top
```

### Network
```bash
# Check if port 3000 is listening
sudo netstat -tulpn | grep 3000

# Test external connectivity
curl http://YOUR_PUBLIC_IP:3000/health
```

---

## 🔐 Security Commands

### Check Firewall Status
```bash
sudo ufw status
```

### Add Firewall Rule
```bash
sudo ufw allow PORT/tcp
```

### View Active Connections
```bash
sudo netstat -tupln
```

---

## 📁 File Transfer Commands

### From Windows to Oracle Cloud
```powershell
# Transfer single file
scp -i "$HOME\.ssh\oracle_cloud_key" "C:\path\to\file.js" ubuntu@YOUR_PUBLIC_IP:~/whatsapp-bot/

# Transfer directory
scp -i "$HOME\.ssh\oracle_cloud_key" -r "C:\path\to\folder" ubuntu@YOUR_PUBLIC_IP:~/whatsapp-bot/
```

### From Oracle Cloud to Windows
```powershell
scp -i "$HOME\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP:~/whatsapp-bot/file.js "C:\path\to\destination\"
```

---

## 🧹 Maintenance Commands

### Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### Update Node.js Packages
```bash
cd ~/whatsapp-bot
npm update
```

### Clear PM2 Logs
```bash
pm2 flush
```

### Clean Old Session
```bash
rm -rf ~/whatsapp-bot/whatsapp-session
```

### Check Disk Space
```bash
df -h
du -sh ~/whatsapp-bot
```

---

## 🧪 Testing Commands

### Test Message Sending
```bash
curl -X POST http://localhost:3000/send-message \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+94771234567","message":"Test from EduTrack"}'
```

### Test Health Endpoint
```bash
curl http://localhost:3000/health
```

### Test from External Network
```powershell
# From Windows
curl http://YOUR_PUBLIC_IP:3000/health
```

---

## 📱 WhatsApp Re-authentication

### Get New QR Code
```bash
# Stop bot
pm2 stop whatsapp-bot

# Clear session
rm -rf ~/whatsapp-bot/whatsapp-session

# Start bot
pm2 start whatsapp-bot

# Wait 10 seconds, then get QR
curl http://localhost:3000/qr-code
```

### Check Authentication Status
```bash
curl http://localhost:3000/health | jq '.whatsapp_ready'
# Should show: true
```

---

## 💾 Backup Commands

### Backup WhatsApp Session
```bash
tar -czf ~/whatsapp-session-backup.tar.gz ~/whatsapp-bot/whatsapp-session
```

### Restore WhatsApp Session
```bash
pm2 stop whatsapp-bot
tar -xzf ~/whatsapp-session-backup.tar.gz -C ~/
pm2 start whatsapp-bot
```

### Backup Bot Configuration
```bash
tar -czf ~/bot-backup.tar.gz ~/whatsapp-bot --exclude=node_modules --exclude=whatsapp-session
```

---

## 🔄 Update Bot Code

### Manual Update
```bash
# Stop bot
pm2 stop whatsapp-bot

# Edit server.js
nano ~/whatsapp-bot/server.js

# Start bot
pm2 start whatsapp-bot
```

### Update from Git
```bash
cd ~/whatsapp-bot
git pull origin main
npm install
pm2 restart whatsapp-bot
```

---

## 📞 Get Server Information

### Public IP Address
```bash
curl ifconfig.me
```

### Instance Details
```bash
# Hostname
hostname

# OS version
lsb_release -a

# Node.js version
node --version

# PM2 version
pm2 --version

# Nginx version (if installed)
nginx -v
```

---

## ⚙️ Configuration Locations

### Important Files
```
~/whatsapp-bot/server.js              - Main bot code
~/whatsapp-bot/package.json           - Dependencies
~/whatsapp-bot/ecosystem.config.js    - PM2 configuration
~/whatsapp-bot/whatsapp-session/      - WhatsApp session data
~/whatsapp-bot/logs/                  - PM2 logs
/etc/nginx/sites-available/whatsapp-bot - Nginx config (if installed)
```

### View Configuration
```bash
# PM2 config
cat ~/whatsapp-bot/ecosystem.config.js

# Nginx config
sudo cat /etc/nginx/sites-available/whatsapp-bot
```

---

## 🎯 One-Liner Quick Checks

```bash
# Everything check
pm2 status && curl http://localhost:3000/health && sudo ufw status

# Bot health
curl -s http://localhost:3000/health | jq '.'

# System health
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')" && echo "Mem: $(free -h | grep Mem | awk '{print $3 "/" $2}')" && echo "Disk: $(df -h / | tail -1 | awk '{print $5}')"

# Check if WhatsApp is ready
curl -s http://localhost:3000/health | jq -r '.whatsapp_ready'
```

---

## 🆘 Troubleshooting One-Liners

```bash
# Why is bot not starting?
pm2 logs whatsapp-bot --lines 100 --nostream

# Is port 3000 blocked?
sudo ufw status | grep 3000

# Can I reach the bot externally?
curl -v http://YOUR_PUBLIC_IP:3000/health

# What's using memory?
ps aux --sort=-%mem | head -10

# Clear everything and restart
pm2 delete whatsapp-bot && rm -rf ~/whatsapp-bot/whatsapp-session && pm2 start ~/whatsapp-bot/ecosystem.config.js
```

---

## 📚 Useful Aliases (Add to ~/.bashrc)

```bash
# Add these to ~/.bashrc for quick commands
nano ~/.bashrc

# Add at end:
alias bot-status='pm2 status'
alias bot-logs='pm2 logs whatsapp-bot'
alias bot-restart='pm2 restart whatsapp-bot'
alias bot-health='curl http://localhost:3000/health'
alias bot-qr='curl http://localhost:3000/qr-code'

# Save and reload
source ~/.bashrc
```

**Now you can use**:
- `bot-status` - Check bot status
- `bot-logs` - View logs
- `bot-restart` - Restart bot
- `bot-health` - Health check
- `bot-qr` - Get QR code

---

**💡 Pro Tip**: Bookmark this page for quick reference during daily operations!