# 🚀 Quick Start Guide - Oracle Cloud Deployment

## Prerequisites Checklist
- [ ] Oracle Cloud account created
- [ ] Credit card added (for verification only)
- [ ] SSH key pair downloaded
- [ ] service-account-key.json ready

## ⚡ Super Quick Setup (30 minutes)

### 1. Create Oracle Cloud Instance (5 min)
```bash
# In Oracle Console:
1. Compute → Instances → Create Instance
2. Name: edutrack-whatsapp-bot
3. Image: Ubuntu 22.04
4. Shape: VM.Standard.A1.Flex (2 OCPUs, 12GB RAM)
5. VCN: Create new with internet connectivity
6. SSH Key: Generate and download
7. Note your Public IP: __________________
```

### 2. Connect to Instance (1 min)
```powershell
# Windows PowerShell
ssh -i oracle-edutrack-ssh.key ubuntu@YOUR_PUBLIC_IP
```

### 3. Setup Instance (10 min)
```bash
# Copy and paste this entire block
curl -fsSL https://raw.githubusercontent.com/mind-flayers/edu-track/main/whatsapp-edutrack-bot/setup-oracle-instance.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

### 4. Deploy Bot (10 min)
```bash
# Clone repository
git clone https://github.com/mind-flayers/edu-track.git
cd edu-track/whatsapp-edutrack-bot

# Upload service account key from local machine
# (Run this on your Windows machine)
scp -i oracle-edutrack-ssh.key "C:\Users\User\Desktop\FlutterProjects\edu_track\whatsapp-edutrack-bot\service-account-key.json" ubuntu@YOUR_PUBLIC_IP:~/edu-track/whatsapp-edutrack-bot/

# Back on Oracle instance - deploy
chmod +x deploy-bot.sh
./deploy-bot.sh
```

### 5. Authenticate WhatsApp (3 min)
```bash
# View QR code
pm2 logs whatsapp-bot

# Scan with WhatsApp → Settings → Linked Devices → Link a Device
```

### 6. Test (1 min)
```bash
# Check health
curl http://localhost:3000/health

# Send test message
curl -X POST http://localhost:3000/send-message \
  -H "Content-Type: application/json" \
  -d '{"number":"94757593737","message":"Bot is live!"}'
```

## 🎯 Essential Commands

### PM2 Process Management
```bash
pm2 status              # Check service status
pm2 logs                # View all logs
pm2 logs whatsapp-bot   # View bot logs only
pm2 restart all         # Restart all services
pm2 stop all            # Stop all services
pm2 monit               # Real-time monitor
```

### Monitoring
```bash
htop                    # System resources
df -h                   # Disk usage
free -h                 # Memory usage
pm2 logs --lines 100    # Last 100 log lines
```

### Troubleshooting
```bash
# WhatsApp not connecting
pm2 restart whatsapp-bot
pm2 logs whatsapp-bot

# Firebase not working
pm2 restart firebase-bridge
pm2 logs firebase-bridge

# Bot not sending messages
curl http://localhost:3000/health  # Check if ready
pm2 logs                            # Check for errors
```

## 🔒 Security Quick Config

### Open Required Ports
```bash
# In Oracle Console Security Lists:
Port 22  (SSH)    - Your IP only (recommended)
Port 80  (HTTP)   - 0.0.0.0/0
Port 443 (HTTPS)  - 0.0.0.0/0
Port 3000 (Bot)   - 0.0.0.0/0 (or remove after Nginx setup)
```

### Ubuntu Firewall
```bash
sudo ufw status
sudo ufw enable
```

## 📊 Resource Usage

Your bot typically uses:
- **CPU**: 5-15% (mostly idle)
- **RAM**: 200-400MB
- **Disk**: 2-3GB
- **Network**: Minimal (<100MB/day)

Oracle Free Tier provides:
- **CPU**: 4 cores (2000% more than needed!)
- **RAM**: 12-24GB (3000% more than needed!)
- **Disk**: 50GB (1500% more than needed!)

You're golden! 🎉

## 🆘 Emergency Commands

### Bot Crashed
```bash
pm2 restart all
pm2 logs
```

### WhatsApp Disconnected
```bash
pm2 restart whatsapp-bot
pm2 logs whatsapp-bot
# Wait for QR code, rescan if needed
```

### Out of Memory
```bash
pm2 restart all
free -h
```

### Update Bot Code
```bash
cd ~/edu-track
git pull
cd whatsapp-edutrack-bot
npm install
pm2 restart all
```

## 📞 Quick Reference

- **Oracle Console**: https://cloud.oracle.com
- **Instance IP**: YOUR_PUBLIC_IP
- **Bot Health**: http://YOUR_PUBLIC_IP:3000/health
- **SSH Command**: `ssh -i oracle-edutrack-ssh.key ubuntu@YOUR_PUBLIC_IP`

## 📖 Full Documentation

For detailed step-by-step instructions, see:
- `ORACLE_CLOUD_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `README.md` - Bot architecture and features

## ✅ Success Indicators

Your bot is working correctly when:
1. `pm2 status` shows both apps as "online"
2. `curl http://localhost:3000/health` returns `"whatsapp_ready":true`
3. Test message sends successfully
4. Flutter app attendance triggers WhatsApp messages

---

**🎊 Your bot is now running 24/7 for FREE on Oracle Cloud! 🎊**

Last updated: 2025-11-09
