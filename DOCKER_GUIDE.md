# 🐳 Panduan Deployment & Pengujian Docker: Warung Mpo Lemez App

Dokumen ini merupakan panduan lengkap untuk menjalankan dan menguji aplikasi **Warung Mpo Lemez** menggunakan Docker di lingkungan komputer **Laboratorium Kampus**, ruang sidang, maupun server deployment tanpa memerlukan instalasi manual Flutter SDK, Dart SDK, Android Studio, atau Java.

---

## 🎯 Mengapa Menggunakan Docker di Lab Kampus?
- **Zero Configuration Conflict**: Tidak perlu khawatir versi Flutter, Dart, Java, atau Android SDK di PC lab berbeda atau bentrok.
- **Portabilitas Penuh**: Berjalan konsisten di Windows, macOS, maupun Linux.
- **Dua Opsi Demonstrasi Lengkap**:
  1. **Demo di Layar PC Lab (Web Presentation)**: Cukup `docker compose up -d`, tampilan UI mobile dapat langsung didemokan di layar monitor lab via browser (`http://localhost:8080`) tanpa emulator Android yang berat.
  2. **Demo di Smartphone Android (Mobile APK)**: Cukup klik `build_apk_docker.bat`, Docker akan otomatis mengompilasi file installer `app-release.apk` tanpa perlu instal Java/Android SDK di PC lab.
- **Automated Testing Mandiri**: Pengujian kode (Unit & Widget Test) dapat dijalankan di dalam container terisolasi.

---

## 📋 1. Prasyarat Sistem Lab
Pastikan pada komputer laboratorium telah terpasang salah satu dari:
1. **Docker Desktop** (untuk Windows 10/11 & macOS) - pastikan statusnya *Running*.
2. **Docker Engine & Docker Compose** (untuk Ubuntu / Debian / CentOS Linux).

---

## 🚀 2. Cara Menjalankan Aplikasi (Mode Produksi)

### Langkah A: Clone / Buka Folder Proyek
Buka terminal (Command Prompt / PowerShell / Terminal) di direktori utama proyek:
```bash
cd GadoGado_App
```

### Langkah B: Jalankan dengan Docker Compose
Cukup ketik perintah berikut:
```bash
docker compose up -d
```
> **Penjelasan**: Perintah ini akan:
> 1. Mengunduh Flutter builder image secara otomatis.
> 2. Melakukan build bundle Flutter Web release.
> 3. Menjalankan Nginx web server super ringan di port `8080`.

### Langkah C: Buka di Browser
Buka Google Chrome, Microsoft Edge, atau browser apa pun lalu akses:
```text
http://localhost:8080
```
Aplikasi **Warung Mpo Lemez** siap digunakan untuk demonstrasi, simulasi transaksi pelanggan, validasi kasir, maupun dashboard eksekutif pemilik.

---

## 🧪 3. Menjalankan Automated Testing di Docker

Untuk mendemonstrasikan pengujian perangkat lunak (*Software Quality Assurance / Testing*) saat presentasi atau sidang:

### A. Menjalankan Test Suite di Container
```bash
docker compose --profile test run --rm test
```
Container akan menjalankan seluruh test (Model Unit Tests & Widget Smoke Tests).

### B. Menjalankan Verifikasi Otomatis Sekali Klik (Script)
Kami telah menyediakan skrip pengujian otomatis:

- **Pada Windows (PowerShell)**:
  ```powershell
  .\test_docker.ps1
  ```

- **Pada Linux / macOS (Bash)**:
  ```bash
  chmod +x test_docker.sh
  ./test_docker.sh
  ```

Skrip ini akan secara otomatis:
1. Memeriksa keberadaan Docker.
2. Membangun image container.
3. Menjalankan seluruh test suite di dalam container.
4. Menjalankan service web dan memverifikasi endpoint `http://localhost:8080/healthz`.

---

## 📱 4. Membangun File APK Android (Mobile) via Docker

Jika Anda ingin mendemokan aplikasi langsung di **HP Android fisik** tanpa perlu menginstal Java JDK atau Android SDK di PC Lab:

### A. Cara 1: Sekali Klik (Script Bawaan)
- **Windows**: Cukup klik 2x berkas `build_apk_docker.bat`
- **Linux / macOS**: Jalankan `./build_apk_docker.sh`

### B. Cara 2: Perintah Docker Compose
```bash
docker compose --profile apk run --rm build-apk
```

> **Hasil Output**:
> File APK installer akan otomatis tersedia di folder:
> `build/app/outputs/flutter-apk/app-release.apk`
> 
> Anda dapat langsung menyalin file tersebut ke Flashdisk/Google Drive dan memasangnya di smartphone Android.

---

## 🛠️ 5. Perintah Tambahan yang Berguna

| Aksi | Perintah |
| :--- | :--- |
| **Jalankan Web App di Browser Lab** | `docker compose up -d` |
| **Build File APK Android** | `docker compose --profile apk run --rm build-apk` (atau double click `build_apk_docker.bat`) |
| **Jalankan Automated Testing** | `docker compose --profile test run --rm test` |
| **Melihat status container** | `docker compose ps` |
| **Melihat log web server** | `docker compose logs -f app` |
| **Menghentikan container** | `docker compose down` |
| **Build ulang image web** | `docker compose up -d --build` |
| **Menjalankan dev server di container** | `docker compose --profile dev up` |

---

## ❓ 6. Troubleshooting & Solusi Kendala Lab

### 1. Port 8080 sudah terpakai oleh aplikasi lain di PC Lab
Ubah port di file `docker-compose.yml` pada bagian `ports`:
```yaml
ports:
  - "3000:80"   # Ganti 8080 menjadi 3000 atau port lain
```
Lalu akses `http://localhost:3000`.

### 2. Docker Desktop belum berjalan
Buka aplikasi **Docker Desktop** dari menu Start / Applications dan tunggu hingga indikator di pojok kiri bawah berwarna hijau (*Engine running*).

### 3. Jaringan Lab Menggunakan Proxy
Jika jaringan kampus memerlukan proxy untuk mengunduh package saat build pertama kali, Docker akan otomatis menggunakan proxy host yang terkonfigurasi di Docker Desktop (*Settings > Proxies*).

---

<p align="center">
  <b>Warung Mpo Lemez App &copy; 2026. Siap Demo di Laboratorium Kampus! 🚀</b>
</p>
