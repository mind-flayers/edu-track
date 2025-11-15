#!/bin/bash

###############################################################################
# WhatsApp Bot Health Monitor
# 
# This script checks the health of the WhatsApp bot and restarts if needed.
# Can be run manually or scheduled with cron.
#
# Usage:
#   chmod +x monitor-bot.sh
#   ./monitor-bot.sh
#
# Schedule with cron (check every 5 minutes):
#   crontab -e
#   */5 * * * * /home/ubuntu/edu-track/whatsapp-edutrack-bot/monitor-bot.sh >> /home/ubuntu/monitor.log 2>&1
###############################################################################

# Configuration
BOT_URL="http://localhost:3000/health"
LOG_FILE="$HOME/monitor.log"
MAX_RETRIES=3
RETRY_DELAY=5

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check bot health
check_bot_health() {
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "$BOT_URL" 2>&1)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        # Check if WhatsApp is ready
        whatsapp_ready=$(echo "$body" | grep -o '"whatsapp_ready":[^,}]*' | cut -d':' -f2 | tr -d ' ')
        
        if [ "$whatsapp_ready" = "true" ]; then
            return 0  # Success - bot is healthy
        else
            log "${YELLOW}⚠️  Bot online but WhatsApp not ready${NC}"
            return 1  # Bot online but WhatsApp not connected
        fi
    else
        log "${RED}❌ Bot health check failed - HTTP $http_code${NC}"
        return 2  # Bot not responding
    fi
}

# Function to check PM2 processes
check_pm2_status() {
    if ! command -v pm2 &> /dev/null; then
        log "${RED}❌ PM2 not found${NC}"
        return 1
    fi
    
    # Check if services are running
    whatsapp_status=$(pm2 jlist | grep -o '"name":"whatsapp-bot"[^}]*"status":"[^"]*"' | cut -d'"' -f8)
    bridge_status=$(pm2 jlist | grep -o '"name":"firebase-bridge"[^}]*"status":"[^"]*"' | cut -d'"' -f8)
    
    if [ "$whatsapp_status" != "online" ] || [ "$bridge_status" != "online" ]; then
        log "${RED}❌ PM2 services not online${NC}"
        log "   WhatsApp Bot: $whatsapp_status"
        log "   Firebase Bridge: $bridge_status"
        return 1
    fi
    
    return 0
}

# Function to restart bot
restart_bot() {
    log "${YELLOW}🔄 Restarting WhatsApp bot...${NC}"
    pm2 restart whatsapp-bot
    sleep 10  # Wait for bot to initialize
    
    log "${YELLOW}🔄 Restarting Firebase bridge...${NC}"
    pm2 restart firebase-bridge
    sleep 5
    
    pm2 save > /dev/null 2>&1
}

# Function to send alert (can be extended to send email/SMS)
send_alert() {
    local message="$1"
    log "${RED}🚨 ALERT: $message${NC}"
    
    # TODO: Add email/SMS notification here
    # Example: echo "$message" | mail -s "WhatsApp Bot Alert" admin@example.com
}

# Main monitoring logic
main() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "🔍 Starting bot health check..."
    
    # Check PM2 status first
    if ! check_pm2_status; then
        log "${RED}❌ PM2 services not running properly${NC}"
        restart_bot
        sleep 10
    fi
    
    # Try health check with retries
    retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if check_bot_health; then
            log "${GREEN}✅ Bot is healthy and WhatsApp is ready${NC}"
            
            # Check memory usage
            memory_usage=$(pm2 jlist | grep -o '"memory":[0-9]*' | head -1 | cut -d':' -f2)
            memory_mb=$((memory_usage / 1024 / 1024))
            log "📊 Memory usage: ${memory_mb}MB"
            
            # Warn if memory is high
            if [ $memory_mb -gt 400 ]; then
                log "${YELLOW}⚠️  High memory usage detected${NC}"
            fi
            
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log "${YELLOW}⏳ Retry $retry_count/$MAX_RETRIES in ${RETRY_DELAY}s...${NC}"
            sleep $RETRY_DELAY
        fi
    done
    
    # If we get here, all retries failed
    log "${RED}❌ Bot health check failed after $MAX_RETRIES attempts${NC}"
    send_alert "WhatsApp bot not responding after $MAX_RETRIES attempts"
    
    # Restart bot
    restart_bot
    
    # Wait and check again
    log "⏳ Waiting 30s for bot to recover..."
    sleep 30
    
    if check_bot_health; then
        log "${GREEN}✅ Bot recovered successfully after restart${NC}"
    else
        log "${RED}❌ Bot still not healthy after restart${NC}"
        send_alert "WhatsApp bot failed to recover after restart - manual intervention required"
    fi
}

# Run monitoring
main

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
