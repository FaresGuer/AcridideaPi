# Script PowerShell pour tester le backend
Write-Host "============================================" -ForegroundColor Green
Write-Host "   LocustFarm Backend - Démarrage" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

$backendPath = "C:\Users\Nihel\OneDrive - ESPRIT\Bureau\arcidia\locust-farming-app\backend"

Write-Host "📂 Dossier: $backendPath" -ForegroundColor Cyan
Write-Host ""

# Lancer le backend
Write-Host "🚀 Lancement du serveur..." -ForegroundColor Yellow
cd $backendPath
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; python simple_main.py" -WindowStyle Normal

Write-Host "⏳ Attente de 12 secondes pour le démarrage..." -ForegroundColor Yellow
Start-Sleep -Seconds 12

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   TESTS DU BACKEND" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Test 1: Root endpoint
Write-Host "TEST 1: Root endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/" -Method GET -TimeoutSec 5
    Write-Host "✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Message: $($response.message)" -ForegroundColor White
} catch {
    Write-Host "❌ FAILED: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Login endpoint
Write-Host "TEST 2: Login endpoint..." -ForegroundColor Cyan
$loginData = @{
    username = "test@locustfarm.com"
    password = "test123"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/token" -Method POST -Body $loginData -ContentType "application/x-www-form-urlencoded" -TimeoutSec 5
    Write-Host "✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor White
} catch {
    Write-Host "❌ FAILED: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "📧 Identifiants de test:" -ForegroundColor Yellow
Write-Host "   Email:    test@locustfarm.com" -ForegroundColor White
Write-Host "   Password: test123" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "✨ Backend est actif sur http://localhost:8000" -ForegroundColor Green
Write-Host "📚 Documentation: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Appuyez sur une touche pour terminer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

