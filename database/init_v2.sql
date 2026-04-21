-- Customers
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (name, phone, address) VALUES 
('Budi Santoso', '081234567890', 'Jl. Merdeka No. 10'),
('Siti Aminah', '081987654321', 'Jl. Sudirman No. 5'),
('Andi Wijaya', '085678901234', 'Jl. Gatot Subroto No. 20');

-- Add customer_id column to orders if not exists (AutoMigrate will handle this, but for SQL consistency)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id INT REFERENCES customers(id) ON DELETE SET NULL;
