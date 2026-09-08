<#
.SYNOPSIS
    Automated Docker Build, Test, and Verification Script for Windows PowerShell.
.DESCRIPTION
    Menjalankan proses build Docker, pengujian unit di dalam container,
    serta memverifikasi endpoint aplikasi dan health check.
#>

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WARUNG MPO LEMEZ - DOCKER AUTOMATED VERIFICATION       " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check Docker & Docker Compose availability
Write-Host "`n[1/5] Memeriksa instalasi Docker..." -ForegroundColor Green
try {
    $dockerVersion = docker --version
    Write-Host "Docker terdeteksi: $dockerVersion" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Docker tidak terdeteksi di PATH sistem ini!" -ForegroundColor Red
    Write-Host "Pastikan Docker Desktop sudah terinstal dan sedang berjalan." -ForegroundColor Yellow
    exit 1
}

# 2. Build Web Application Docker Image
Write-Host "`n[2/5] Membangun image Docker produksi (Flutter Web & Nginx)..." -ForegroundColor Green
docker compose build app
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Gagal melakukan build image Docker!" -ForegroundColor Red
    exit 1
}
Write-Host "Build image berhasil!" -ForegroundColor Gray

# 3. Run Automated Tests Inside Docker Container
Write-Host "`n[3/5] Menjalankan Test Suite di dalam Container Docker..." -ForegroundColor Green
docker compose --profile test run --rm test
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Automated test di dalam Docker mengalami kegagalan!" -ForegroundColor Red
    exit 1
}
Write-Host "Seluruh test di dalam Docker BERHASIL (100% Passed)!" -ForegroundColor Green

# 4. Start Container and Verify Health
Write-Host "`n[4/5] Menjalankan container aplikasi..." -ForegroundColor Green
docker compose up -d app

Write-Host "Menunggu inisialisasi container (maks 15 detik)..." -ForegroundColor Gray
$healthy = $false
for ($i = 1; $i -le 15; $i++) {
    Start-Sleep -Seconds 1
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/healthz" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    } catch {
        # Retry until available
    }
    Write-Host -NoNewline "."
}
Write-Host ""

if (-not $healthy) {
    Write-Host "[WARNING] Health check timeout, mencoba verifikasi root URL..." -ForegroundColor Yellow
}

# 5. Verify Web Endpoint
Write-Host "`n[5/5] Memverifikasi respon HTTP pada http://localhost:8080..." -ForegroundColor Green
try {
    $webResponse = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing
    if ($webResponse.StatusCode -eq 200) {
        Write-Host "HTTP Status: 200 OK" -ForegroundColor Green
        Write-Host "`n==========================================================" -ForegroundColor Green
        Write-Host "  SUKSES! Aplikasi Warung Mpo Lemez berjalan di Docker!   " -ForegroundColor Yellow
        Write-Host "  Silakan buka di browser: http://localhost:8080         " -ForegroundColor Cyan
        Write-Host "==========================================================" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Gagal menghubungi http://localhost:8080. Periksa port atau log container: docker compose logs app" -ForegroundColor Red
}
