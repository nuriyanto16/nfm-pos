-- ============================================================
-- CLEANUP & RESET SIDEBAR MENUS
-- ============================================================

-- 1. Kosongkan tabel (CASCADE akan ikut menghapus role_menus)
TRUNCATE sidebar_menus CASCADE;

-- 2. Insert Menu Utama
INSERT INTO sidebar_menus (id, title, path, icon, sort_order, is_header) VALUES 
-- SECTION 1: DASHBOARD
(1, 'Dashboard', '/dashboard', 'dashboard', 1, FALSE),
(2, 'Dashboard Executive', '/dashboard/executive', 'insights', 2, FALSE),

-- SECTION 2: TRANSAKSI & LAYANAN
(3, 'TRANSAKSI & LAYANAN', NULL, NULL, 10, TRUE),
(4, 'POS Resto', '/pos?type=resto', 'restaurant', 11, FALSE),
(5, 'POS Fashion', '/pos?type=fashion', 'shopping_bag', 12, FALSE),
(6, 'POS Retail/Toko', '/pos?type=retail', 'storefront', 13, FALSE),
(7, 'POS Jasa', '/pos?type=jasa', 'dry_cleaning', 14, FALSE),
(8, 'Kitchen Display', '/kitchen', 'kitchen', 15, FALSE),
(9, 'Daftar Pesanan', '/orders', 'receipt_long', 16, FALSE),
(10, 'Monitoring Meja', '/monitoring-tables', 'monitor', 17, FALSE),
(11, 'Denah Meja', '/layout-tables', 'map', 18, FALSE),

-- SECTION 3: INVENTORY & STOK
(12, 'INVENTORY & STOK', NULL, NULL, 20, TRUE),
(13, 'Stok & Bahan', '/ingredients', 'inventory_2', 21, FALSE),
(14, 'Barang Masuk', '/inventory/receipts', 'input', 22, FALSE),
(15, 'Barang Keluar', '/inventory/issues', 'output', 23, FALSE),
(16, 'Pesanan Cabang', '/inventory/branch-orders', 'local_shipping', 24, FALSE),
(17, 'Monitoring Stok', '/inventory/stock-history', 'history', 25, FALSE),

-- SECTION 4: KEUANGAN
(18, 'KEUANGAN', NULL, NULL, 30, TRUE),
(19, 'Jurnal Umum', '/finance/journal', 'book', 31, FALSE),
(20, 'Buku Besar', '/finance/ledger', 'account_balance', 32, FALSE),
(21, 'Chart of Accounts', '/finance/coa', 'list_alt', 33, FALSE),

-- SECTION 5: MASTER DATA
(22, 'MASTER DATA', NULL, NULL, 40, TRUE),
(23, 'Manajemen Menu Resto', '/menus?type=resto', 'restaurant_menu', 41, FALSE),
(24, 'Manajemen Barang (Fashion)', '/menus?type=fashion', 'shopping_bag', 42, FALSE),
(25, 'Manajemen Barang (Retail)', '/menus?type=retail', 'storefront', 43, FALSE),
(26, 'Manajemen Layanan Jasa', '/menus?type=jasa', 'dry_cleaning', 44, FALSE),
(27, 'Kategori', '/menus', 'category', 45, FALSE),
(28, 'Pelanggan', '/customers', 'person', 46, FALSE),
(29, 'Meja', '/manage-tables', 'table_restaurant', 47, FALSE),
(30, 'Perusahaan', '/companies', 'corporate_fare', 48, FALSE),
(31, 'User Registrasi Online', '/customer-users', 'group_add', 49, FALSE),

-- SECTION 6: LAPORAN
(32, 'LAPORAN', NULL, NULL, 50, TRUE),
(33, 'Laporan Penjualan', '/reports/sales', 'assessment', 51, FALSE),

-- SECTION 7: CHATBOT AI
(34, 'CHATBOT AI', NULL, NULL, 60, TRUE),
(35, 'Chatbot History', '/chatbot-logs', 'chat', 61, FALSE),
(36, 'Chatbot Knowledge', '/chatbot-knowledge', 'school', 62, FALSE),

-- SECTION 8: SISTEM
(37, 'SISTEM', NULL, NULL, 70, TRUE),
(38, 'Pengaturan', '/settings', 'settings', 71, FALSE),
(39, 'User Management', '/users', 'people', 72, FALSE),
(40, 'Role Privilege', '/roles', 'security', 73, FALSE),
(41, 'Sidebar Management', '/management/sidebar', 'menu_open', 74, FALSE),
(42, 'Registrasi Trial', '/registrations', 'app_registration', 75, FALSE);

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
    '/reports/sales',
    '/companies'
) OR (is_header = TRUE AND title IN ('KEUANGAN', 'CHATBOT AI', 'LAPORAN'));

-- Role 3: Kasir
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 3, id FROM sidebar_menus 
WHERE path IN (
    '/dashboard', 
    '/pos?type=resto', 
    '/pos?type=fashion', 
    '/pos?type=retail', 
    '/pos?type=jasa', 
    '/orders', 
    '/monitoring-tables'
) OR (is_header = TRUE AND title IN ('TRANSAKSI & LAYANAN'));

-- Role 4: Dapur
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 4, id FROM sidebar_menus 
WHERE path IN ('/kitchen')
OR (is_header = TRUE AND title IN ('TRANSAKSI & LAYANAN'));

-- Role 2: Manager
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT 2, id FROM sidebar_menus 
WHERE path NOT IN ('/chatbot-knowledge', '/dashboard/executive')
OR (is_header = TRUE);
