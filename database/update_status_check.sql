-- Update orders status check constraint to include 'Siap'
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ('Pending', 'Proses', 'Siap', 'Selesai', 'Batal'));
