CREATE TABLE OldCustomers(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	city VARCHAR(50)

);

CREATE TABLE NewCustomers(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	city VARCHAR(50)

);

-- OldCustomers (khách cũ)
INSERT INTO OldCustomers (name, city) VALUES
('Nguyễn Văn An', 'Hà Nội'),
('Trần Thị Bình', 'TP.HCM'),
('Lê Văn Cường', 'Đà Nẵng'),
('Phạm Thị Dung', 'Hà Nội'),
('Hoàng Văn Em', 'Hải Phòng');

-- NewCustomers (khách mới)
INSERT INTO NewCustomers (name, city) VALUES
('Nguyễn Văn An', 'Hà Nội'),    
('Vũ Thị Phương', 'TP.HCM'),
('Đặng Văn Giang', 'Cần Thơ'),
('Trần Thị Bình', 'TP.HCM'),    
('Nguyễn Thị Lan', 'Hà Nội');

--1. Lấy danh sách tất cả khách hàng (cũ + mới) không trùng lặp (UNION)
SELECT name, city FROM OldCustomers
UNION
SELECT name, city FROM NewCustomers
ORDER BY name;

--2. Tìm khách hàng vừa thuộc bảng OldCustomers 
--vừa thuộc bảng NewCustomers (INTERSECT)
SELECT name, city FROM OldCustomers
INTERSECT
SELECT name, city FROM NewCustomers
ORDER BY name;

--3. Tính số lượng khách hàng ở từng thành phố (dùng GROUP BY city)
SELECT 
    city,
    COUNT(*) as customer_count
FROM (
    SELECT name, city FROM OldCustomers
    UNION ALL  -- ALL để đếm cả trùng
    SELECT name, city FROM NewCustomers
) all_customers
GROUP BY city
ORDER BY customer_count DESC;

--4. Tìm thành phố có nhiều khách hàng nhất (dùng Subquery và MAX)
SELECT city, customer_count
FROM (
    SELECT city, COUNT(*) as customer_count
    FROM (
        SELECT name, city FROM OldCustomers
        UNION ALL
        SELECT name, city FROM NewCustomers
    ) combined
    GROUP BY city
) city_stats
WHERE customer_count = (
    SELECT MAX(customer_count) 
    FROM (
        SELECT COUNT(*) as customer_count
        FROM (
            SELECT name, city FROM OldCustomers
            UNION ALL
            SELECT name, city FROM NewCustomers
        ) t
        GROUP BY city
    ) max_count
);
