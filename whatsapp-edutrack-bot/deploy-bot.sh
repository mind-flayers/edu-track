#!/bin/bash

###############################################################################
# WhatsApp Bot Deployment Script
# 
# This script deploys the WhatsApp bot after the Oracle instance is set up.
#
# Prerequisites:
#   - Oracle instance setup completed (run setup-oracle-instance.sh first)
#   - service-account-key.json uploaded to this directory
#   - Node.js and PM2 installed
#
# Usage:
#   chmod +x deploy-bot.sh
#   ./deploy-bot.sh
###############################################################################

set -e  # Exit on any error

echo "=================================================="
echo "🤖 Deploying EduTrack WhatsApp Bot"
echo "=================================================="
echo ""

# Check if service account key exists
if [ ! -f "service-account-key.json" ]; then
    echo "❌ Error: service-account-key.json not found!"
    echo "💡 Please upload your Firebase service account key to this directory"
    echo ""
    echo "On your local machine, run:"
    echo "  scp -i oracle-edutrack-ssh.key service-account-key.json ubuntu@YOUR_IP:~/edu-track/whatsapp-edutrack-bot/"
    exit 1
fi

echo "✅ service-account-key.json found"

echo ""
echo "📋 Step 1: Installing Node.js dependencies..."
npm install

echo ""
echo "📋 Step 2: Creating logs directory..."
mkdir -p logs

echo ""
echo "📋 Step 3: Checking ecosystem.config.js..."
if [ ! -f "ecosystem.config.js" ]; then
    echo "❌ Error: ecosystem.config.js not found!"
    exit 1
fi
echo "✅ ecosystem.config.js found"

echo ""
echo "📋 Step 4: Stopping any existing PM2 processes..."
pm2 delete all 2>/dev/null || true

echo ""
echo "📋 Step 5: Starting services with PM2..."
pm2 start ecosystem.config.js

echo ""
echo "📋 Step 6: Waiting for services to initialize..."
sleep 5

echo ""
echo "📋 Step 7: Checking service status..."
pm2 status

echo ""
echo "📋 Step 8: Saving PM2 process list..."
pm2 save

echo ""
echo "=================================================="
echo "🎉 WhatsApp Bot Deployment Complete!"
echo "=================================================="
echo ""
echo "📊 Service Status:"
pm2 status
echo ""
echo "📱 WhatsApp Authentication Required:"
echo "  1. View logs to see QR code: pm2 logs whatsapp-bot"
echo "  2. Open WhatsApp on your phone"
echo "  3. Go to Settings → Linked Devices"
echo "  4. Tap 'Link a Device'"
echo "  5. Scan the QR code from the terminal"
echo ""
echo "🔍 Monitoring Commands:"
echo "  • View all logs: pm2 logs"
echo "  • View bot logs: pm2 logs whatsapp-bot"
echo "  • View bridge logs: pm2 logs firebase-bridge"
echo "  • Check status: pm2 status"
echo "  • Monitor: pm2 monit"
echo ""
echo "🧪 Test Commands:"
echo "  • Test health: curl http://localhost:3000/health"
echo "  • Test message: curl -X POST http://localhost:3000/send-message -H 'Content-Type: application/json' -d '{\"number\":\"94757593737\",\"message\":\"Test\"}'"
echo ""
echo "📖 Full documentation: ORACLE_CLOUD_DEPLOYMENT_GUIDE.md"
echo "=================================================="
