-- ============================================================
-- POS Resto v4 — Branch & Franchising Migration
-- ============================================================

-- 1. Create branches table
CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Seed default branch
INSERT INTO branches (name, code, address, phone, email)
VALUES ('Pusat (HQ)', 'HQ001', 'Jakarta Head Office', '021-123456', 'hq@resto.com')
ON CONFLICT (code) DO NOTHING;

-- 3. Add branch_id to existing tables
-- Users
ALTER TABLE users ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;
UPDATE users SET branch_id = 1 WHERE branch_id IS NULL;

-- Categories (can be global if branch_id is NULL)
ALTER TABLE categories ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;

-- Menus (can be global if branch_id is NULL)
ALTER TABLE menus ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;

-- Tables (must belong to a branch)
ALTER TABLE tables ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE CASCADE;
UPDATE tables SET branch_id = 1 WHERE branch_id IS NULL;

-- Orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE CASCADE;
UPDATE orders SET branch_id = 1 WHERE branch_id IS NULL;

-- Payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE CASCADE;
UPDATE payments SET branch_id = 1 WHERE branch_id IS NULL;

-- Cashier Sessions
ALTER TABLE cashier_sessions ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE CASCADE;
UPDATE cashier_sessions SET branch_id = 1 WHERE branch_id IS NULL;

-- Promos (can be global)
ALTER TABLE promos ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;

-- Suppliers (can be global)
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;

-- Ingredients
ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES branches(id) ON DELETE SET NULL;

-- 4. Fix table_number unique constraint (should be unique PER branch)
ALTER TABLE tables DROP CONSTRAINT IF EXISTS tables_table_number_key;
-- Check if the unique index exists and drop if so
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_table_number_branch') THEN
        DROP INDEX idx_table_number_branch;
    END IF;
END $$;
-- Note: GORM will handle composite unique indexes if specified or we can do it manually:
-- CREATE UNIQUE INDEX idx_table_number_branch ON tables(table_number, branch_id);

-- 5. Add default branch to existing orders items if needed (usually handled by order parent)
-- Everything else should be fine with existing constraints.
