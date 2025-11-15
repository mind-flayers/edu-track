#!/bin/bash

###############################################################################
# WhatsApp Auth Backup Script
# 
# This script backs up the WhatsApp authentication data (auth_info folder)
# to prevent losing your WhatsApp session.
#
# Usage:
#   chmod +x backup-auth.sh
#   ./backup-auth.sh
#
# Schedule with cron (daily backup at 2 AM):
#   crontab -e
#   0 2 * * * /home/ubuntu/edu-track/whatsapp-edutrack-bot/backup-auth.sh
###############################################################################

# Configuration
BACKUP_DIR="$HOME/whatsapp-backups"
AUTH_DIR="./auth_info"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="auth_backup_${DATE}.tar.gz"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================================="
echo "🔐 WhatsApp Authentication Backup"
echo "=================================================="
echo ""

# Check if auth_info exists
if [ ! -d "$AUTH_DIR" ]; then
    echo -e "${RED}❌ Error: auth_info directory not found${NC}"
    echo "💡 Make sure you're in the whatsapp-edutrack-bot directory"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📋 Backup Details:"
echo "  Source: $AUTH_DIR"
echo "  Destination: $BACKUP_DIR/$BACKUP_FILE"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Create backup
echo "📦 Creating backup..."
if tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$AUTH_DIR" 2>/dev/null; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup created successfully${NC}"
    echo "  File: $BACKUP_FILE"
    echo "  Size: $BACKUP_SIZE"
else
    echo -e "${RED}❌ Backup failed${NC}"
    exit 1
fi

echo ""

# List all backups
echo "📚 Available Backups:"
ls -lh "$BACKUP_DIR" | grep "auth_backup" | awk '{print "  " $9 " - " $5}'

echo ""

# Clean old backups
echo "🧹 Cleaning old backups (older than $RETENTION_DAYS days)..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "auth_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [ $DELETED_COUNT -gt 0 ]; then
    echo -e "${YELLOW}  Deleted $DELETED_COUNT old backup(s)${NC}"
else
    echo "  No old backups to delete"
fi

echo ""

# Show disk usage
echo "💾 Disk Usage:"
echo "  Backups: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "  Available: $(df -h . | awk 'NR==2 {print $4}')"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Backup completed successfully${NC}"
echo "=================================================="
echo ""
echo "💡 To restore from this backup:"
echo "   1. Stop the bot: pm2 stop whatsapp-bot"
echo "   2. Extract: tar -xzf $BACKUP_DIR/$BACKUP_FILE"
echo "   3. Start the bot: pm2 start whatsapp-bot"
echo ""
echo "💡 To download backup to your local machine:"
echo "   scp -i oracle-edutrack-ssh.key ubuntu@YOUR_IP:$BACKUP_DIR/$BACKUP_FILE ."
echo ""
