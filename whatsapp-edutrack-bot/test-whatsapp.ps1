# Quick Test Script for WhatsApp Integration
# Run this in PowerShell to quickly test the WhatsApp bot integration

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "WhatsApp Integration Quick Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Step 1: Check if service account key exists
Write-Host "`n[1/6] Checking Firebase service account key..." -ForegroundColor Yellow
$keyPath = ".\service-account-key.json"
if (Test-Path $keyPath) {
    Write-Host "✅ Service account key found" -ForegroundColor Green
} else {
    Write-Host "❌ Service account key NOT found" -ForegroundColor Red
    Write-Host "Please download from Firebase Console and save as service-account-key.json" -ForegroundColor Red
    exit 1
}

# Step 2: Check if node_modules exists
Write-Host "`n[2/6] Checking npm dependencies..." -ForegroundColor Yellow
if (Test-Path ".\node_modules") {
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Dependencies not found. Installing..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Kill any existing node processes
Write-Host "`n[3/6] Cleaning up existing processes..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Found $($nodeProcesses.Count) node process(es). Stopping..." -ForegroundColor Yellow
    Stop-Process -Name node -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "✅ Cleaned up processes" -ForegroundColor Green
} else {
    Write-Host "✅ No existing processes found" -ForegroundColor Green
}

# Step 4: Start WhatsApp Bot (in background job)
Write-Host "`n[4/6] Starting WhatsApp Bot Server..." -ForegroundColor Yellow
Write-Host "This will run in the background. Monitor output in separate terminal." -ForegroundColor Cyan

# Create a new PowerShell window for the bot
$botScript = @"
cd '$PWD'
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host 'WhatsApp Bot Server' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
npm start
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $botScript

Write-Host "✅ Bot server starting in new window..." -ForegroundColor Green
Write-Host "⏳ Waiting 15 seconds for bot to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Step 5: Check bot health
Write-Host "`n[5/6] Checking bot health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 10 -UseBasicParsing
    $health = $response.Content | ConvertFrom-Json
    
    Write-Host "`nBot Status:" -ForegroundColor Cyan
    Write-Host "  Status: $($health.status)" -ForegroundColor $(if ($health.status -eq "online") { "Green" } else { "Red" })
    Write-Host "  WhatsApp Ready: $($health.whatsapp_ready)" -ForegroundColor $(if ($health.whatsapp_ready) { "Green" } else { "Yellow" })
    Write-Host "  Message: $($health.message)" -ForegroundColor Cyan
    
    if ($health.whatsapp_ready) {
        Write-Host "`n✅ Bot is ready to send messages!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Bot is online but WhatsApp not ready yet" -ForegroundColor Yellow
        Write-Host "This can take 30-60 seconds. Check the bot window for status." -ForegroundColor Yellow
        Write-Host "Wait for '✅ WhatsApp Client is ready!' message" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Bot health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the bot window shows 'Server running on http://0.0.0.0:3000'" -ForegroundColor Yellow
    exit 1
}

# Step 6: Offer to start Firebase Bridge
Write-Host "`n[6/6] Firebase Bridge Setup" -ForegroundColor Yellow
Write-Host "Do you want to start the Firebase Bridge now?" -ForegroundColor Cyan
Write-Host "This monitors Firestore and sends queued messages to the bot." -ForegroundColor Cyan
$response = Read-Host "Start bridge? (Y/N)"

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "`nStarting Firebase Bridge in new window..." -ForegroundColor Green
    
    $bridgeScript = @"
cd '$PWD'
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host 'Firebase WhatsApp Bridge' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
npm run bridge
"@
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $bridgeScript
    Write-Host "✅ Bridge starting in new window" -ForegroundColor Green
} else {
    Write-Host "`nTo start bridge manually later, run:" -ForegroundColor Yellow
    Write-Host "  npm run bridge" -ForegroundColor Cyan
}

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait for bot window to show: ✅ WhatsApp Client is ready!" -ForegroundColor White
Write-Host "  2. Open Flutter app and mark attendance for a student" -ForegroundColor White
Write-Host "  3. Watch the bridge window for message processing" -ForegroundColor White
Write-Host "  4. Check parent's WhatsApp for the notification" -ForegroundColor White

Write-Host "`nMonitoring:" -ForegroundColor Yellow
Write-Host "  Bot Health: http://localhost:3000/health" -ForegroundColor Cyan
Write-Host "  Firestore: https://console.firebase.google.com/project/edutrack-73a2e/firestore" -ForegroundColor Cyan

Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
Write-Host "  - If bot not ready, wait up to 60 seconds" -ForegroundColor White
Write-Host "  - Check bot window for any error messages" -ForegroundColor White
Write-Host "  - If issues persist, see TESTING_GUIDE.md" -ForegroundColor White

Write-Host "`n🎉 Happy Testing!" -ForegroundColor Green
