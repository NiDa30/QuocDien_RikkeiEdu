CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    order_date DATE DEFAULT CURRENT_DATE
);

INSERT INTO products (name, stock) VALUES 
('Laptop Dell', 100),
('iPhone 16', 50),
('Samsung TV', 75);

-- tạo trigger function quản lý tồn kho
CREATE OR REPLACE FUNCTION manage_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_current_stock INTEGER;
BEGIN
    SELECT stock INTO v_current_stock 
    FROM products 
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    
    IF TG_OP = 'INSERT' THEN
        IF v_current_stock < NEW.quantity THEN
            RAISE EXCEPTION 'Không đủ tồn kho! Product %: Còn % nhưng đặt %', 
                NEW.product_id, v_current_stock, NEW.quantity;
        END IF;
        UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
        
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE products 
        SET stock = stock + OLD.quantity - NEW.quantity 
        WHERE id = NEW.product_id;
        
        IF (SELECT stock FROM products WHERE id = NEW.product_id) < 0 THEN
            RAISE EXCEPTION 'Tồn kho âm sau khi sửa đơn hàng! Product %', NEW.product_id;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products SET stock = stock + OLD.quantity WHERE id = OLD.product_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- tạo trigger AFTER cho 3 sự kiện
CREATE TRIGGER trg_manage_stock
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION manage_stock();

-- test trigger
INSERT INTO orders (product_id, quantity) VALUES (1, 10);  -- Laptop: 100→90 ✓
INSERT INTO orders (product_id, quantity) VALUES (2, 5);   -- iPhone: 50→45 ✓

INSERT INTO orders (product_id, quantity) VALUES (2, 60);  -- iPhone chỉ còn 45! ❌

UPDATE orders SET quantity = 15 WHERE id = 1; 

UPDATE orders SET quantity = 8 WHERE id = 1;   

DELETE FROM orders WHERE id = 1;  

-- kiểm tra kết quả
SELECT * FROM products ORDER BY id;

SELECT o.*, p.name FROM orders o JOIN products p ON o.product_id = p.id;
