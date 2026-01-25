-- Dùng DROP để xóa hoàn toàn bảng cũ (cấu trúc + dữ liệu)
DROP TABLE IF EXISTS order_detail CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS customer CASCADE;

-- 1. Tạo bảng Customer
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    region VARCHAR(50)
);

-- 2. Tạo bảng Orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    total_amount DECIMAL(10,2),
    order_date DATE,
    status VARCHAR(20)
);

-- 3. Tạo bảng Product (đã bổ sung kiểu dữ liệu thiếu trong đề bài)
CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    category VARCHAR(50)
);

-- 4. Tạo bảng Order_Detail
CREATE TABLE order_detail (
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES product(product_id),
    quantity INT, -- Sửa 'quanlity' thành 'quantity' cho chuẩn tiếng Anh
    PRIMARY KEY (order_id, product_id)
);

-- 5. Chèn dữ liệu mẫu
INSERT INTO customer (full_name, region) VALUES
('Nguyen Van A', 'North'),
('Tran Thi B', 'South'),
('Le Van C', 'Central'),
('Pham Thi D', 'North'),
('Hoang Van E', 'South');

INSERT INTO product (name, price, category) VALUES
('Laptop Dell', 1500.00, 'Electronics'),
('Mouse Logitech', 20.00, 'Accessories'),
('Keyboard Keychron', 80.00, 'Accessories');

INSERT INTO orders (customer_id, total_amount, order_date, status) VALUES
(1, 1500.00, '2024-01-15', 'Completed'),
(2, 2000.00, '2024-02-20', 'Pending'),
(3, 500.00, '2024-01-10', 'Shipped'),
(4, 300.00, '2024-03-05', 'Pending'),
(5, 1200.00, '2024-02-25', 'Completed'),
(1, 100.00, '2024-03-01', 'Pending');

INSERT INTO order_detail (order_id, product_id, quantity) VALUES
(1, 1, 1),
(2, 1, 1), (2, 3, 5); -- Đơn hàng 2 mua nhiều món



--1.Tạo View tổng hợp doanh thu theo khu vực:
CREATE VIEW v_revenue_by_region AS
SELECT c.region, SUM(o.total_amount) AS total_revenue
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

--Viết truy vấn xem top 3 khu vực có doanh thu cao nhất
SELECT * 
FROM v_revenue_by_region
ORDER BY total_revenue DESC
LIMIT 3;


--2.Tạo View chi tiết đơn hàng có thể cập nhật được:
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_sales;

CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(total_amount) AS monthly_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

--a.Cập nhật status của đơn hàng thông qua View này
-- Cập nhật một đơn hàng trong bảng gốc
UPDATE orders 
SET total_amount = total_amount + 500 
WHERE order_id = 1;

-- Cập nhật status (Ví dụ)
UPDATE orders 
SET status = 'Completed' 
WHERE order_id = 2;

-- Lệnh quan trọng: Làm mới dữ liệu cho Materialized View để phản ánh thay đổi
REFRESH MATERIALIZED VIEW mv_monthly_sales;

-- Kiểm tra lại xem số liệu đã thay đổi chưa
SELECT * FROM mv_monthly_sales;


--b.Kiểm tra hành vi khi vi phạm điều kiện WITH CHECK OPTION
CREATE OR REPLACE VIEW v_pending_orders AS
SELECT order_id, status, total_amount
FROM orders
WHERE status = 'Pending'
WITH CHECK OPTION;

-- Thử nghiệm 1: Cập nhật HỢP LỆ (Vẫn giữ status là 'Pending')
-- Kết quả: Thành công
UPDATE v_pending_orders
SET total_amount = 2500.00
WHERE order_id = 4; -- Giả sử ID 4 đang là Pending

-- Thử nghiệm 2: Cập nhật KHÔNG HỢP LỆ (Đổi status sang trạng thái khác)
-- Kết quả: Sẽ báo lỗi "new row violates check option for view"
-- Lý do: Dòng này sẽ biến mất khỏi View v_pending_orders sau khi update
UPDATE v_pending_orders
SET status = 'Shipped'
WHERE order_id = 4;


--3.Tạo View phức hợp (Nested View):
--Từ v_revenue_by_region, tạo View mới v_revenue_above_avg 
--chỉ hiển thị khu vực có doanh thu > trung bình toàn quốc
CREATE OR REPLACE VIEW v_revenue_above_avg AS
SELECT 
    region, 
    total_revenue
FROM v_revenue_by_region
WHERE total_revenue > (
    SELECT AVG(total_revenue) FROM v_revenue_by_region
);

SELECT * FROM v_revenue_above_avg;
