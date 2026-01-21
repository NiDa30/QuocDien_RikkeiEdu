-- Xóa bảng cũ
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Customer;

-- Tạo bảng
CREATE TABLE Customer(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50)
);

CREATE TABLE Orders(
	id SERIAL PRIMARY KEY,
	customer_id INT,
	total_amount NUMERIC(10,2),
	FOREIGN KEY (customer_id) REFERENCES Customer(id)
);

-- Dữ liệu Customer (7 khách)
INSERT INTO Customer (name) VALUES
('Nguyễn Văn An'), ('Trần Thị Bình'), ('Lê Văn Cường'), 
('Phạm Thị Dung'), ('Hoàng Văn Em'), ('Vũ Thị Phương'), ('Nguyễn Văn Giang');

-- Dữ liệu Orders (khách 1,2,3,5 có đơn, 4,6,7 chưa mua)
INSERT INTO Orders (customer_id, total_amount) VALUES
(1, 2500000), (1, 1800000), (1, 1200000),  -- An: 55tr
(2, 3200000), (2, 1500000),                -- Bình: 47tr
(3, 2200000),                              -- Cường: 22tr
(5, 800000),                               -- Em: 0.8tr
(1, 500000);                               -- An thêm: tổng 60.5tr


--1. Hiển thị tên khách hàng và tổng tiền đã mua, 
--sắp xếp theo tổng tiền giảm dần
SELECT 
    c.name,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_spent
FROM Customer c
LEFT JOIN Orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY total_spent DESC NULLS LAST;

--2. Tìm khách hàng có tổng chi tiêu cao nhất (dùng Subquery với MAX)
SELECT c.name, SUM(o.total_amount) as max_spent
FROM Customer c
JOIN Orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
HAVING SUM(o.total_amount) = (
    SELECT MAX(total_spent) 
    FROM (
        SELECT SUM(total_amount) as total_spent 
        FROM Orders 
        GROUP BY customer_id
    ) t
);

--3. Liệt kê khách hàng chưa từng mua hàng (LEFT JOIN + IS NULL)
SELECT c.name as no_orders_customer
FROM Customer c
LEFT JOIN Orders o ON c.id = o.customer_id
WHERE o.customer_id IS NULL;

--4. Hiển thị khách hàng có tổng chi tiêu > trung bình của toàn bộ khách hàng 
--(dùng Subquery trong HAVING)
SELECT 
    c.name,
    SUM(o.total_amount) as total_spent
FROM Customer c
LEFT JOIN Orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
HAVING SUM(o.total_amount) > (
    SELECT AVG(total_spent) 
    FROM (
        SELECT SUM(total_amount) as total_spent 
        FROM Orders GROUP BY customer_id
    ) avg_table
)
ORDER BY total_spent DESC;

SELECT * FROM Customer ORDER BY id;
SELECT * FROM Orders ORDER BY id;
