CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tạo trigger function
CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- tạo trigger BEFORE UPDATE
CREATE TRIGGER trg_update_last_modified
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_last_modified();

-- chèn dữ liệu
INSERT INTO products (name, price) VALUES 
('Laptop Dell', 25000000),
('iPhone 16', 30000000);

-- kiểm trả
SELECT * FROM products;

UPDATE products SET price = price * 1.1 WHERE name = 'Laptop Dell';

-- Kiểm tra last_modified đã cập nhật
SELECT * FROM products;
