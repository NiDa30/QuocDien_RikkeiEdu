CREATE TABLE customers(
      customer_id SERIAL PRIMARY KEY,
     name VARCHAR(100),
     balance NUMERIC(12,2)
);
CREATE TABLE Product (
      product_id SERIAL PRIMARY KEY,
     name VARCHAR(100),
     stock INT,
     price NUMERIC(10,2)
);

CREATE TABLE orders(
     order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
     total_amount NUMERIC(12,2),
    create_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'PENDING'
);
CREATE TABLE order_items(
      item_id SERIAL PRIMARY KEY,
     order_id INT REFERENCES orders(order_id),
     product_id INT REFERENCES products(product_id),
    quantity INT, 
    subtotal NUMERIC(10,2)
);

INSERT INTO customers (name, balance) VALUES 
('Tran Thi B', 100000000);

INSERT INTO products (name, stock, price) VALUES 
('iPhone 16 Pro', 5, 25000000),
('MacBook Air M3', 3, 35000000);

--1 Transaction đặt hàng thành công
-- a) Bắt đầu SERIALIZABLE (ngăn oversell)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;

-- b) Tạo đơn hàng: iPhone(id=1,qty=1) + MacBook(id=2,qty=1)
INSERT INTO orders (customer_id, total_amount, status) 
VALUES (1, 0, 'PENDING') 
RETURNING order_id \gset  

-- c) SAVEPOINT trước khi trừ kho
SAVEPOINT before_stock_check;

-- d) Kiểm tra & trừ tồn kho
DO $$
DECLARE
    v_iphone_stock INT;
    v_macbook_stock INT;
BEGIN
    SELECT stock INTO v_iphone_stock FROM products WHERE product_id = 1;
    SELECT stock INTO v_macbook_stock FROM products WHERE product_id = 2;
    
    IF v_iphone_stock < 1 OR v_macbook_stock < 1 THEN
        RAISE EXCEPTION 'Không đủ tồn kho!';
    END IF;
END $$;

-- e) Trừ tồn kho
UPDATE products SET stock = stock - 1 WHERE product_id = 1;  
UPDATE products SET stock = stock - 1 WHERE product_id = 2;  

-- f) Tạo order_items
INSERT INTO order_items (order_id, product_id, quantity, subtotal) VALUES
(:order_id, 1, 1, 25000000),
(:order_id, 2, 1, 35000000);

-- g) Trừ tiền customer
UPDATE customers 
SET balance = balance - 60000000 
WHERE customer_id = 1 AND balance >= 60000000;

-- h) Cập nhật order status = COMPLETED & total_amount
UPDATE orders 
SET status = 'COMPLETED', total_amount = 60000000 
WHERE order_id = :order_id;

-- i) COMMIT hoàn tất
COMMIT;


--2. Transaction ROLLBACK
BEGIN;

-- Tạo order
INSERT INTO orders (customer_id, status) VALUES (1, 'PENDING') RETURNING order_id \gset

SAVEPOINT before_stock_check;

-- Lỗi: Đặt 6 iPhone (chỉ còn 4!)
DO $$ BEGIN
    IF (SELECT stock FROM products WHERE product_id = 1) < 6 THEN
        RAISE EXCEPTION 'Không đủ iPhone!';
    END IF;
END $$;

-- Rollback CHỈ phần trừ kho, giữ order PENDING
ROLLBACK TO before_stock_check;

-- Cập nhật order status = CANCELLED
UPDATE orders SET status = 'CANCELLED' WHERE order_id = :order_id;

COMMIT;

--3. Kiểm tra tình trạng đơn hàng
-- Tổng quan đơn hàng
SELECT o.order_id, o.status, o.total_amount, c.name,
       SUM(oi.quantity * p.price) as items_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.status, o.total_amount, c.name;

-- Tồn kho hiện tại
SELECT product_id, name, stock FROM products;
