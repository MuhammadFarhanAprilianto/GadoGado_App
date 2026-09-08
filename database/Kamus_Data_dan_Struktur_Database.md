# Kamus Data dan Struktur Database
### Aplikasi POS & Manajemen Warung Mpo Lemezz

---

## 1. Arsitektur Basis Data
Aplikasi **Warung Mpo Lemezz** menggunakan arsitektur *Hybrid Database & Cloud Storage*:
1. **Google Firebase Cloud Firestore**: Database NoSQL dokumen realtime utama untuk transaksi, katalog, autentikasi, dan inventaris.
2. **Supabase Cloud Storage & PostgreSQL**: Penyimpanan objek berkas media (foto profil, gambar menu beresolusi tinggi, bukti transfer/resi QRIS) dan referensi skema relasional SQL.

---

## 2. Struktur Koleksi Dokumen (NoSQL Firestore)

### A. Koleksi users
Menyimpan identitas akun pengguna (Owner, Admin Kasir, dan Pelanggan).

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| id | String | Dokumen ID unik pengguna |
| uid | String | UID autentikasi Firebase Auth |
| 
ama | String | Nama lengkap pengguna |
| email | String | Alamat email terdaftar |
| 
ole | String | Hak akses (owner, dmin, pelanggan) |
| vatar_url | String (URL) | Tautan foto profil di Supabase Storage |
| hp | String | Nomor telepon / WhatsApp aktif |

---

### B. Koleksi 
aw_ingredients (Bahan Baku)
Menyimpan master data persediaan bahan baku dan batas minimum stok.

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| id | String | Kode bahan baku (cth: ING_001) |
| 
ama | String | Nama bahan baku (Kacang Tanah, Tahu, Telur, dll) |
| kategori | String | Kelompok bahan (Bumbu, Sayuran, Lauk, dll) |
| jumlah | Number (Double) | Jumlah stok fisik saat ini |
| satuan | String | Satuan kuantitas (kg, ikat, potong, utir, uah) |
| min_stok | Number (Double) | Batas peringatan stok menipis (*low stock threshold*) |
| is_low_stock | Boolean | Status penanda apakah stok di bawah ambang batas |

---

### C. Koleksi ood_items (Menu Makanan & Minuman)
Menyimpan katalog menu kuliner, harga jual, dan takaran resep otomatis (*recipe mapping*).

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| id | String | Kode menu (cth: MENU_001) |
| 
ama | String | Nama item kuliner |
| kategori | String | Kategori produk (Makanan Utama, Minuman) |
| harga | Number (Double) | Harga satuan produk (Rupiah) |
| status | String | Status ketersediaan (Tersedia, Habis) |
| gambar_url | String (URL) | Link gambar menu dari Supabase Storage |
| deskripsi | String | Penjelasan komposisi dan keunikan menu |
| 
esep_bahan | Array of Object | Komposisi bahan baku yang terpotong otomatis saat pesanan dibuat |

---

### D. Koleksi 	oppings
Menyimpan pilihan tambahan/ekstra menu.

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| id | String | Kode topping (cth: TOP_001) |
| 
ama | String | Nama topping (Ekstra Telur, Ekstra Lontong, dll) |
| harga | Number (Double) | Biaya tambahan topping |
| id_bahan | String | Relasi ke 
aw_ingredients yang akan dipotong stoknya |

---

### E. Koleksi orders (Transaksi Pemesanan)
Menyimpan seluruh histori transaksi pemesanan online maupun kasir langsung.

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| id | String | Nomor pesanan unik (cth: ORD_20260826_0001) |
| id_user | String | Relasi ID akun pemesan |
| 
ama_pelanggan | String | Nama penerima / pemesan |
| hp_pelanggan | String | Nomor telepon kontak pelanggan |
| 	ipe_layanan | String | Layanan (dineIn, 	akeAway, delivery) |
| metode_pembayaran | String | Metode (cash, qris, 	ransfer) |
| status | String | Status alur (pending, processing, completed, cancelled) |
| subtotal | Number (Double) | Total murni harga pesanan |
| iaya_layanan | Number (Double) | Biaya admin / kemasan |
| iaya_pengiriman | Number (Double) | Ongkos kirim jika layanan delivery |
| 	otal | Number (Double) | Grand total tagihan pembayaran |
| lamat_pengiriman | String | Alamat tujuan pengantaran |
| latitude | Number (Double) | Koordinat titik peta GPS lintang |
| longitude | Number (Double) | Koordinat titik peta GPS bujur |
| catatan_khusus | String | Catatan preferensi rasa / bumbu |
| waktu_pesan | Timestamp | Waktu masuk pesanan |
| waktu_selesai | Timestamp | Waktu pesanan selesai diproses |
| 
ating | Number (Double) | Ulasan rating kepuasan (1 s/d 5) |
| catatan_rating | String | Ulasan tertulis pelanggan |
| ukti_pembayaran_url | String (URL) | Link bukti transfer / resi QRIS |
| items | Array of Object | Detail daftar menu yang dipesan |

---

### F. Koleksi shop_settings
Menyimpan konfigurasi operasional toko/warung.

| Nama Field | Tipe Data | Deskripsi / Keterangan |
|---|---|---|
| status | String | Status operasional warung (open, ishoma, closed) |
| 
ama_toko | String | Nama toko/warung |
| lamat | String | Alamat fisik warung |
| isManualOverride| Boolean | Apakah status dikontrol manual oleh pemilik |
| jam_operasional | Map / Object | Jam buka, tutup, dan jadwal istirahat |
| lastUpdated | Timestamp | Waktu status terakhir diperbarui |
