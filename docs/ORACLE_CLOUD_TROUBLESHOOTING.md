# 🔧 Oracle Cloud WhatsApp Bot - Troubleshooting Guide

## 📋 Common Issues and Solutions

---

## Issue 1: Cannot Create Oracle Cloud Account

### Problem: Credit card verification fails
**Solutions**:
1. Try a different card (Visa/Mastercard work best)
2. Ensure card has international transactions enabled
3. Contact your bank to allow Oracle verification charge ($0)
4. Try a different browser (Chrome recommended)
5. Clear browser cache and cookies

### Problem: "Free tier not available in your region"
**Solutions**:
1. Choose a different home region during signup
2. Available regions: Mumbai (India), Singapore, Tokyo, etc.
3. Check: https://www.oracle.com/cloud/data-regions/

### Problem: Account stuck in "Pending verification"
**Solutions**:
1. Wait 24 hours for manual review
2. Check spam folder for Oracle emails
3. Contact Oracle Cloud Support via live chat

---

## Issue 2: SSH Connection Problems

### Problem: "Connection refused" or "Connection timed out"

**Check 1: VCN Security List**
```bash
# Verify ingress rule for SSH (port 22) exists
# In Oracle Console:
# Instance → Subnet → Security Lists → Ingress Rules
# Should have: Source 0.0.0.0/0, Protocol TCP, Port 22
```

**Check 2: Instance is running**
```bash
# Instance status should be "Running" (green)
# Public IP should be displayed
```

**Check 3: Correct SSH command**
```powershell
# Windows PowerShell:
ssh -i "$HOME\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP

# If key permissions error on Windows:
icacls "$HOME\.ssh\oracle_cloud_key" /inheritance:r
icacls "$HOME\.ssh\oracle_cloud_key" /grant:r "$env:USERNAME:R"
```

**Check 4: Use Cloud Shell (Backup method)**
```
# In Oracle Console, click terminal icon (top-right)
# Cloud Shell opens in browser
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP
```

### Problem: "Permission denied (publickey)"

**Solution 1: Verify SSH key format**
```powershell
# Public key should start with: ssh-rsa AAAAB3NzaC1yc2E...
Get-Content "$HOME\.ssh\oracle_cloud_key.pub"
```

**Solution 2: Re-add SSH key to instance**
```
# In Oracle Console:
# Instance Details → Edit → Add SSH keys
# Paste your public key again
```

**Solution 3: Use ubuntu username, not root**
```bash
# WRONG:
ssh root@YOUR_PUBLIC_IP

# CORRECT:
ssh ubuntu@YOUR_PUBLIC_IP
```

---

## Issue 3: WhatsApp Bot Not Starting

### Problem: "Cannot find module 'whatsapp-web.js'"

**Solution**:
```bash
cd ~/whatsapp-bot
npm install
# Wait for installation to complete
node server.js
```

### Problem: "Error: Failed to launch the browser process"

**Solution 1: Install Chromium dependencies**
```bash
sudo apt update
sudo apt install -y chromium-browser libgbm1 libnss3 libatk-bridge2.0-0 libgtk-3-0
```

**Solution 2: Add Puppeteer args** (already in provided server.js)
```javascript
puppeteer: {
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox'
  ]
}
```

### Problem: "EADDRINUSE: address already in use :::3000"

**Solution: Kill existing process**
```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill it
sudo kill -9 PID_NUMBER

# Or kill all node processes
pkill node
```

---

## Issue 4: QR Code Not Appearing

### Problem: QR code not visible in SSH terminal

**Solution 1: Get QR via API**
```bash
# In SSH session:
curl http://localhost:3000/qr-code

# Or from Windows:
curl http://YOUR_PUBLIC_IP:3000/qr-code
```

**Solution 2: Use online QR generator**
```
1. Copy the QR text from API response
2. Go to: https://www.qr-code-generator.com/
3. Paste text and generate QR image
4. Scan with WhatsApp
```

**Solution 3: Check bot logs**
```bash
# If using PM2:
pm2 logs whatsapp-bot

# Should show: "📱 QR CODE RECEIVED"
```

---

## Issue 5: WhatsApp Session Expired

### Problem: "WhatsApp client not ready" after some time

**Solution 1: Re-authenticate**
```bash
# Stop bot
pm2 stop whatsapp-bot

# Remove old session
rm -rf ~/whatsapp-bot/whatsapp-session

# Start bot
pm2 start whatsapp-bot

# Get new QR code
curl http://localhost:3000/qr-code

# Scan with WhatsApp
```

**Solution 2: Check session permissions**
```bash
# Ensure correct ownership
chown -R ubuntu:ubuntu ~/whatsapp-bot/whatsapp-session
chmod -R 755 ~/whatsapp-bot/whatsapp-session
```

---

## Issue 6: PM2 Process Not Auto-Starting

### Problem: Bot doesn't start after server reboot

**Solution 1: Configure PM2 startup**
```bash
pm2 startup systemd
# Copy and run the command it outputs

# Save PM2 process list
pm2 save
```

**Solution 2: Verify startup script**
```bash
# Check if systemd service exists
sudo systemctl status pm2-ubuntu

# Enable if exists
sudo systemctl enable pm2-ubuntu
```

**Solution 3: Manual reboot test**
```bash
# Reboot server
sudo reboot

# Wait 2-3 minutes, reconnect
ssh -i "$HOME\.ssh\oracle_cloud_key" ubuntu@YOUR_PUBLIC_IP

# Check PM2 status
pm2 status
# Should show bot running
```

---

## Issue 7: Cannot Access Bot from Flutter App

### Problem: Connection timeout or refused

**Check 1: Oracle VCN Security List**
```
# In Oracle Console:
# Instance → Subnet → Security Lists
# Verify ingress rule exists:
# - Source: 0.0.0.0/0
# - Protocol: TCP
# - Port: 3000 (or 80 if using Nginx)
```

**Check 2: Instance UFW firewall**
```bash
sudo ufw status
# Should show:
# 3000/tcp    ALLOW       Anywhere
# 80/tcp      ALLOW       Anywhere (if using Nginx)
```

**Check 3: Bot is running**
```bash
pm2 status
# Should show: online (green)

# Check logs
pm2 logs whatsapp-bot --lines 50
```

**Check 4: Test from server itself**
```bash
# Test locally
curl http://localhost:3000/health

# Test via public IP
curl http://YOUR_PUBLIC_IP:3000/health
```

**Check 5: Flutter app configuration**
```dart
// In whatsapp_direct_service.dart
static const String _whatsappServerUrl = 'http://YOUR_PUBLIC_IP';
// NOT: 'http://YOUR_PUBLIC_IP:3000' if using Nginx on port 80
```

---

## Issue 8: High Memory Usage

### Problem: Bot consuming too much memory

**Solution 1: Optimize Puppeteer**
```javascript
// In server.js, add to puppeteer args:
args: [
  '--disable-dev-shm-usage',
  '--disable-accelerated-2d-canvas',
  '--no-first-run',
  '--no-zygote',
  '--disable-gpu'
]
```

**Solution 2: Set PM2 memory limit**
```bash
pm2 delete whatsapp-bot

# Edit ecosystem.config.js
nano ~/whatsapp-bot/ecosystem.config.js

# Change:
max_memory_restart: '500M'  # Restart if exceeds 500MB

# Restart
pm2 start ecosystem.config.js
pm2 save
```

**Solution 3: Monitor and restart periodically**
```bash
# Add to crontab for daily restart at 3 AM
crontab -e

# Add line:
0 3 * * * pm2 restart whatsapp-bot
```

---

## Issue 9: Nginx Configuration Problems

### Problem: 502 Bad Gateway

**Solution 1: Check bot is running**
```bash
pm2 status
curl http://localhost:3000/health
```

**Solution 2: Verify Nginx configuration**
```bash
sudo nginx -t
# Should say: "syntax is ok"
```

**Solution 3: Check Nginx logs**
```bash
sudo tail -f /var/log/nginx/error.log
```

**Solution 4: Restart Nginx**
```bash
sudo systemctl restart nginx
```

---

## Issue 10: SSL Certificate Issues (If using HTTPS)

### Problem: Let's Encrypt certificate fails

**Solution 1: Install Certbot**
```bash
sudo apt install -y certbot python3-certbot-nginx
```

**Solution 2: Configure domain first**
```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/whatsapp-bot

# Change:
server_name your-domain.com;  # Replace _ with actual domain
```

**Solution 3: Obtain certificate**
```bash
sudo certbot --nginx -d your-domain.com
# Follow prompts
```

**Solution 4: Test auto-renewal**
```bash
sudo certbot renew --dry-run
```

---

## Issue 11: Messages Not Sending

### Problem: "WhatsApp client not ready"

**Check 1: Authentication status**
```bash
curl http://localhost:3000/health
# Should show: "whatsapp_ready": true
```

**Check 2: Re-authenticate if needed**
```bash
curl http://localhost:3000/qr-code
# Scan QR code with WhatsApp
```

### Problem: "Phone number is not registered on WhatsApp"

**Check 1: Phone number format**
```dart
// In Flutter, phone numbers should be:
// +94771234567 (international format with +)
// OR
// 0771234567 (local format - will be converted)
```

**Check 2: Test with your own number**
```bash
# Send test message via curl
curl -X POST http://YOUR_PUBLIC_IP:3000/send-message \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+94771234567","message":"Test from EduTrack"}'
```

---

## Issue 12: Server Performance Degradation

### Problem: Slow response times

**Solution 1: Check server resources**
```bash
# CPU and memory usage
htop

# Disk usage
df -h

# Network usage
sudo iftop
```

**Solution 2: Restart bot**
```bash
pm2 restart whatsapp-bot
```

**Solution 3: Clear logs**
```bash
# Truncate PM2 logs
pm2 flush

# Clear old logs
rm ~/whatsapp-bot/logs/*.log
```

---

## 🆘 Emergency Commands

### Quick Bot Restart:
```bash
pm2 restart whatsapp-bot
pm2 logs whatsapp-bot
```

### Complete Restart (if bot misbehaving):
```bash
pm2 delete whatsapp-bot
rm -rf ~/whatsapp-bot/whatsapp-session
pm2 start ~/whatsapp-bot/ecosystem.config.js
curl http://localhost:3000/qr-code
```

### Server Reboot:
```bash
sudo reboot
# Wait 2-3 minutes, then reconnect
```

### Check Everything:
```bash
# Instance status
pm2 status

# Bot logs
pm2 logs whatsapp-bot --lines 50

# Health check
curl http://localhost:3000/health

# Firewall status
sudo ufw status

# Nginx status (if installed)
sudo systemctl status nginx
```

---

## 📞 Getting Help

### Oracle Cloud Support:
- **Free Tier Support**: Community forums
- **Paid Support**: Create support ticket in console
- **Community**: https://community.oracle.com/cloud/

### WhatsApp Bot Issues:
- Check logs: `pm2 logs whatsapp-bot`
- GitHub Issues: https://github.com/pedroslopez/whatsapp-web.js/issues

### General Debugging:
1. Check all logs: `pm2 logs`, `sudo tail -f /var/log/nginx/error.log`
2. Test connectivity: `curl http://localhost:3000/health`
3. Verify firewall: `sudo ufw status`, Oracle Security Lists
4. Check resources: `htop`, `df -h`

---

**💡 Tip**: When asking for help, always include:
- Error messages from logs
- Output of health check
- PM2 status
- What you've tried so far