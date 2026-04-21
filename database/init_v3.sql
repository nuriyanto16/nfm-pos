-- ============================================================
-- POS Resto v3 — Migration (Run AFTER init.sql / init_v2.sql)
-- ============================================================

-- 1. Update roles table: add description
ALTER TABLE roles ADD COLUMN IF NOT EXISTS description TEXT;

-- 2. Update users table: add full_name, is_active
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 3. Update customers table: add email, loyalty_points, total_spent, tier
ALTER TABLE customers ADD COLUMN IF NOT EXISTS email VARCHAR(100);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS loyalty_points INT DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tier VARCHAR(20) DEFAULT 'Bronze';

-- 4. Update menus table: add is_available
ALTER TABLE menus ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- 5. Update tables table: add capacity
ALTER TABLE tables ADD COLUMN IF NOT EXISTS capacity INT DEFAULT 4;

-- 6. Update orders table: add promo_id
ALTER TABLE orders ADD COLUMN IF NOT EXISTS promo_id INT REFERENCES promos(id) ON DELETE SET NULL;

-- 7. Update order_items table: add notes
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS notes TEXT;

-- 8. Update payments table: add change, reference_no
ALTER TABLE payments ADD COLUMN IF NOT EXISTS change DECIMAL(12,2) DEFAULT 0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reference_no VARCHAR(100);
-- Expand payment_method constraint
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_payment_method_check;
ALTER TABLE payments ADD CONSTRAINT payments_payment_method_check 
    CHECK (payment_method IN ('Tunai', 'QRIS', 'E-Wallet', 'Transfer Bank', 'Kartu Debit/Kredit'));

-- ============================================================
-- New Tables
-- ============================================================

-- 9. Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Ingredients (Bahan Baku)
CREATE TABLE IF NOT EXISTS ingredients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    stock DECIMAL(12,3) DEFAULT 0,
    cost_per_unit DECIMAL(12,2) DEFAULT 0,
    min_stock DECIMAL(12,3) DEFAULT 0,
    supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Menu Ingredients (Recipe / Komposisi)
CREATE TABLE IF NOT EXISTS menu_ingredients (
    id SERIAL PRIMARY KEY,
    menu_id INT NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    ingredient_id INT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty_used DECIMAL(12,3) NOT NULL,
    unit VARCHAR(20),
    UNIQUE(menu_id, ingredient_id)
);

-- 12. Promos
CREATE TABLE IF NOT EXISTS promos (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'flat')),
    value DECIMAL(12,2) NOT NULL,
    min_order DECIMAL(12,2) DEFAULT 0,
    max_discount DECIMAL(12,2) DEFAULT 0,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Cashier Sessions
CREATE TABLE IF NOT EXISTS cashier_sessions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    open_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    close_time TIMESTAMP,
    initial_cash DECIMAL(12,2) DEFAULT 0,
    closing_cash DECIMAL(12,2) DEFAULT 0,
    total_sales DECIMAL(12,2) DEFAULT 0,
    total_orders INT DEFAULT 0,
    notes TEXT,
    status VARCHAR(10) DEFAULT 'Open' CHECK (status IN ('Open', 'Closed'))
);

-- ============================================================
-- Seed Data for New Tables
-- ============================================================

-- Default Promo (contoh)
INSERT INTO promos (name, description, type, value, min_order, start_date, end_date, is_active)
VALUES 
('Happy Hour 10%', 'Diskon 10% untuk semua menu jam 14-17', 'percentage', 10, 50000, NOW(), NOW() + INTERVAL '1 year', true),
('Gratis Minuman', 'Diskon Rp 15.000 untuk pembelian min Rp 100.000', 'flat', 15000, 100000, NOW(), NOW() + INTERVAL '1 year', false)
ON CONFLICT DO NOTHING;

-- Default Supplier
INSERT INTO suppliers (name, contact_person, phone, email)
VALUES ('Supplier Utama', 'Budi Santoso', '081234567890', 'budi@supplier.com')
ON CONFLICT DO NOTHING;
