# Folder Database - Aplikasi POS Warung Mpo Lemezz

Folder ini merupakan dokumentasi terpusat dan repositori aset skema basis data untuk aplikasi **Point of Sales & Manajemen Warung Mpo Lemezz**.

---

## Struktur Direktori Database

`
database/
├── collections_json/                      # Dataset awal / Dummy Data NoSQL Firestore
│   ├── users.json                         # Master data akun pengguna (Owner, Admin, Pelanggan)
│   ├── bahan_baku.json                    # Master inventaris bahan baku & batas minimum stok
│   ├── menus_makanan.json                 # Katalog menu kuliner & relasi resep takaran
│   ├── toppings.json                      # Master pilihan topping tambahan
│   ├── pesanan_orders.json                # Transaksi pesanan (Dine-in, Take Away, Delivery)
│   └── shop_settings.json                 # Pengaturan jadwal & status warung
├── sql_schema/                            # Skrip Relasional SQL (PostgreSQL / Supabase / MySQL)
│   └── schema_database_pos_gadogado.sql   # DDL Tabel Relasional lengkap & Foreign Keys
├── security_rules/                        # Aturan Keamanan & Hak Akses
│   ├── firestore.rules                    # Aturan keamanan Cloud Firestore (Role-based security)
│   └── supabase_storage_rls.sql           # Setup bucket storage & RLS policies Supabase
├── Kamus_Data_dan_Struktur_Database.md     # Deskripsi lengkap field, tipe data, dan relasi tabel
└── README.md                              # Dokumentasi teknis folder database
`

---

## Panduan Penggunaan:
1. **Untuk Firebase Firestore:**
   - Unggah aturan hak akses dari file security_rules/firestore.rules ke Firebase Console.
   - Gunakan data JSON di collections_json/ sebagai acuan struktur dokumen koleksi.
2. **Untuk Supabase Cloud Storage:**
   - Jalankan skrip security_rules/supabase_storage_rls.sql di SQL Editor Supabase untuk membuat bucket vatars, menu-images, dan 
eceipts.
3. **Untuk Relational Database (SQL):**
   - Import file sql_schema/schema_database_pos_gadogado.sql ke PostgreSQL / MySQL / Supabase SQL Editor.
