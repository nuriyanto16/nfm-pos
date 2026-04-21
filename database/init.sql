-- Roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (name) VALUES ('Admin'), ('Kasir'), ('Waiter'), ('Manager');

-- Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT REFERENCES roles(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Note: Password default is 'password' (bcrypt hash format should be used in app, using dummy here, but for login to work smoothly without bcrypt initially, we can put a plain text or let the app create it. We will assume the backend will hash passwords, so we will create a user via the app or insert a known bcrypt hash here. Let's insert a known bcrypt hash for 'password123': $2a$10$tZ2xN3.y.tS/l1x5B5TMW.2M5Z.X2Q6J2M5X2Q6J2M5X2Q6J2M5X )
-- We'll just create the table and use the app's seeder/register endpoint.

-- Categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

INSERT INTO categories (name, description) VALUES 
('Makanan', 'Aneka makanan utama dan cemilan'), 
('Minuman', 'Aneka minuman dingin dan panas'), 
('Paket', 'Paket hemat kombinasi makanan dan minuman');

-- Menus
CREATE TABLE menus (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO menus (category_id, name, description, price, stock, image_url) VALUES 
(1, 'Nasi Goreng Spesial', 'Nasi goreng dengan ayam, telur, dan kerupuk', 35000, 50, ''),
(1, 'Mie Goreng Seafood', 'Mie goreng dengan udang dan cumi', 40000, 30, ''),
(2, 'Es Teh Manis', 'Teh melati manis dingin', 10000, 100, ''),
(2, 'Kopi Susu Gula Aren', 'Kopi kekinian dengan gula aren asli', 20000, 50, ''),
(3, 'Paket Hemat 1', 'Nasi Goreng + Es Teh Manis', 40000, 20, '');

-- Tables
CREATE TABLE tables (
    id SERIAL PRIMARY KEY,
    table_number VARCHAR(10) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'Kosong' CHECK (status IN ('Kosong', 'Dipesan', 'Digunakan'))
);

INSERT INTO tables (table_number, status) VALUES 
('T1', 'Kosong'), ('T2', 'Kosong'), ('T3', 'Kosong'), ('T4', 'Kosong'), ('T5', 'Kosong');

-- Orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    table_id INT REFERENCES tables(id) ON DELETE SET NULL, -- NULL is take-away
    user_id INT REFERENCES users(id) ON DELETE SET NULL, -- Waiter/Kasir who created and took the order
    customer_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Proses', 'Selesai', 'Batal')),
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    menu_id INT REFERENCES menus(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    price DECIMAL(12,2) NOT NULL, -- Price at the time of order
    subtotal DECIMAL(12,2) NOT NULL
);

-- Payments
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    amount_paid DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Tunai', 'QRIS', 'E-Wallet')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

