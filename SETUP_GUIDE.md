# Panduan Setup & Eksekusi Aplikasi - Warehouse Stock Management

Aplikasi manajemen stok gudang berbasis **Flutter (Dart)** dan **Supabase**. Dirancang responsif (Mobile, Tablet, Desktop/Web), modular, hemat dependensi, dan mengutamakan integritas data stok secara atomik.

---

## 1. Menjalankan Aplikasi

### A. Menjalankan di Web
Pastikan Flutter sudah terpasang di sistem:
```bash
flutter run -d chrome
```
Atau build web untuk produksi:
```bash
flutter build web
```

### B. Menjalankan di Android
Jika Android SDK / Android Studio sudah terpasang:
```bash
flutter run -d android
```

---

## 2. Konfigurasi Database Supabase

### A. Migration Database & RPC
1. Buka dashboard proyek Anda di [Supabase](https://supabase.com).
2. Masuk ke menu **SQL Editor**.
3. Jalankan script migrasi utama yang ada pada:
   ```text
   supabase/migrations/20240101000000_initial_schema.sql
   ```
   *Script ini secara otomatis membuat tabel bisnis, index, relasi foreign key, Row Level Security (RLS) policies, serta fungsi RPC PostgreSQL atomik (`post_stock_transaction`, `cancel_stock_transaction`, `post_stock_opname`).*
4. Untuk mengisi data awal (kategori contoh, 2 gudang, produk contoh, stok awal, supplier, dan pelanggan), jalankan file seed:
   ```text
   supabase/seed.sql
   ```

### B. Konfigurasi Environment (`.env`)
Salin file `.env.example` ke `.env`:
```bash
cp .env.example .env
```
Isi konfigurasi URL dan Anon Key proyek Supabase Anda:
```env
SUPABASE_URL=https://[YOUR-PROJECT-ID].supabase.co
SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
```
> **PENTING**: Jangan pernah menggunakan `service_role` key pada aplikasi Flutter. Aplikasi ini sepenuhnya memanfaatkan Supabase Auth dan Row Level Security (RLS).

---

## 3. Akun Pengguna & Hak Akses (Role)

Aplikasi memiliki 3 role dengan batasan akses:

| Role | Hak Akses |
|---|---|
| **Admin** | Akses penuh: Katalog produk, Transaksi Masuk/Keluar, Stok Opname, Laporan, Manajemen Role Pengguna, dan Master Data. |
| **Staff Gudang** | Melihat katalog produk, melakukan transaksi barang masuk, barang keluar, dan stok opname. |
| **Manager** | Melihat dashboard, ringkasan stok, riwayat mutasi, dan mencetak/ekspor laporan PDF & Excel. |

### Mode Demo / Offline
Jika Supabase belum dikonfigurasi di file `.env`, aplikasi tetap dapat langsung digunakan dan diuji dengan data awal dan simulator login cepat untuk masing-masing role:
- **Admin**: `admin@stokgudang.com`
- **Staff Gudang**: `staff@stokgudang.com`
- **Manager**: `manager@stokgudang.com`

---

## 4. Fitur Utama yang Telah Berfungsi

1. **Dashboard Responsif**:
   - Total produk aktif, total stok gabungan, barang masuk hari ini, dan barang keluar hari ini.
   - Peringatan dini produk yang menyentuh batas minimum stok.
   - Log 5 transaksi mutasi terbaru.
   - Pemilihan filter gudang aktif di bagian atas antarmuka.

2. **Master Produk**:
   - Pencarian real-time berdasarkan Nama, SKU, atau nomor Barcode.
   - Filter berdasarkan Kategori dan Status (Aktif / Arsip).
   - Penambahan produk baru dengan generator SKU dan Barcode otomatis (Code 128 / EAN).
   - Proteksi arsip (produk dengan riwayat transaksi tidak dapat dihapus sembarangan).

3. **Barcode & Label Cetak**:
   - Generator Barcode format **Code 128 (1D)** dan **QR Code (2D)**.
   - Scanner barcode kamera (`mobile_scanner`) dengan toggle senter dan pembalik kamera.
   - Input barcode / SKU manual untuk perangkat tanpa kamera atau Web.
   - Preview label satuan dan batch printing (pilihan jumlah salinan: 1, 4, 12, 24, dll.).
   - Ekspor label barcode ke file **PDF** atau cetak langsung ke printer label via package `printing`.

4. **Pencatatan Barang Masuk (Stock In)**:
   - Pemilihan gudang tujuan, tanggal transaksi, pemasok/supplier, nomor surat jalan/PO, dan catatan.
   - Pemilihan multi-produk dengan input kuantitas dan harga satuan.
   - Dialog ringkasan sebelum transaksi disimpan.
   - Pembaruan stok secara atomik melalui PostgreSQL function `post_stock_transaction`.

5. **Pencatatan Barang Keluar (Stock Out)**:
   - Validasi ketersediaan stok di gudang asal secara langsung pada UI sebelum ditambahkan.
   - Menolak transaksi jika kuantitas keluar melebihi stok yang tersedia.
   - Pengurangan stok secara atomik di database.

6. **Stok Gudang, Kartu Mutasi, & Stok Opname**:
   - Tabel stok terkini per gudang dengan indikator status (AMAN / MENIPIS).
   - **Kartu Stok (Stock Card)**: Riwayat mutasi lengkap per produk dengan perhitungan saldo stok berjalan (*running balance*).
   - **Stok Opname**: Perbandingan stok sistem dengan hasil hitungan fisik lapangan, perhitungan selisih, dan koreksi stok otomatis berstatus penyesuaian (ADJUSTMENT).
   - **Pembatalan Transaksi**: Fitur pembatalan transaksi berstatus COMPLETED dengan pengembalian kuantitas stok secara otomatis dan pencatatan audit log.

7. **Laporan & Ekspor**:
   - Filter berdasarkan gudang, jenis mutasi, dan rentang tanggal.
   - Ekspor laporan ke dokumen **PDF** dengan tata letak resmi landscape.
   - Ekspor laporan ke spreadsheet **Excel (.xlsx)**.

---

## 5. Pengujian & Kualitas Kode

- **Flutter Analyze**: `No issues found!` (0 error, 0 warning, 0 info).
- **Unit & Widget Test**: 100% lulus (7 dari 7 pengujian passed).
- **Web Build**: Berhasil dikompilasi dengan `flutter build web`.

