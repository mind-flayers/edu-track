#!/bin/bash

###############################################################################
# Oracle Cloud Ubuntu Instance Setup Script
# 
# This script automates the initial setup of an Oracle Cloud Ubuntu instance
# for hosting the EduTrack WhatsApp Bot.
#
# Usage:
#   chmod +x setup-oracle-instance.sh
#   ./setup-oracle-instance.sh
#
# What this script does:
#   1. Updates system packages
#   2. Installs Node.js 18.x LTS
#   3. Installs PM2 process manager
#   4. Configures Ubuntu firewall (UFW)
#   5. Creates necessary directories
#   6. Sets up log rotation
#
# Run this script AFTER you SSH into your Oracle Cloud instance
###############################################################################

set -e  # Exit on any error

echo "=================================================="
echo "🚀 Oracle Cloud Instance Setup for WhatsApp Bot"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "❌ Please do not run this script as root or with sudo"
   echo "💡 Run as ubuntu user: ./setup-oracle-instance.sh"
   exit 1
fi

echo "📋 Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo ""
echo "📋 Step 2: Installing essential tools..."
sudo apt install -y curl wget git nano htop ufw build-essential

echo ""
echo "📋 Step 3: Installing Node.js 18.x LTS..."
# Add NodeSource repository
if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "✅ Node.js repository already configured"
fi

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "✅ Node.js $NODE_VERSION installed"
echo "✅ npm $NPM_VERSION installed"

echo ""
echo "📋 Step 4: Installing PM2 process manager..."
sudo npm install -g pm2

PM2_VERSION=$(pm2 --version)
echo "✅ PM2 $PM2_VERSION installed"

echo ""
echo "📋 Step 5: Configuring Ubuntu Firewall (UFW)..."
sudo ufw --force enable
sudo ufw allow 22/tcp comment 'SSH access'
sudo ufw allow 80/tcp comment 'HTTP access'
sudo ufw allow 443/tcp comment 'HTTPS access'
sudo ufw allow 3000/tcp comment 'WhatsApp Bot API'
sudo ufw status verbose

echo ""
echo "📋 Step 6: Creating project directory..."
mkdir -p ~/edutrack-deployment
cd ~/edutrack-deployment

echo ""
echo "📋 Step 7: Configuring PM2 startup..."
# This will fail if already configured, but that's okay
pm2 startup systemd -u ubuntu --hp /home/ubuntu 2>/dev/null || true

echo ""
echo "📋 Step 8: Installing PM2 log rotation..."
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true

echo ""
echo "=================================================="
echo "✅ Oracle Cloud Instance Setup Complete!"
echo "=================================================="
echo ""
echo "📊 System Information:"
echo "  • OS: $(lsb_release -d | cut -f2)"
echo "  • Node.js: $NODE_VERSION"
echo "  • npm: $NPM_VERSION"
echo "  • PM2: $PM2_VERSION"
echo "  • User: $(whoami)"
echo "  • Home: $HOME"
echo ""
echo "🎯 Next Steps:"
echo "  1. Clone your bot repository or upload bot files"
echo "  2. Install bot dependencies: npm install"
echo "  3. Upload service-account-key.json"
echo "  4. Start bot with PM2: pm2 start ecosystem.config.js"
echo "  5. Scan WhatsApp QR code: pm2 logs"
echo "  6. Save PM2 process list: pm2 save"
echo ""
echo "📖 Full guide: See ORACLE_CLOUD_DEPLOYMENT_GUIDE.md"
echo "=================================================="
