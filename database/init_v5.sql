-- ============================================================
-- POS Resto v5 — Multi-Company, Sidebar, Finance & Inventory
-- ============================================================

-- 0. Create companies table (Multi-tenancy root)
CREATE TABLE IF NOT EXISTS companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    logo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed default company
INSERT INTO companies (name, code, address, phone, email)
VALUES ('NFM Group', 'NFM001', 'Main Office', '0812345678', 'info@nfm.com')
ON CONFLICT (code) DO NOTHING;

-- Update existing tables with company_id
ALTER TABLE branches ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE menus ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;

UPDATE branches SET company_id = 1 WHERE company_id IS NULL;
UPDATE users SET company_id = 1 WHERE company_id IS NULL;
UPDATE categories SET company_id = 1 WHERE company_id IS NULL;
UPDATE menus SET company_id = 1 WHERE company_id IS NULL;
UPDATE ingredients SET company_id = 1 WHERE company_id IS NULL;
UPDATE orders SET company_id = 1 WHERE company_id IS NULL;


-- 1. Create Sidebar & Privilege Tables
CREATE TABLE IF NOT EXISTS sidebar_menus (
    id SERIAL PRIMARY KEY,
    parent_id INT REFERENCES sidebar_menus(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    path VARCHAR(100),
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    is_header BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS role_menus (
    role_id INT REFERENCES roles(id) ON DELETE CASCADE,
    sidebar_menu_id INT REFERENCES sidebar_menus(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, sidebar_menu_id)
);

-- 1b. Create Inventory Tables
CREATE TABLE IF NOT EXISTS goods_receipts (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
    receipt_no VARCHAR(50) UNIQUE NOT NULL,
    vendor_invoice_no VARCHAR(50),
    receipt_date TIMESTAMP NOT NULL,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    notes TEXT,
    received_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id SERIAL PRIMARY KEY,
    receipt_id INT REFERENCES goods_receipts(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2) NOT NULL,
    subtotal DECIMAL(15, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS goods_issues (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    issue_no VARCHAR(50) UNIQUE NOT NULL,
    issue_category VARCHAR(50),
    issue_date TIMESTAMP NOT NULL,
    notes TEXT,
    issued_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS goods_issue_items (
    id SERIAL PRIMARY KEY,
    issue_id INT REFERENCES goods_issues(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    notes TEXT
);

-- 2. Create Finance Tables
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Note: In GORM, the unique index for accounts is composite
CREATE UNIQUE INDEX IF NOT EXISTS idx_branch_code ON accounts (COALESCE(branch_id, 0), code);

CREATE TABLE IF NOT EXISTS journal_entries (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    reference VARCHAR(100), -- Order ID, etc.
    total_amount DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS journal_items (
    id SERIAL PRIMARY KEY,
    journal_id INT REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id INT REFERENCES accounts(id) ON DELETE CASCADE,
    debit DECIMAL(15,2) DEFAULT 0,
    credit DECIMAL(15,2) DEFAULT 0
);

-- 3. Create Stock & Log Tables
CREATE TABLE IF NOT EXISTS stock_histories (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL, -- IN, OUT, ADJUST, WASTE, VOID
    quantity DECIMAL(15,3) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wa_logs (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE SET NULL,
    customer_id INT REFERENCES customers(id) ON DELETE SET NULL,
    phone VARCHAR(20),
    message TEXT,
    status VARCHAR(20), -- Success, Failed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create System Settings Table
CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    key VARCHAR(50) NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_branch_key ON system_settings (COALESCE(branch_id, 0), key);

-- 5. Add New Columns to Existing Tables
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_fee DECIMAL(12,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_charge_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS void_reason TEXT;

ALTER TABLE customers ADD COLUMN IF NOT EXISTS is_send_wa BOOLEAN DEFAULT FALSE;

-- 6. Seed Data for Sidebar Menus
-- Delete existing to avoid duplicates when re-seeding
DELETE FROM role_menus;
DELETE FROM sidebar_menus;

-- Insert Menus
INSERT INTO sidebar_menus (title, path, icon, sort_order, is_header) VALUES 
('Dashboard', '/dashboard', 'dashboard', 1, FALSE),
('Dashboard Executive', '/dashboard/executive', 'insights', 2, FALSE),
('OPERASIONAL', NULL, NULL, 5, TRUE),
('Point of Sale', '/pos', 'shopping_cart', 6, FALSE),
('Kitchen Display', '/kitchen', 'kitchen', 7, FALSE),
('Daftar Pesanan', '/orders', 'receipt_long', 8, FALSE),
('Barang Masuk', '/inventory/receipts', 'input', 60, FALSE),
('Barang Keluar', '/inventory/issues', 'output', 61, FALSE),
('KEUANGAN', NULL, NULL, 10, TRUE),
('Jurnal Umum', '/finance/journal', 'book', 11, FALSE),
('Buku Besar', '/finance/ledger', 'account_balance', 12, FALSE),
('Chart of Accounts', '/finance/coa', 'list_alt', 13, FALSE),
('MASTER DATA', NULL, NULL, 20, TRUE),
('Manajemen Menu', '/menus', 'restaurant_menu', 21, FALSE),
('Kategori', '/menus', 'category', 22, FALSE),
('Meja', '/manage-tables', 'table_restaurant', 23, FALSE),
('Pelanggan', '/customers', 'person', 24, FALSE),
('Stok & Bahan', '/ingredients', 'inventory_2', 25, FALSE),
('SISTEM', NULL, NULL, 40, TRUE),
('Pengaturan', '/settings', 'settings', 41, FALSE),
('User Management', '/users', 'people', 42, FALSE),
('Role Privilege', '/roles', 'security', 43, FALSE),
('Sidebar Management', '/management/sidebar', 'menu_open', 44, FALSE),
('Perusahaan', '/companies', 'corporate_fare', 110, FALSE);

-- 7. Grant All Menus to Admin Role
-- We try to find the 'Admin' role first. If it exists, map it.
DO $$
DECLARE
    admin_id INT;
BEGIN
    SELECT id INTO admin_id FROM roles WHERE name = 'Admin' LIMIT 1;
    IF admin_id IS NOT NULL THEN
        INSERT INTO role_menus (role_id, sidebar_menu_id)
        SELECT admin_id, id FROM sidebar_menus;
    END IF;
END $$;

-- 8. Seed Chart of Accounts (Default Global)
INSERT INTO accounts (code, name, type) VALUES 
('1101', 'Kas', 'Asset'),
('1201', 'Persediaan Bahan Baku', 'Asset'),
('2101', 'Hutang PPN', 'Liability'),
('3101', 'Modal Pemilik', 'Equity'),
('4101', 'Pendapatan Penjualan', 'Revenue'),
('4102', 'Pendapatan Service', 'Revenue'),
('5101', 'Harga Pokok Penjualan', 'Expense'),
('5201', 'Beban Operasional', 'Expense');

-- 9. Seed Default Settings for Branch 1
INSERT INTO system_settings (branch_id, key, value) VALUES 
(1, 'tax_pct', '11'),
(1, 'service_charge_pct', '5'),
(1, 'wa_gateway_url', 'http://localhost:3000'),
(1, 'wa_sender_number', '628123456789')
ON CONFLICT (branch_id, key) DO NOTHING;
