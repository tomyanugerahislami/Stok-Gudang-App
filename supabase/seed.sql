-- Seed Data for Warehouse Stock Management

-- Warehouses
INSERT INTO public.warehouses (id, kode, nama, alamat, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'GDG-01', 'Gudang Utama Jakarta', 'Jl. Industri Raya No. 10, Jakarta Barat', 'active'),
    ('22222222-2222-2222-2222-222222222222', 'GDG-02', 'Gudang Transit Bekasi', 'Kawasan Industri MM2100, Bekasi', 'active')
ON CONFLICT (kode) DO NOTHING;

-- Categories
INSERT INTO public.categories (id, nama, deskripsi)
VALUES
    ('33333333-3333-3333-3333-333333333331', 'Elektronik & Sparepart', 'Perangkat elektronik dan suku cadang'),
    ('33333333-3333-3333-3333-333333333332', 'Alat Tulis Kantor', 'Kebutuhan ATK dan dokumen kantor'),
    ('33333333-3333-3333-3333-333333333333', 'Bahan Baku & Material', 'Material produksi dan pengemasan')
ON CONFLICT (nama) DO NOTHING;

-- Suppliers
INSERT INTO public.suppliers (id, nama, kontak, alamat)
VALUES
    ('44444444-4444-4444-4444-444444444441', 'PT Maju Logistik Sentosa', '081234567890 / Budi', 'Jl. Gatot Subroto No. 45, Jakarta Selatan'),
    ('44444444-4444-4444-4444-444444444442', 'CV Sumber Makmur Abadi', '081398765432 / Hendra', 'Jl. Raya Bogor KM 28, Depok')
ON CONFLICT DO NOTHING;

-- Customers
INSERT INTO public.customers (id, nama, kontak, alamat)
VALUES
    ('55555555-5555-5555-5555-555555555551', 'Toko Berkah Sejahtera', '082111223344 / Ibu Siti', 'Pasar Tanah Abang Blok A Lt. 2'),
    ('55555555-5555-5555-5555-555555555552', 'PT Cipta Kreasi Digital', '085712349988 / Pak Doni', 'Gedung Wisma Antara Lt. 8, Jakarta')
ON CONFLICT DO NOTHING;

-- Products
INSERT INTO public.products (id, sku, nama, category_id, unit, barcode, minimum_stock, cost_price, status)
VALUES
    ('66666666-6666-6666-6666-666666666661', 'PRD-ELK-001', 'Scanner Barcode Wireless 2D', '33333333-3333-3333-3333-333333333331', 'unit', '899100100001', 5, 450000.00, 'active'),
    ('66666666-6666-6666-6666-666666666662', 'PRD-ELK-002', 'Thermal Label Printer 80mm', '33333333-3333-3333-3333-333333333331', 'unit', '899100100002', 3, 850000.00, 'active'),
    ('66666666-6666-6666-6666-666666666663', 'PRD-ATK-001', 'Kertas Thermal Roll 80x80', '33333333-3333-3333-3333-333333333332', 'roll', '899100100003', 20, 15000.00, 'active'),
    ('66666666-6666-6666-6666-666666666664', 'PRD-MAT-001', 'Kardus Packing Karton Double Wall', '33333333-3333-3333-3333-333333333333', 'pcs', '899100100004', 50, 8500.00, 'active'),
    ('66666666-6666-6666-6666-666666666665', 'PRD-MAT-002', 'Lakban Fragile 48mm x 100m', '33333333-3333-3333-3333-333333333333', 'roll', '899100100005', 15, 12000.00, 'active')
ON CONFLICT (sku) DO NOTHING;

-- Initial Inventory for Gudang Utama
INSERT INTO public.inventory (product_id, warehouse_id, quantity)
VALUES
    ('66666666-6666-6666-6666-666666666661', '11111111-1111-1111-1111-111111111111', 18),
    ('66666666-6666-6666-6666-666666666662', '11111111-1111-1111-1111-111111111111', 4),  -- Mendekati minimum stock (3)
    ('66666666-6666-6666-6666-666666666663', '11111111-1111-1111-1111-111111111111', 85),
    ('66666666-6666-6666-6666-666666666664', '11111111-1111-1111-1111-111111111111', 120),
    ('66666666-6666-6666-6666-666666666665', '11111111-1111-1111-1111-111111111111', 8)   -- Di bawah minimum stock (15)
ON CONFLICT (product_id, warehouse_id) DO NOTHING;

