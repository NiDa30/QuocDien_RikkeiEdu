CREATE TABLE customer (
	customer_id SERIAL PRIMARY KEY,
	full_name VARCHAR(100),
	email VARCHAR(100),
	phone VARCHAR(15)
);

CREATE TABLE "order"(
	order_id SERIAL PRIMARY KEY,
	customer_id INT REFERENCES customer(customer_id),
	total_amount DECIMAL(10,2),
	order_date DATE

);

INSERT INTO customer (full_name, email, phone) VALUES 
('Nguyen Van A', 'a@mail.com', '0901234567'),
('Tran Thi B', 'b@mail.com', '0909876543');

INSERT INTO "order" (customer_id, total_amount, order_date) VALUES 
(1, 150.00, '2025-01-10'),
(1, 200.00, '2025-01-15'),
(2, 300.50, '2025-02-01');

--1. Tạo một View tên v_order_summary hiển thị:
--full_name, total_amount, order_date
--(ẩn thông tin email và phone)
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    c.full_name, 
    o.total_amount, 
    o.order_date
FROM "order" o
JOIN customer c ON o.customer_id = c.customer_id;

--2.Viết truy vấn để xem tất cả dữ liệu từ View
-- Bước 1: Tạo hàm xử lý cập nhật
SELECT * FROM v_order_summary;

--3.Cập nhật tổng tiền đơn hàng thông qua View (gợi ý: dùng WITH CHECK OPTION nếu cần)
CREATE OR REPLACE FUNCTION update_order_via_view()
RETURNS TRIGGER AS $$
BEGIN
    -- Cập nhật bảng gốc "order" dựa trên tên khách hàng và ngày cũ
    UPDATE "order"
    SET total_amount = NEW.total_amount
    FROM customer c
    WHERE "order".customer_id = c.customer_id
      AND c.full_name = OLD.full_name
      AND "order".order_date = OLD.order_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Gắn Trigger vào View
CREATE TRIGGER trg_update_order_summary
INSTEAD OF UPDATE ON v_order_summary
FOR EACH ROW
EXECUTE FUNCTION update_order_via_view();

--cập nhật
UPDATE v_order_summary 
SET total_amount = 500.00 
WHERE full_name = 'Nguyen Van A' AND order_date = '2025-01-10';


--4.Tạo một View thứ hai v_monthly_sales thống kê tổng doanh thu mỗi tháng
CREATE VIEW v_monthly_sales AS
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month, -- Gom nhóm theo tháng-năm
    SUM(total_amount) AS total_revenue
FROM "order"
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;


--5.Thử DROP View và ghi chú sự khác biệt giữa DROP VIEW 
--và DROP MATERIALIZED VIEW trong PostgreSQL
--DROP VIEW, chỉ xóa phần định nghĩa và không ảnh hưởng đến dữ liểu thật.
--DROP MATERIALIZED, xóa định nghĩa và dữ liệu vật lý được lưu trữ

