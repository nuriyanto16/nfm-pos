-- ============================================================
-- CLEANUP & RESET SIDEBAR MENUS
-- ============================================================

-- 1. Kosongkan tabel (CASCADE akan ikut menghapus role_menus)
TRUNCATE sidebar_menus CASCADE;

-- 2. Insert Menu Utama
INSERT INTO sidebar_menus (id, title, path, icon, sort_order, is_header) VALUES 
(1, 'Dashboard', '/dashboard', 'dashboard', 1, FALSE),
(2, 'Dashboard Executive', '/dashboard/executive', 'insights', 2, FALSE),
(3, 'OPERASIONAL', NULL, NULL, 5, TRUE),
(4, 'Point of Sale', '/pos', 'shopping_cart', 6, FALSE),
(5, 'Kitchen Display', '/kitchen', 'kitchen', 7, FALSE),
(6, 'Daftar Pesanan', '/orders', 'receipt_long', 8, FALSE),
(7, 'Barang Masuk', '/inventory/receipts', 'input', 60, FALSE),
(8, 'Barang Keluar', '/inventory/issues', 'output', 61, FALSE),
(9, 'Pesanan Cabang', '/inventory/branch-orders', 'local_shipping', 62, FALSE),
(10, 'KEUANGAN', NULL, NULL, 10, TRUE),
(11, 'Jurnal Umum', '/finance/journal', 'book', 11, FALSE),
(12, 'Buku Besar', '/finance/ledger', 'account_balance', 12, FALSE),
(13, 'Chart of Accounts', '/finance/coa', 'list_alt', 13, FALSE),
(14, 'MASTER DATA', NULL, NULL, 20, TRUE),
(15, 'Manajemen Menu', '/menus', 'restaurant_menu', 21, FALSE),
(16, 'Kategori', '/menus', 'category', 22, FALSE),
(17, 'Meja', '/manage-tables', 'table_restaurant', 23, FALSE),
(18, 'Pelanggan', '/customers', 'person', 24, FALSE),
(19, 'Stok & Bahan', '/ingredients', 'inventory_2', 25, FALSE),
(20, 'Monitoring Meja', '/monitoring-tables', 'monitor', 26, FALSE),
(21, 'Denah Meja', '/layout-tables', 'map', 27, FALSE),
(22, 'SISTEM', NULL, NULL, 40, TRUE),
(23, 'Pengaturan', '/settings', 'settings', 41, FALSE),
(24, 'User Management', '/users', 'people', 42, FALSE),
(25, 'Role Privilege', '/roles', 'security', 43, FALSE),
(26, 'Sidebar Management', '/management/sidebar', 'menu_open', 44, FALSE),
(27, 'Perusahaan', '/companies', 'corporate_fare', 110, FALSE),
(28, 'CHATBOT', NULL, NULL, 100, TRUE),
(29, 'Chatbot History', '/chatbot-logs', 'chat', 101, FALSE),
(30, 'Chatbot Knowledge', '/chatbot-knowledge', 'school', 102, FALSE);

-- Reset sequence ID
SELECT setval('sidebar_menus_id_seq', (SELECT MAX(id) FROM sidebar_menus));

-- 3. Atur Role Privileges

-- Role 1: Admin (Semua Menu)
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 1, id FROM sidebar_menus;

-- Role 5: Executive
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 5, id FROM sidebar_menus 
WHERE path IN (
    '/dashboard/executive', 
    '/chatbot-logs', 
    '/chatbot-knowledge', 
    '/reports',
    '/companies'
) OR (is_header = TRUE AND title IN ('KEUANGAN', 'CHATBOT'));

-- Role 3: Kasir
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 3, id FROM sidebar_menus 
WHERE path IN ('/dashboard', '/pos', '/orders', '/monitoring-tables')
OR (is_header = TRUE AND title IN ('OPERASIONAL'));

-- Role 4: Dapur
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 4, id FROM sidebar_menus 
WHERE path IN ('/kitchen')
OR (is_header = TRUE AND title IN ('OPERASIONAL'));

-- Role 2: Manager
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 2, id FROM sidebar_menus 
WHERE path NOT IN ('/chatbot-knowledge', '/dashboard/executive')
OR (is_header = TRUE);
