-- Dùng DROP để xóa hoàn toàn bảng cũ (cấu trúc + dữ liệu)
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS customer CASCADE;

-- 1. Tạo bảng Customer (Độc lập)
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    region VARCHAR(50)
);

-- 2. Tạo bảng Product (Đưa lên trước Orders)
CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category TEXT[],
    price NUMERIC(10,2)
);

-- 3. Tạo bảng Orders (Phụ thuộc vào 2 bảng trên)
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    product_id INT REFERENCES product(product_id), -- Lúc này bảng product đã tồn tại nên không lỗi nữa
    order_date DATE,
    quantity INT
);



--1.Thêm dữ liệu mẫu (ít nhất 5 khách hàng, 5 sản phẩm, 10 đơn hàng)
-- Thêm dữ liệu vào bảng Customer
INSERT INTO customer (full_name, email, region) VALUES
('Nguyen Van A', 'a@mail.com', 'Hanoi'),
('Tran Thi B', 'b@mail.com', 'HCMC'),
('Le Van C', 'c@mail.com', 'Danang'),
('Pham Thi D', 'd@mail.com', 'Hanoi'),
('Hoang Van E', 'e@mail.com', 'HCMC');

-- Thêm dữ liệu vào bảng Product (Chú ý: category là mảng TEXT[])
INSERT INTO product (product_name, category, price) VALUES
('Laptop Dell', ARRAY['Electronics', 'Computers'], 1200.00),
('iPhone 15', ARRAY['Electronics', 'Phones'], 999.00),
('Nike Shoes', ARRAY['Fashion', 'Sport'], 120.00),
('Coffee Machine', ARRAY['Home', 'Appliances'], 250.00),
('Book SQL', ARRAY['Books', 'Education'], 45.00);

-- Thêm dữ liệu vào bảng Orders
INSERT INTO orders (customer_id, product_id, order_date, quantity) VALUES
(1, 1, '2024-01-10', 1),
(2, 2, '2024-01-12', 1),
(3, 3, '2024-01-15', 2),
(1, 4, '2024-01-20', 1),
(4, 5, '2024-02-01', 3),
(2, 1, '2024-02-05', 1),
(5, 2, '2024-02-10', 1),
(3, 1, '2024-02-15', 1),
(1, 5, '2024-03-01', 2),
(2, 3, '2024-03-05', 1);


--2.Tối ưu truy vấn tìm kiếm khách hàng và sản phẩm:
--a.Tạo chỉ mục B-tree trên cột email để tối ưu tìm khách hàng theo email
CREATE INDEX idx_customer_email ON customer(email);

--b.Tạo chỉ mục Hash trên cột city để lọc theo thành phố
CREATE INDEX idx_customer_region_hash ON customer USING HASH (region);

--c.Tạo chỉ mục GIN trên cột category của products để hỗ trợ tìm theo danh mục (mảng)
CREATE INDEX idx_product_category_gin ON product USING GIN (category);

--d.Tạo chỉ mục GiST trên cột price để hỗ trợ tìm sản phẩm trong khoảng giá
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Tạo Index GiST cho price
CREATE INDEX idx_product_price_gist ON product USING GIST (price);

--3.Thực hiện một số truy vấn trước và sau khi có Index:
--a.Tìm khách hàng có email cụ thể
EXPLAIN ANALYZE SELECT * FROM customer WHERE email = 'a@mail.com';

--b.Tìm sản phẩm có category chứa 'Electronics'
EXPLAIN ANALYZE SELECT * FROM product WHERE category @> ARRAY['Electronics'];

--c.Tìm sản phẩm trong khoảng giá từ 500 đến 1000
EXPLAIN ANALYZE SELECT * FROM product WHERE price BETWEEN 500 AND 1000;

--d.Dùng EXPLAIN ANALYZE để so sánh hiệu suất truy vấn trước và sau khi tạo Index

--4.Thực hiện Clustered Index trên bảng orders theo cột order_date
CREATE INDEX idx_orders_date ON orders(order_date);
CLUSTER orders USING idx_orders_date;

--5.Sử dụng View để:
--a.Xem top 3 khách hàng mua nhiều nhất
CREATE OR REPLACE VIEW v_top_customers AS
SELECT 
    c.full_name, 
    COUNT(o.order_id) as total_orders,
    SUM(p.price * o.quantity) as total_spent
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN product p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC
LIMIT 3;

SELECT * FROM v_top_customers;

--b.Xem tổng doanh thu theo từng sản phẩm
CREATE OR REPLACE VIEW v_product_revenue AS
SELECT 
    p.product_name, 
    SUM(p.price * o.quantity) as revenue
FROM product p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name;

SELECT * FROM v_product_revenue;
 

--6.Thực hành cập nhật dữ liệu qua View có thể ghi:
--a.Tạo View cho phép chỉnh sửa city của khách hàng:
CREATE OR REPLACE VIEW v_customer_region AS
SELECT customer_id, full_name, region 
FROM customer 
WITH CHECK OPTION;

-- b. Thử cập nhật vùng miền (region) của 1 khách hàng qua View
UPDATE v_customer_region 
SET region = 'Danang' 
WHERE full_name = 'Nguyen Van A';

SELECT * FROM customer WHERE full_name = 'Nguyen Van A';