# Test WhatsApp Bot Health
Write-Host "Testing WhatsApp Bot Health..." -ForegroundColor Green

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 10
    Write-Host "✅ Health Check Successful!" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Cyan
    Write-Host "WhatsApp Ready: $($response.whatsapp_ready)" -ForegroundColor Cyan
    Write-Host "Message: $($response.message)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Health Check Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}