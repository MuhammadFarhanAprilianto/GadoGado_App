#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "   WARUNG MPO LEMEZ - DOCKER ANDROID APK BUILDER          "
echo "=========================================================="
echo "Membangun file APK Android di dalam Docker..."
echo "(Tidak memerlukan instalasi Java JDK atau Android SDK di PC Lab)"
echo ""

docker compose --profile apk run --rm build-apk

echo ""
echo "=========================================================="
echo "  SUKSES! File APK telah berhasil dibuat!"
echo "  Lokasi file: build/app/outputs/flutter-apk/app-release.apk"
echo "=========================================================="
echo "Silakan salin file APK tersebut dan pasang di smartphone Android Anda."
