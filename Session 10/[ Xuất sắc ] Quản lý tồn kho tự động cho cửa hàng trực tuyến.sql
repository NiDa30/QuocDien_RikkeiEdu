CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    order_status VARCHAR(20) DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'cancelled'))
);

INSERT INTO products (name, stock) VALUES 
('iPhone 16 Pro', 50),
('Samsung Galaxy S26', 30),
('MacBook Air M3', 20);

-- tạo trigger function quản lý tồn kho
CREATE OR REPLACE FUNCTION manage_product_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_current_stock INTEGER;
BEGIN
    SELECT stock INTO v_current_stock 
    FROM products 
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    
    IF TG_OP = 'INSERT' THEN
        IF v_current_stock < NEW.quantity THEN
            RAISE EXCEPTION '❌ Không đủ hàng! Product %: Còn % nhưng đặt %', 
                NEW.product_id, v_current_stock, NEW.quantity;
        END IF;
        UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
        RAISE NOTICE '✅ Đã trừ % sản phẩm %. Tồn kho còn: %', NEW.quantity, NEW.product_id, v_current_stock - NEW.quantity;
        
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.quantity != NEW.quantity OR OLD.order_status != NEW.order_status THEN
            UPDATE products 
            SET stock = stock + OLD.quantity - NEW.quantity 
            WHERE id = NEW.product_id;
            
            IF (SELECT stock FROM products WHERE id = NEW.product_id) < 0 THEN
                RAISE EXCEPTION '❌ Tồn kho âm! Product % sau khi sửa đơn %', NEW.product_id, NEW.id;
            END IF;
            RAISE NOTICE '✅ Cập nhật tồn kho product %: % → %', NEW.product_id, OLD.quantity, NEW.quantity;
        END IF;
        
    ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.order_status = 'cancelled') THEN
        UPDATE products SET stock = stock + COALESCE(OLD.quantity, NEW.quantity) 
        WHERE id = COALESCE(OLD.product_id, NEW.product_id);
        RAISE NOTICE '✅ Hoàn % sản phẩm % vào kho', OLD.quantity, OLD.product_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- tạo trigger
CREATE TRIGGER trg_manage_stock
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION manage_product_stock();

--test
INSERT INTO orders (product_id, quantity, order_status) VALUES (1, 5, 'confirmed');

INSERT INTO orders (product_id, quantity) VALUES (1, 60); 

INSERT INTO orders (product_id, quantity) VALUES (2, 3);  
UPDATE orders SET quantity = 10 WHERE id = 2;             

UPDATE orders SET quantity = 2 WHERE id = 2;             

UPDATE orders SET order_status = 'cancelled' WHERE id = 1; 

DELETE FROM orders WHERE id = 1;                         

-- kiểm tra kết quả
-- Tồn kho hiện tại
SELECT * FROM products ORDER BY id;

SELECT o.id, p.name, o.quantity, o.order_status FROM orders o 
JOIN products p ON o.product_id = p.id;
