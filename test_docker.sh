#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "   WARUNG MPO LEMEZ - DOCKER AUTOMATED VERIFICATION       "
echo "=========================================================="

# 1. Check Docker & Docker Compose availability
echo ""
echo "[1/5] Memeriksa instalasi Docker..."
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker tidak ditemukan di PATH sistem ini!"
    echo "Pastikan Docker engine / Docker Desktop sudah terinstal dan berjalan."
    exit 1
fi
echo "Docker terdeteksi: $(docker --version)"

# 2. Build Web Application Docker Image
echo ""
echo "[2/5] Membangun image Docker produksi (Flutter Web & Nginx)..."
docker compose build app
echo "Build image berhasil!"

# 3. Run Automated Tests Inside Docker Container
echo ""
echo "[3/5] Menjalankan Test Suite di dalam Container Docker..."
docker compose --profile test run --rm test
echo "Seluruh test di dalam Docker BERHASIL (100% Passed)!"

# 4. Start Container and Verify Health
echo ""
echo "[4/5] Menjalankan container aplikasi..."
docker compose up -d app

echo "Menunggu inisialisasi container (maks 15 detik)..."
HEALTHY=false
for i in {1..15}; do
    sleep 1
    if curl -s -f http://localhost:8080/healthz > /dev/null 2>&1; then
        HEALTHY=true
        break
    fi
    printf "."
done
echo ""

# 5. Verify Web Endpoint
echo ""
echo "[5/5] Memverifikasi respon HTTP pada http://localhost:8080..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || true)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "HTTP Status: 200 OK"
    echo ""
    echo "=========================================================="
    echo "  SUKSES! Aplikasi Warung Mpo Lemez berjalan di Docker!   "
    echo "  Silakan buka di browser: http://localhost:8080         "
    echo "=========================================================="
else
    echo "[WARNING] HTTP status code: $HTTP_STATUS"
    echo "Cek logs container dengan perintah: docker compose logs app"
fi
