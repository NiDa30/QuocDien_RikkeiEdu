CREATE TABLE products(
product_id SERIAL PRIMARY KEY,
product_name VARCHAR(100),
stock INT,
price NUMERIC(10,2)
);
CREATE TABLE orders(
order_id SERIAL PRIMARY KEY,
customer_name VARCHAR(100),
total_amount NUMERIC(10,2),
create_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE order_items(
order_item_id SERIAL PRIMARY KEY,
order_id INT REFERENCES orders(order_id),
product_id INT REFERENCES products(product_id),
quantity INT,
subtotal NUMERIC(10,2)
);

INSERT INTO products (product_name, stock, price) VALUES 
('iPhone 16', 10, 25000000),
('MacBook Air', 5, 35000000),
('AirPods Pro', 20, 6500000);


--1
-- a) Bắt đầu Transaction
BEGIN;

-- b) Tạo đơn hàng chính
INSERT INTO orders (customer_name, total_amount) 
VALUES ('Nguyen Van A', 0) 
RETURNING order_id;

-- Lấy order_id vừa tạo (giả sử = 1)
-- c) Thêm 2 sản phẩm: iPhone (id=1, qty=2), MacBook (id=2, qty=1)
INSERT INTO order_items (order_id, product_id, quantity, subtotal) VALUES
(1, 1, 2, 2*25000000),  
(1, 2, 1, 1*35000000);  

-- d) Kiểm tra & trừ tồn kho
UPDATE products SET stock = stock - 2 WHERE product_id = 1;  -- iPhone: 10→8
UPDATE products SET stock = stock - 1 WHERE product_id = 2;  -- MacBook: 5→4

-- e) Cập nhật total_amount = 85tr
UPDATE orders 
SET total_amount = 85000000 
WHERE order_id = 1;

-- f) Hoàn tất Transaction
COMMIT;

--kiểm tra 
SELECT * FROM orders WHERE customer_name = 'Nguyen Van A';

SELECT * FROM order_items WHERE order_id = 1;

SELECT product_id, product_name, stock FROM products WHERE product_id IN (1,2);

--2 
-- a) Bắt đầu Transaction mới
BEGIN;

-- b) Tạo đơn hàng
INSERT INTO orders (customer_name, total_amount) VALUES ('Tran Thi B', 0) RETURNING order_id;

-- c) Lỗi: Đặt 15 iPhone (chỉ còn 8!)
INSERT INTO order_items (order_id, product_id, quantity, subtotal) 
VALUES (2, 1, 15, 15*25000000);

-- d) Trừ tồn kho → LỖI: stock âm!
UPDATE products SET stock = stock - 15 WHERE product_id = 1;  -- 8-15 = -7!

-- e) ROLLBACK hủy TẤT CẢ thay đổi
ROLLBACK;

--kiểm tra ROLLBACK
-- Tồn kho KHÔNG thay đổi!
SELECT stock FROM products WHERE product_id = 1;  -- VẪN 8 ✓

-- Đơn hàng KHÔNG được tạo!
SELECT COUNT(*) FROM orders WHERE customer_name = 'Tran Thi B';  -- 0 ✓
