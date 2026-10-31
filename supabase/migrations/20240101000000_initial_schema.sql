-- Migration: Initial Schema for Warehouse Stock Management
-- Description: Creates profiles, warehouses, categories, products, suppliers, customers,
--              inventory, transactions, opnames, audit logs, RLS policies, and atomic stock RPCs.

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    nama TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('Admin', 'Staff Gudang', 'Manager')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. WAREHOUSES
CREATE TABLE IF NOT EXISTS public.warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kode TEXT NOT NULL UNIQUE,
    nama TEXT NOT NULL,
    alamat TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama TEXT NOT NULL UNIQUE,
    deskripsi TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. PRODUCTS
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT NOT NULL UNIQUE,
    nama TEXT NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    unit TEXT NOT NULL DEFAULT 'pcs',
    barcode TEXT NOT NULL UNIQUE,
    minimum_stock NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0),
    cost_price NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. SUPPLIERS
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama TEXT NOT NULL,
    kontak TEXT,
    alamat TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. CUSTOMERS (Penerima / Pelanggan)
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama TEXT NOT NULL,
    kontak TEXT,
    alamat TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. INVENTORY (Stok per produk & gudang)
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
    quantity NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_product_warehouse UNIQUE (product_id, warehouse_id)
);

-- 8. STOCK TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nomor_transaksi TEXT NOT NULL UNIQUE,
    tipe TEXT NOT NULL CHECK (tipe IN ('IN', 'OUT', 'ADJUSTMENT', 'TRANSFER')),
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
    to_warehouse_id UUID REFERENCES public.warehouses(id) ON DELETE RESTRICT,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    recipient TEXT,
    document_number TEXT,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'COMPLETED', 'CANCELLED')),
    catatan TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 9. STOCK TRANSACTION ITEMS
CREATE TABLE IF NOT EXISTS public.stock_transaction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES public.stock_transactions(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity NUMERIC(12, 2) NOT NULL CHECK (quantity > 0),
    unit_cost NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    notes TEXT
);

-- 10. STOCK OPNAMES
CREATE TABLE IF NOT EXISTS public.stock_opnames (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nomor_opname TEXT NOT NULL UNIQUE,
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'COMPLETED', 'CANCELLED')),
    catatan TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 11. STOCK OPNAME ITEMS
CREATE TABLE IF NOT EXISTS public.stock_opname_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opname_id UUID NOT NULL REFERENCES public.stock_opnames(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    system_quantity NUMERIC(12, 2) NOT NULL DEFAULT 0,
    physical_quantity NUMERIC(12, 2) NOT NULL CHECK (physical_quantity >= 0),
    difference NUMERIC(12, 2) NOT NULL DEFAULT 0,
    notes TEXT
);

-- 12. AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id TEXT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products(sku);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_inventory_product_warehouse ON public.inventory(product_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_transactions_warehouse ON public.stock_transactions(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tanggal ON public.stock_transactions(tanggal);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.stock_transactions(status);
CREATE INDEX IF NOT EXISTS idx_transaction_items_tx ON public.stock_transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_items_prod ON public.stock_transaction_items(product_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at);

-- =================================================================
-- HELPER FUNCTIONS FOR ROLE AND AUDIT
-- =================================================================
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
    RETURN COALESCE(v_role, 'Guest');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Automatically create profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_count INTEGER;
    initial_role TEXT;
BEGIN
    SELECT COUNT(*) INTO user_count FROM public.profiles;
    IF user_count = 0 THEN
        initial_role := 'Admin';
    ELSE
        initial_role := COALESCE(new.raw_user_meta_data->>'role', 'Staff Gudang');
    END IF;

    INSERT INTO public.profiles (id, email, nama, role, status)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'nama', split_part(new.email, '@', 1)),
        initial_role,
        'active'
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        nama = EXCLUDED.nama;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =================================================================
-- ATOMIC STOCK FUNCTIONS / RPCS
-- =================================================================

-- 1. POST STOCK TRANSACTION
CREATE OR REPLACE FUNCTION public.post_stock_transaction(p_transaction_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_tx RECORD;
    v_item RECORD;
    v_current_stock NUMERIC(12, 2);
    v_new_stock NUMERIC(12, 2);
BEGIN
    -- Lock transaction for update
    SELECT * INTO v_tx
    FROM public.stock_transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaksi dengan ID % tidak ditemukan', p_transaction_id;
    END IF;

    IF v_tx.status <> 'DRAFT' THEN
        RAISE EXCEPTION 'Transaksi % sudah berstatus % dan tidak dapat diposting lagi', v_tx.nomor_transaksi, v_tx.status;
    END IF;

    -- Process each item
    FOR v_item IN
        SELECT sti.*, p.nama as product_name
        FROM public.stock_transaction_items sti
        JOIN public.products p ON p.id = sti.product_id
        WHERE sti.transaction_id = p_transaction_id
    LOOP
        -- Ensure inventory row exists for warehouse
        INSERT INTO public.inventory (product_id, warehouse_id, quantity)
        VALUES (v_item.product_id, v_tx.warehouse_id, 0)
        ON CONFLICT (product_id, warehouse_id) DO NOTHING;

        -- Lock inventory row
        SELECT quantity INTO v_current_stock
        FROM public.inventory
        WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id
        FOR UPDATE;

        IF v_tx.tipe = 'IN' THEN
            v_new_stock := v_current_stock + v_item.quantity;
            UPDATE public.inventory
            SET quantity = v_new_stock, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'OUT' THEN
            IF v_current_stock < v_item.quantity THEN
                RAISE EXCEPTION 'Stok tidak mencukupi untuk % (SKU: %). Tersedia: %, diminta: %', 
                    v_item.product_name, v_item.product_id, v_current_stock, v_item.quantity;
            END IF;
            v_new_stock := v_current_stock - v_item.quantity;
            UPDATE public.inventory
            SET quantity = v_new_stock, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'ADJUSTMENT' THEN
            -- Notes or item quantity represents change or target
            -- If difference is stored in quantity:
            v_new_stock := v_current_stock + v_item.quantity;
            IF v_new_stock < 0 THEN
                RAISE EXCEPTION 'Penyesuaian menyebabkan stok % menjadi negatif', v_item.product_name;
            END IF;
            UPDATE public.inventory
            SET quantity = v_new_stock, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'TRANSFER' THEN
            IF v_tx.to_warehouse_id IS NULL THEN
                RAISE EXCEPTION 'Gudang tujuan harus diisi untuk transaksi TRANSFER';
            END IF;
            IF v_current_stock < v_item.quantity THEN
                RAISE EXCEPTION 'Stok tidak mencukupi untuk transfer %. Tersedia: %, diminta: %',
                    v_item.product_name, v_current_stock, v_item.quantity;
            END IF;
            -- Deduct from origin
            UPDATE public.inventory
            SET quantity = v_current_stock - v_item.quantity, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

            -- Add to destination
            INSERT INTO public.inventory (product_id, warehouse_id, quantity)
            VALUES (v_item.product_id, v_tx.to_warehouse_id, v_item.quantity)
            ON CONFLICT (product_id, warehouse_id) DO UPDATE
            SET quantity = public.inventory.quantity + EXCLUDED.quantity, updated_at = now();
        END IF;
    END LOOP;

    -- Update transaction status to COMPLETED
    UPDATE public.stock_transactions
    SET status = 'COMPLETED'
    WHERE id = p_transaction_id;

    -- Audit log
    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, details)
    VALUES (
        auth.uid(),
        'POST_TRANSACTION',
        'stock_transactions',
        p_transaction_id::text,
        jsonb_build_object(
            'nomor_transaksi', v_tx.nomor_transaksi,
            'tipe', v_tx.tipe,
            'warehouse_id', v_tx.warehouse_id
        )
    );

    RETURN jsonb_build_object('success', true, 'message', 'Transaksi berhasil diposting');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CANCEL STOCK TRANSACTION (Atomically reverses posted stock)
CREATE OR REPLACE FUNCTION public.cancel_stock_transaction(p_transaction_id UUID, p_reason TEXT DEFAULT 'Pembatalan transaksi')
RETURNS JSONB AS $$
DECLARE
    v_tx RECORD;
    v_item RECORD;
    v_current_stock NUMERIC(12, 2);
BEGIN
    SELECT * INTO v_tx
    FROM public.stock_transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaksi tidak ditemukan';
    END IF;

    IF v_tx.status <> 'COMPLETED' THEN
        RAISE EXCEPTION 'Hanya transaksi berstatus COMPLETED yang dapat dibatalkan';
    END IF;

    -- Reverse each item
    FOR v_item IN
        SELECT sti.*, p.nama as product_name
        FROM public.stock_transaction_items sti
        JOIN public.products p ON p.id = sti.product_id
        WHERE sti.transaction_id = p_transaction_id
    LOOP
        SELECT quantity INTO v_current_stock
        FROM public.inventory
        WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id
        FOR UPDATE;

        IF v_tx.tipe = 'IN' THEN
            -- Was added, now deduct
            IF v_current_stock < v_item.quantity THEN
                RAISE EXCEPTION 'Tidak dapat membatalkan: stok % saat ini (%) lebih kecil dari jumlah yang dibatalkan (%)',
                    v_item.product_name, v_current_stock, v_item.quantity;
            END IF;
            UPDATE public.inventory
            SET quantity = v_current_stock - v_item.quantity, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'OUT' THEN
            -- Was deducted, now add back
            UPDATE public.inventory
            SET quantity = v_current_stock + v_item.quantity, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'ADJUSTMENT' THEN
            -- Reverse difference
            UPDATE public.inventory
            SET quantity = v_current_stock - v_item.quantity, updated_at = now()
            WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;

        ELSIF v_tx.tipe = 'TRANSFER' THEN
            -- Check destination has enough to return
            DECLARE
                v_dest_stock NUMERIC(12, 2);
            BEGIN
                SELECT quantity INTO v_dest_stock
                FROM public.inventory
                WHERE product_id = v_item.product_id AND warehouse_id = v_tx.to_warehouse_id
                FOR UPDATE;

                IF v_dest_stock < v_item.quantity THEN
                    RAISE EXCEPTION 'Gudang tujuan tidak memiliki stok cukup untuk pengembalian transfer %', v_item.product_name;
                END IF;

                UPDATE public.inventory
                SET quantity = v_dest_stock - v_item.quantity, updated_at = now()
                WHERE product_id = v_item.product_id AND warehouse_id = v_tx.to_warehouse_id;

                UPDATE public.inventory
                SET quantity = v_current_stock + v_item.quantity, updated_at = now()
                WHERE product_id = v_item.product_id AND warehouse_id = v_tx.warehouse_id;
            END;
        END IF;
    LOOP END LOOP;

    UPDATE public.stock_transactions
    SET status = 'CANCELLED',
        catatan = COALESCE(catatan, '') || E'\n[DIBATALKAN: ' || p_reason || ']'
    WHERE id = p_transaction_id;

    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, details)
    VALUES (
        auth.uid(),
        'CANCEL_TRANSACTION',
        'stock_transactions',
        p_transaction_id::text,
        jsonb_build_object('nomor_transaksi', v_tx.nomor_transaksi, 'alasan', p_reason)
    );

    RETURN jsonb_build_object('success', true, 'message', 'Transaksi berhasil dibatalkan dan stok dikembalikan');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. POST STOCK OPNAME (Applies physical count differences as an atomic adjustment)
CREATE OR REPLACE FUNCTION public.post_stock_opname(p_opname_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_opname RECORD;
    v_item RECORD;
    v_adj_tx_id UUID;
    v_adj_tx_no TEXT;
    v_current_stock NUMERIC(12, 2);
BEGIN
    SELECT * INTO v_opname
    FROM public.stock_opnames
    WHERE id = p_opname_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Data Opname tidak ditemukan';
    END IF;

    IF v_opname.status <> 'DRAFT' THEN
        RAISE EXCEPTION 'Opname sudah berstatus %', v_opname.status;
    END IF;

    v_adj_tx_no := 'ADJ-OPN-' || to_char(now(), 'YYYYMMDD-HH24MISS');

    -- Create an adjustment transaction automatically
    INSERT INTO public.stock_transactions (
        nomor_transaksi, tipe, warehouse_id, tanggal, status, created_by, catatan
    ) VALUES (
        v_adj_tx_no, 'ADJUSTMENT', v_opname.warehouse_id, CURRENT_DATE, 'COMPLETED', auth.uid(),
        'Penyesuaian otomatis dari Opname: ' || v_opname.nomor_opname
    ) RETURNING id INTO v_adj_tx_id;

    FOR v_item IN
        SELECT * FROM public.stock_opname_items WHERE opname_id = p_opname_id
    LOOP
        -- Ensure inventory row exists
        INSERT INTO public.inventory (product_id, warehouse_id, quantity)
        VALUES (v_item.product_id, v_opname.warehouse_id, 0)
        ON CONFLICT (product_id, warehouse_id) DO NOTHING;

        SELECT quantity INTO v_current_stock
        FROM public.inventory
        WHERE product_id = v_item.product_id AND warehouse_id = v_opname.warehouse_id
        FOR UPDATE;

        -- Record item in adjustment transaction
        INSERT INTO public.stock_transaction_items (transaction_id, product_id, quantity, notes)
        VALUES (v_adj_tx_id, v_item.product_id, v_item.difference, 'Selisih Opname fisik: ' || v_item.physical_quantity || ', sistem: ' || v_item.system_quantity);

        -- Directly adjust inventory to physical_quantity
        UPDATE public.inventory
        SET quantity = v_item.physical_quantity, updated_at = now()
        WHERE product_id = v_item.product_id AND warehouse_id = v_opname.warehouse_id;
    END LOOP;

    UPDATE public.stock_opnames
    SET status = 'COMPLETED'
    WHERE id = p_opname_id;

    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, details)
    VALUES (
        auth.uid(),
        'POST_OPNAME',
        'stock_opnames',
        p_opname_id::text,
        jsonb_build_object(
            'nomor_opname', v_opname.nomor_opname,
            'adjustment_tx', v_adj_tx_no
        )
    );

    RETURN jsonb_build_object('success', true, 'message', 'Opname berhasil diposting dan stok disesuaikan');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_opnames ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_opname_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- PROFILES RLS
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles"
    ON public.profiles FOR ALL
    TO authenticated
    USING (public.current_user_role() = 'Admin');

-- WAREHOUSES RLS
CREATE POLICY "Warehouses viewable by authenticated"
    ON public.warehouses FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Warehouses manageable by Admin"
    ON public.warehouses FOR ALL
    TO authenticated
    USING (public.current_user_role() = 'Admin');

-- CATEGORIES RLS
CREATE POLICY "Categories viewable by authenticated"
    ON public.categories FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Categories manageable by Admin"
    ON public.categories FOR ALL
    TO authenticated
    USING (public.current_user_role() = 'Admin');

-- PRODUCTS RLS
CREATE POLICY "Products viewable by authenticated"
    ON public.products FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Products manageable by Admin and Staff"
    ON public.products FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

-- SUPPLIERS & CUSTOMERS RLS
CREATE POLICY "Suppliers viewable by authenticated"
    ON public.suppliers FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Suppliers manageable by Admin and Staff"
    ON public.suppliers FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

CREATE POLICY "Customers viewable by authenticated"
    ON public.customers FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Customers manageable by Admin and Staff"
    ON public.customers FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

-- INVENTORY RLS
CREATE POLICY "Inventory viewable by authenticated"
    ON public.inventory FOR SELECT
    TO authenticated
    USING (true);

-- Direct changes to inventory restricted to Admin (normal updates occur via secure RPC)
CREATE POLICY "Inventory update via admin or RPC"
    ON public.inventory FOR ALL
    TO authenticated
    USING (public.current_user_role() = 'Admin');

-- STOCK TRANSACTIONS RLS
CREATE POLICY "Transactions viewable by authenticated"
    ON public.stock_transactions FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Transactions insertable by Admin and Staff"
    ON public.stock_transactions FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('Admin', 'Staff Gudang'));

CREATE POLICY "Draft transactions updatable by creator or admin"
    ON public.stock_transactions FOR UPDATE
    TO authenticated
    USING (status = 'DRAFT' AND (created_by = auth.uid() OR public.current_user_role() = 'Admin'));

-- STOCK TRANSACTION ITEMS RLS
CREATE POLICY "Transaction items viewable by authenticated"
    ON public.stock_transaction_items FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Transaction items manageable by Admin and Staff"
    ON public.stock_transaction_items FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

-- STOCK OPNAMES & ITEMS RLS
CREATE POLICY "Opnames viewable by authenticated"
    ON public.stock_opnames FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Opnames manageable by Admin and Staff"
    ON public.stock_opnames FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

CREATE POLICY "Opname items viewable by authenticated"
    ON public.stock_opname_items FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Opname items manageable by Admin and Staff"
    ON public.stock_opname_items FOR ALL
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Staff Gudang'));

-- AUDIT LOGS RLS
CREATE POLICY "Audit logs viewable by Admin and Manager"
    ON public.audit_logs FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('Admin', 'Manager'));

CREATE POLICY "Audit logs insertable by system/authenticated"
    ON public.audit_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

