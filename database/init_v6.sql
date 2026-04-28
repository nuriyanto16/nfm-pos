-- ============================================================
-- POS Resto v6 — Optimized Schema with Full Indexing
-- ============================================================

-- 1. Core Tables
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
CREATE INDEX IF NOT EXISTS idx_companies_code ON companies(code);

CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_branches_company_id ON branches(company_id);
CREATE INDEX IF NOT EXISTS idx_branches_code ON branches(code);

CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    role_id INT REFERENCES roles(id),
    full_name VARCHAR(100),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_branch_id ON users(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- 2. Master Data
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT
);
CREATE INDEX IF NOT EXISTS idx_categories_company_id ON categories(company_id);
CREATE INDEX IF NOT EXISTS idx_categories_branch_id ON categories(branch_id);

CREATE TABLE IF NOT EXISTS menus (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    category_id INT REFERENCES categories(id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(15, 2) NOT NULL,
    stock INT DEFAULT 0,
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_menus_company_id ON menus(company_id);
CREATE INDEX IF NOT EXISTS idx_menus_branch_id ON menus(branch_id);
CREATE INDEX IF NOT EXISTS idx_menus_category_id ON menus(category_id);
CREATE INDEX IF NOT EXISTS idx_menus_is_available ON menus(is_available);

CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_suppliers_company_id ON suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_branch_id ON suppliers(branch_id);

CREATE TABLE IF NOT EXISTS ingredients (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    stock DECIMAL(15, 2) DEFAULT 0,
    cost_per_unit DECIMAL(15, 2) DEFAULT 0,
    min_stock DECIMAL(15, 2) DEFAULT 0,
    supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_ingredients_company_id ON ingredients(company_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_branch_id ON ingredients(branch_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_stock ON ingredients(stock);

CREATE TABLE IF NOT EXISTS menu_ingredients (
    id SERIAL PRIMARY KEY,
    menu_id INT NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    ingredient_id INT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty_used DECIMAL(15, 3) NOT NULL,
    unit VARCHAR(20),
    UNIQUE(menu_id, ingredient_id)
);
CREATE INDEX IF NOT EXISTS idx_menu_ingredients_menu_id ON menu_ingredients(menu_id);
CREATE INDEX IF NOT EXISTS idx_menu_ingredients_ingredient_id ON menu_ingredients(ingredient_id);

CREATE TABLE IF NOT EXISTS tables (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    table_number VARCHAR(10) NOT NULL,
    capacity INT DEFAULT 4,
    floor VARCHAR(20),
    status VARCHAR(20) DEFAULT 'Kosong', -- Kosong, Digunakan, Dipesan
    position_x DECIMAL(10, 2) DEFAULT 0,
    position_y DECIMAL(10, 2) DEFAULT 0,
    image_url TEXT
);
CREATE INDEX IF NOT EXISTS idx_tables_branch_id ON tables(branch_id);
CREATE INDEX IF NOT EXISTS idx_tables_status ON tables(status);

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    loyalty_points INT DEFAULT 0,
    total_spent DECIMAL(15, 2) DEFAULT 0,
    tier VARCHAR(20) DEFAULT 'Bronze',
    is_send_wa BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_company_id ON customers(company_id);

CREATE TABLE IF NOT EXISTS promos (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'flat')),
    value DECIMAL(15, 2) NOT NULL,
    min_order DECIMAL(15, 2) DEFAULT 0,
    max_discount DECIMAL(15, 2) DEFAULT 0,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_promos_company_id ON promos(company_id);
CREATE INDEX IF NOT EXISTS idx_promos_status ON promos(is_active, start_date, end_date);

-- 3. Transactional Tables
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    table_id INT REFERENCES tables(id) ON DELETE SET NULL,
    user_id INT REFERENCES users(id),
    customer_id INT REFERENCES customers(id) ON DELETE SET NULL,
    promo_id INT REFERENCES promos(id) ON DELETE SET NULL,
    customer_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Pending', -- Pending, Proses, Selesai, Batal
    total_amount DECIMAL(15, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    service_charge_amount DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    shipping_fee DECIMAL(15, 2) DEFAULT 0,
    notes TEXT,
    is_paid BOOLEAN DEFAULT FALSE,
    void_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_orders_company_id ON orders(company_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_is_paid ON orders(is_paid);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
-- Composite indexes for dashboard/reporting
CREATE INDEX IF NOT EXISTS idx_orders_perf_company ON orders(company_id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_perf_branch ON orders(branch_id, status, created_at);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    menu_id INT REFERENCES menus(id),
    quantity INT NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    subtotal DECIMAL(15, 2) NOT NULL,
    notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_id ON order_items(menu_id);

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
    amount_paid DECIMAL(15, 2) NOT NULL,
    change DECIMAL(15, 2) DEFAULT 0,
    payment_method VARCHAR(50) NOT NULL,
    reference_no VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_company_id ON payments(company_id);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(payment_method);

CREATE TABLE IF NOT EXISTS cashier_sessions (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    open_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    close_time TIMESTAMP,
    initial_cash DECIMAL(15, 2) DEFAULT 0,
    closing_cash DECIMAL(15, 2) DEFAULT 0,
    total_sales DECIMAL(15, 2) DEFAULT 0,
    total_orders INT DEFAULT 0,
    notes TEXT,
    status VARCHAR(10) DEFAULT 'Open' -- Open, Closed
);
CREATE INDEX IF NOT EXISTS idx_cashier_sessions_user ON cashier_sessions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_cashier_sessions_branch ON cashier_sessions(branch_id, status);

-- 4. Inventory Tables
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
CREATE INDEX IF NOT EXISTS idx_branch_orders_company_id ON branch_orders(company_id);
CREATE INDEX IF NOT EXISTS idx_branch_orders_status ON branch_orders(status);

CREATE TABLE IF NOT EXISTS branch_order_items (
    id SERIAL PRIMARY KEY,
    branch_order_id INT REFERENCES branch_orders(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    approved_qty DECIMAL(15, 2) DEFAULT 0,
    notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_branch_order_items_order_id ON branch_order_items(branch_order_id);

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
    status VARCHAR(20) DEFAULT 'Draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_company_id ON goods_receipts(company_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_branch_id ON goods_receipts(branch_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_status ON goods_receipts(status);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_receipt_date ON goods_receipts(receipt_date);

CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id SERIAL PRIMARY KEY,
    receipt_id INT REFERENCES goods_receipts(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2) NOT NULL,
    subtotal DECIMAL(15, 2) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt_id ON goods_receipt_items(receipt_id);

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
CREATE INDEX IF NOT EXISTS idx_goods_issues_company_id ON goods_issues(company_id);
CREATE INDEX IF NOT EXISTS idx_goods_issues_status ON goods_issues(status);

CREATE TABLE IF NOT EXISTS goods_issue_items (
    id SERIAL PRIMARY KEY,
    issue_id INT REFERENCES goods_issues(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 2) NOT NULL,
    notes TEXT
);

-- 5. Finance Tables
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_accounts_company_id ON accounts(company_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_branch_code ON accounts (COALESCE(branch_id, 0), code);

CREATE TABLE IF NOT EXISTS journal_entries (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    reference VARCHAR(100),
    total_amount DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_journal_entries_branch_id ON journal_entries(branch_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_date ON journal_entries(date);

CREATE TABLE IF NOT EXISTS journal_items (
    id SERIAL PRIMARY KEY,
    journal_id INT REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id INT REFERENCES accounts(id) ON DELETE CASCADE,
    debit DECIMAL(15, 2) DEFAULT 0,
    credit DECIMAL(15, 2) DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_journal_items_journal_id ON journal_items(journal_id);

-- 6. Sidebar & System
CREATE TABLE IF NOT EXISTS sidebar_menus (
    id SERIAL PRIMARY KEY,
    parent_id INT REFERENCES sidebar_menus(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    path VARCHAR(100),
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    is_header BOOLEAN DEFAULT FALSE,
    UNIQUE (title, path)
);

CREATE TABLE IF NOT EXISTS role_menus (
    role_id INT REFERENCES roles(id) ON DELETE CASCADE,
    sidebar_menu_id INT REFERENCES sidebar_menus(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, sidebar_menu_id)
);

CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    key VARCHAR(50) NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_settings_branch_key ON system_settings (COALESCE(branch_id, 0), key);

CREATE TABLE IF NOT EXISTS stock_histories (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL, -- IN, OUT, ADJUST, WASTE, VOID
    quantity DECIMAL(15, 3) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_stock_histories_ingredient_id ON stock_histories(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_stock_histories_created_at ON stock_histories(created_at);

CREATE TABLE IF NOT EXISTS wa_logs (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE SET NULL,
    customer_id INT REFERENCES customers(id) ON DELETE SET NULL,
    phone VARCHAR(20),
    message TEXT,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Roles
INSERT INTO roles (id, name, description) VALUES 
(1, 'Admin', 'Administrator with full access'),
(2, 'Manager', 'Branch Manager'),
(3, 'Cashier', 'Cashier staff'),
(4, 'Kitchen', 'Kitchen staff'),
(5, 'Executive', 'Company Executive (Multi-branch view)')
ON CONFLICT (id) DO NOTHING;

-- Companies
INSERT INTO companies (id, name, code, address, phone, email)
VALUES (1, 'NFM Group', 'NFM001', 'Main Office', '0812345678', 'info@nfm.com')
ON CONFLICT (id) DO NOTHING;

-- Branches
INSERT INTO branches (id, company_id, name, code, address)
VALUES (1, 1, 'NFM Resto Center', 'BR001', 'Jakarta Center')
ON CONFLICT (id) DO NOTHING;

-- Default User (Password: admin123)
-- Hash generated for: admin123
INSERT INTO users (id, company_id, branch_id, role_id, full_name, username, password_hash)
VALUES (1, 1, 1, 1, 'Super Admin', 'admin', '$2a$10$R9h6E7pIu.z8sJ1o0y9u.e8u.e8u.e8u.e8u.e8u.e8u.e8u.e8u.')
ON CONFLICT (id) DO NOTHING;

-- Sidebar Menus
TRUNCATE sidebar_menus CASCADE;
INSERT INTO sidebar_menus (title, path, icon, sort_order, is_header) VALUES 
('Dashboard', '/dashboard', 'dashboard', 1, FALSE),
('Dashboard Executive', '/dashboard/executive', 'insights', 2, FALSE),
('OPERASIONAL', NULL, NULL, 5, TRUE),
('Point of Sale', '/pos', 'shopping_cart', 6, FALSE),
('Kitchen Display', '/kitchen', 'kitchen', 7, FALSE),
('Daftar Pesanan', '/orders', 'receipt_long', 8, FALSE),
('Barang Masuk', '/inventory/receipts', 'input', 60, FALSE),
('Barang Keluar', '/inventory/issues', 'output', 61, FALSE),
('Pesanan Cabang', '/inventory/branch-orders', 'local_shipping', 62, FALSE),
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
('Monitoring Meja', '/monitoring-tables', 'monitor', 26, FALSE),
('Denah Meja', '/layout-tables', 'map', 27, FALSE),
('Perusahaan', '/companies', 'corporate_fare', 110, FALSE);

-- Map all menus to Admin (Role ID 1)
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 1, id FROM sidebar_menus ON CONFLICT DO NOTHING;
