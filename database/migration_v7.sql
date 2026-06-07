-- ============================================================
-- Migration v7: Dokumentasi Menu untuk Role Super User
-- Tanggal: 2026-06-07
-- Deskripsi:
--   1. Tambah icon 'menu_book' support (dokumentasi saja, di frontend)
--   2. Insert sidebar menu 'Dokumentasi' dengan path /documentation
--   3. Assign menu tersebut ke role Super User
-- ============================================================

-- 1. Insert sidebar menu Dokumentasi (idempotent: skip jika sudah ada)
INSERT INTO sidebar_menus (title, path, icon, sort_order, is_header, parent_id)
SELECT 'Dokumentasi', '/documentation', 'menu_book', 76, false, NULL
WHERE NOT EXISTS (
    SELECT 1 FROM sidebar_menus WHERE path = '/documentation'
);

-- 2. Assign menu Dokumentasi ke role Super User (idempotent)
INSERT INTO role_menus (role_id, sidebar_menu_id)
SELECT r.id, sm.id
FROM roles r, sidebar_menus sm
WHERE r.name = 'Super User'
  AND sm.path = '/documentation'
  AND NOT EXISTS (
    SELECT 1 FROM role_menus rm2
    WHERE rm2.role_id = r.id AND rm2.sidebar_menu_id = sm.id
  );

-- Verifikasi hasil
SELECT 
    sm.id,
    sm.title,
    sm.path,
    sm.icon,
    sm.sort_order,
    r.name AS assigned_role
FROM sidebar_menus sm
JOIN role_menus rm ON rm.sidebar_menu_id = sm.id
JOIN roles r ON r.id = rm.role_id
WHERE sm.path = '/documentation';
