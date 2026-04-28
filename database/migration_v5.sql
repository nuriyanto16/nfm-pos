-- ============================================================
-- POS Resto v5 — Multi-Company & Inventory Management
-- ============================================================

-- 1. Create companies table
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

-- 2. Seed default company
INSERT INTO companies (name, code, address, phone, email)
VALUES ('NFM Group', 'NFM001', 'Main Office', '0812345678', 'info@nfm.com')
ON CONFLICT (code) DO NOTHING;

-- 3. Add company_id to branches
ALTER TABLE branches ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE branches SET company_id = 1 WHERE company_id IS NULL;

-- 4. Add company_id to other relevant tables for easy multi-tenancy filtering
ALTER TABLE users ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE users SET company_id = 1 WHERE company_id IS NULL;

ALTER TABLE categories ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE categories SET company_id = 1 WHERE company_id IS NULL;

ALTER TABLE menus ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE menus SET company_id = 1 WHERE company_id IS NULL;

ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE ingredients SET company_id = 1 WHERE company_id IS NULL;

ALTER TABLE orders ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE SET NULL;
UPDATE orders SET company_id = 1 WHERE company_id IS NULL;

-- 5. Create Goods Receipt (Barang Masuk)
CREATE TABLE IF NOT EXISTS goods_receipts (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
    receipt_no VARCHAR(50) UNIQUE NOT NULL,
    vendor_invoice_no VARCHAR(50),
    receipt_date TIMESTAMP NOT NULL,
    branch_order_id INT REFERENCES branch_orders(id) ON DELETE SET NULL,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    notes TEXT,
    received_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Draft', -- Draft, Approved, Cancelled
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

-- 6. Create Goods Issue (Barang Keluar)
CREATE TABLE IF NOT EXISTS goods_issues (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    issue_no VARCHAR(50) UNIQUE NOT NULL,
    issue_category VARCHAR(50),
    issue_date TIMESTAMP NOT NULL,
    notes TEXT,
    issued_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Draft', -- Draft, Approved, Cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS goods_issue_items (
    id SERIAL PRIMARY KEY,
    issue_id INT REFERENCES goods_issues(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    notes TEXT
);

-- 6b. Create Branch Order (Request Antar Cabang)
CREATE TABLE IF NOT EXISTS branch_orders (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    order_date TIMESTAMP NOT NULL,
    notes TEXT,
    requested_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Pending', -- Pending, Approved, Adjusted, Fulfilled, Cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS branch_order_items (
    id SERIAL PRIMARY KEY,
    branch_order_id INT REFERENCES branch_orders(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    approved_qty DECIMAL(15, 2) DEFAULT 0,
    notes TEXT
);

-- Update Goods Receipt to link with Branch Order
ALTER TABLE goods_receipts ADD COLUMN IF NOT EXISTS branch_order_id INT REFERENCES branch_orders(id) ON DELETE SET NULL;

-- 7. Add Sidebar Menus
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Dashboard Executive', '/dashboard/executive', 'insights', 5) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Barang Masuk', '/inventory/receipts', 'input', 60) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Barang Keluar', '/inventory/issues', 'output', 61) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Pesanan Cabang', '/inventory/branch-orders', 'local_shipping', 62) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Monitoring Meja', '/monitoring-tables', 'monitor', 26) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Denah Meja', '/layout-tables', 'map', 27) ON CONFLICT DO NOTHING;
INSERT INTO sidebar_menus (title, path, icon, sort_order) VALUES ('Perusahaan', '/companies', 'corporate_fare', 110) ON CONFLICT DO NOTHING;
