-- =========================================================================
-- SKRIPSI TUGAS AKHIR
-- Judul: Aplikasi Point of Sales (POS) dan Manajemen Warung Mpo Lemezz
-- Penulis: Muhammad Farhan Aprilianto (NPM: 4522210058)
-- DBMS Target: PostgreSQL / Supabase / MySQL (Relational Schema Reference & DDL)
-- =========================================================================

-- 1. TABEL USERS / PENGGUNA
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    uid VARCHAR(128) UNIQUE NOT NULL,
    nama VARCHAR(150) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'admin', 'pelanggan')),
    avatar_url TEXT,
    hp VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. TABEL BAHAN BAKU (RAW INGREDIENTS) & INVENTARIS
CREATE TABLE IF NOT EXISTS bahan_baku (
    id VARCHAR(50) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    kategori VARCHAR(50) NOT NULL,
    jumlah DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    satuan VARCHAR(20) NOT NULL,
    min_stok DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_low_stock BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. TABEL TOPPING / TAMBAHAN
CREATE TABLE IF NOT EXISTS toppings (
    id VARCHAR(50) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    harga DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    id_bahan VARCHAR(50) REFERENCES bahan_baku(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. TABEL MENU MAKANAN & MINUMAN
CREATE TABLE IF NOT EXISTS menus (
    id VARCHAR(50) PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    kategori VARCHAR(50) NOT NULL,
    harga DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'Tersedia',
    gambar_url TEXT,
    deskripsi TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. TABEL RESEP MENU (RELASI MENU DENGAN BAHAN BAKU)
CREATE TABLE IF NOT EXISTS menu_recipes (
    id SERIAL PRIMARY KEY,
    id_menu VARCHAR(50) REFERENCES menus(id) ON DELETE CASCADE,
    id_bahan VARCHAR(50) REFERENCES bahan_baku(id) ON DELETE CASCADE,
    jumlah_per_porsi DECIMAL(10, 3) NOT NULL,
    satuan VARCHAR(20) NOT NULL
);

-- 6. TABEL PESANAN / TRANSAKSI ORDERS
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(50) PRIMARY KEY,
    id_user VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
    nama_pelanggan VARCHAR(150) NOT NULL,
    hp_pelanggan VARCHAR(20),
    tipe_layanan VARCHAR(20) NOT NULL CHECK (tipe_layanan IN ('dineIn', 'takeAway', 'delivery')),
    metode_pembayaran VARCHAR(20) NOT NULL CHECK (metode_pembayaran IN ('cash', 'qris', 'transfer')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    pajak DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    biaya_layanan DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    biaya_pengiriman DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    alamat_pengiriman TEXT,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    catatan_khusus TEXT,
    bukti_pembayaran_url TEXT,
    waktu_pesan TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    waktu_selesai TIMESTAMP WITH TIME ZONE,
    rating DECIMAL(3, 2),
    catatan_rating TEXT,
    waktu_rating TIMESTAMP WITH TIME ZONE
);

-- 7. TABEL ITEM PESANAN (ORDER ITEMS)
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    id_order VARCHAR(50) REFERENCES orders(id) ON DELETE CASCADE,
    id_menu VARCHAR(50) REFERENCES menus(id) ON DELETE SET NULL,
    nama_menu VARCHAR(150) NOT NULL,
    harga_satuan DECIMAL(12, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    catatan TEXT,
    subtotal_item DECIMAL(12, 2) NOT NULL
);

-- 8. TABEL ITEM TOPPING PESANAN
CREATE TABLE IF NOT EXISTS order_item_toppings (
    id SERIAL PRIMARY KEY,
    id_order_item INT REFERENCES order_items(id) ON DELETE CASCADE,
    id_topping VARCHAR(50) REFERENCES toppings(id) ON DELETE SET NULL,
    nama_topping VARCHAR(100) NOT NULL,
    harga DECIMAL(12, 2) NOT NULL
);

-- 9. TABEL PENGATURAN TOKO (SHOP SETTINGS)
CREATE TABLE IF NOT EXISTS shop_settings (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'default_setting',
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    nama_toko VARCHAR(100) NOT NULL,
    alamat TEXT,
    is_manual_override BOOLEAN DEFAULT FALSE,
    jam_buka TIME,
    jam_tutup TIME,
    istirahat_mulai TIME,
    istirahat_selesai TIME,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
