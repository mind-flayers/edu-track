# Deployment Files for EduTrack WhatsApp Bot

This folder contains deployment configurations for hosting the WhatsApp notification bot.

---

## 📁 Files Overview

### Dockerfile.koyeb
**Purpose**: Docker image for Koyeb hosting (recommended, no credit card)

**Features**:
- Node.js 18 runtime
- Chromium + dependencies for WhatsApp Web
- Optimized for 512 MB RAM (Koyeb free tier)
- Persistent volume support for WhatsApp session

**Usage**:
```powershell
# Build locally (testing)
docker build -f Dockerfile.koyeb -t edutrack-whatsapp .

# Run locally
docker run -p 3000:3000 -v $(pwd)/whatsapp-session:/app/whatsapp-session edutrack-whatsapp
```

**Koyeb Deployment**:
- Set "Dockerfile Path" to: `deployment/Dockerfile.koyeb`
- Koyeb automatically builds and deploys

---

### .dockerignore
**Purpose**: Excludes unnecessary files from Docker build

**What's excluded**:
- `node_modules` (reinstalled during build)
- `whatsapp-session/*` (uses volume instead)
- Git files, logs, docs

---

### keep-alive-ping.js
**Purpose**: Script to ping WhatsApp bot health endpoint

**Usage**:
```powershell
# Test locally
node keep-alive-ping.js http://localhost:3000

# Deploy to cron-job.org
# Use this URL: https://your-app.koyeb.app/health
```

**Not required for deployment** - just a testing/reference script.
Use cron-job.org web interface instead (simpler).

---

## 🚀 Deployment Guides

### Recommended: Koyeb (No Credit Card)
📖 **Guide**: `../docs/KOYEB_DEPLOYMENT_GUIDE.md`

**Why Koyeb?**
- ✅ No credit card required
- ✅ Persistent volumes (WhatsApp session survives restarts)
- ✅ 512 MB RAM (sufficient)
- ✅ $0/month forever

**Quick Start**:
1. Sign up: https://app.koyeb.com/auth/signup
2. Connect GitHub repo
3. Set Dockerfile path: `deployment/Dockerfile.koyeb`
4. Add volume: `/app/whatsapp-session`
5. Deploy!

---

### Alternative: Oracle Cloud (Credit Card Required)
📖 **Guide**: `../docs/ORACLE_CLOUD_DEPLOYMENT_GUIDE.md`

**Why Oracle?**
- ✅ 12 GB RAM (vs 512 MB)
- ✅ More powerful VM
- ⚠️ Requires credit card
- ⚠️ Complex setup (3+ hours)

---

### Comparison: All Platforms
📖 **Guide**: `../docs/HOSTING_COMPARISON.md`

Compare Koyeb, Render, Railway, Fly.io, Oracle, VPS, Raspberry Pi.

---

## 🔧 Local Development

### Prerequisites:
```powershell
# Install Node.js 18+
node --version  # Should show v18.x.x

# Install dependencies
cd whatsapp-edutrack-bot
npm install
```

### Run Locally:
```powershell
# Start WhatsApp bot server
cd whatsapp-edutrack-bot
node server.js

# In another terminal, test:
curl http://localhost:3000/health
curl http://localhost:3000/qr-code  # Get QR to scan
```

### Test with Flutter:
```dart
// In lib/app/services/whatsapp_direct_service.dart
static const String _whatsappServerUrl = 'http://localhost:3000';
```

---

## 🐳 Docker Local Testing

### Build Image:
```powershell
# From repo root
docker build -f deployment/Dockerfile.koyeb -t edutrack-whatsapp .
```

### Run Container:
```powershell
# Run with volume
docker run -d \
  --name whatsapp-bot \
  -p 3000:3000 \
  -v ${PWD}/whatsapp-session:/app/whatsapp-session \
  edutrack-whatsapp

# View logs
docker logs -f whatsapp-bot

# Get QR code
curl http://localhost:3000/qr-code
```

### Stop & Clean:
```powershell
docker stop whatsapp-bot
docker rm whatsapp-bot
```

---

## 📊 Deployment Checklist

Before deploying:

### Code Ready:
- [ ] `whatsapp-edutrack-bot/server.js` exists
- [ ] `whatsapp-edutrack-bot/package.json` has all dependencies
- [ ] Code pushed to GitHub

### Docker Configuration:
- [ ] `deployment/Dockerfile.koyeb` verified
- [ ] `.dockerignore` configured
- [ ] Chromium dependencies included

### Platform Setup:
- [ ] Koyeb account created
- [ ] GitHub repo connected
- [ ] Dockerfile path configured
- [ ] Persistent volume added (1 GB, `/app/whatsapp-session`)
- [ ] Environment variables set (PORT=3000)

### Keep-Alive:
- [ ] cron-job.org account created
- [ ] Cron job configured (every 5 min)
- [ ] Health endpoint URL set

### Flutter Integration:
- [ ] `whatsapp_direct_service.dart` server URL updated
- [ ] App rebuilt and tested

---

## 🆘 Troubleshooting

### Build Fails:
- Check Dockerfile path is correct
- Verify all files are pushed to GitHub
- Check build logs in Koyeb dashboard

### Container Crashes:
- Check logs: Koyeb Dashboard → App → Logs
- Verify environment variables
- Check memory usage (max 512 MB on free tier)

### WhatsApp Session Lost:
- Verify volume is attached
- Check mount path: `/app/whatsapp-session`
- Ensure volume has write permissions

### Full Troubleshooting:
📖 See: `../docs/KOYEB_TROUBLESHOOTING.md`

---

## 📚 Related Documentation

- **KOYEB_DEPLOYMENT_GUIDE.md** - Complete Koyeb deployment (45 min)
- **HOSTING_COMPARISON.md** - Compare all hosting platforms
- **KOYEB_TROUBLESHOOTING.md** - Fix common issues
- **WHATSAPP_HOSTING_SUMMARY.md** - Quick reference
- **ORACLE_CLOUD_DEPLOYMENT_GUIDE.md** - Alternative deployment

---

## 🔄 Updates & Maintenance

### Update Dependencies:
```powershell
cd whatsapp-edutrack-bot
npm update
git add package.json package-lock.json
git commit -m "Update dependencies"
git push
# Koyeb auto-deploys
```

### Update Dockerfile:
```powershell
# Edit deployment/Dockerfile.koyeb
git add deployment/Dockerfile.koyeb
git commit -m "Update Dockerfile"
git push
# Koyeb auto-rebuilds
```

### Monitor Deployment:
- Koyeb Dashboard: https://app.koyeb.com
- View logs, metrics, health status
- Set up email alerts for failures

---

## 🎯 Quick Commands Reference

```powershell
# Test health endpoint
curl https://your-app.koyeb.app/health

# Get QR code
curl https://your-app.koyeb.app/qr-code

# Send test message
curl -X POST https://your-app.koyeb.app/send-message \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+94771234567", "message": "Test"}'

# Check service info
curl https://your-app.koyeb.app/info

# View recent logs
curl https://your-app.koyeb.app/logs
```

---

**Ready to deploy?** Start with `../docs/KOYEB_DEPLOYMENT_GUIDE.md`! 🚀
