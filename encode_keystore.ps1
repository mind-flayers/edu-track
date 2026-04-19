# PowerShell script to encode keystore to base64 for GitHub Actions
# Run this from the project root directory

Write-Host "`nKeystore to Base64 Encoder for GitHub Actions`n" -ForegroundColor Cyan

$keystorePath = "android\app\upload-keystore.jks"
$outputFile = "keystore_base64.txt"

# Check if keystore exists
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERROR: Keystore not found at: $keystorePath" -ForegroundColor Red
    Write-Host "Make sure you are in the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found keystore at: $keystorePath" -ForegroundColor Green
Write-Host "Encoding to base64..." -ForegroundColor Yellow

# Read and encode
try {
    $keystore = [System.IO.File]::ReadAllBytes($keystorePath)
    $base64 = [System.Convert]::ToBase64String($keystore)
    $base64 | Set-Content $outputFile
    
    Write-Host "`nSuccess! Base64 encoded keystore saved to: $outputFile`n" -ForegroundColor Green
    
    # Show file size
    $fileSize = (Get-Item $outputFile).Length
    Write-Host "Encoded file size: $fileSize bytes`n" -ForegroundColor Cyan
    
    # Instructions
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/mishafhasan/edu-track/settings/secrets/actions" -ForegroundColor White
    Write-Host "2. Click New repository secret" -ForegroundColor White
    Write-Host "3. Name: KEYSTORE_BASE64" -ForegroundColor Yellow
    Write-Host "4. Value: Copy entire content from $outputFile" -ForegroundColor Yellow
    Write-Host "5. Add these additional secrets:" -ForegroundColor White
    Write-Host "   - KEYSTORE_PASSWORD (currently: password)" -ForegroundColor Yellow
    Write-Host "   - KEY_ALIAS (currently: upload)" -ForegroundColor Yellow
    Write-Host "   - KEY_PASSWORD (currently: password)" -ForegroundColor Yellow
    
    Write-Host "`nIMPORTANT: Delete $outputFile after copying to GitHub!" -ForegroundColor Red
    Write-Host "Run: Remove-Item $outputFile -Force`n" -ForegroundColor Yellow
    
}
catch {
    Write-Host "ERROR: Failed to encode keystore" -ForegroundColor Red
    Write-Host "$_" -ForegroundColor Red
    exit 1
}
