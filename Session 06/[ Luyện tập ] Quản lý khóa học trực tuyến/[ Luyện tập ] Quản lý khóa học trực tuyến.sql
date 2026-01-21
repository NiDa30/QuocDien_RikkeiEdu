CREATE TABLE Course(
	id SERIAL PRIMARY KEY,
	title VARCHAR(100),
	instructor VARCHAR(50),
	price NUMERIC(10,2), 
	duration INT

);

--1. thêm 10 khóa học
INSERT INTO Course (title, instructor, price, duration) VALUES
('SQL Database Fundamentals', 'John Doe',     1200000, 25),
('Advanced Python Programming','Jane Smith',  1800000, 40),
('JavaScript Essentials',     'Mike Johnson', 800000,  20),
('SQL Advanced Queries',      'Anna Lee',     1500000, 35),
('React Native Mobile Dev',   'Tom Wilson',   2200000, 45),
('Demo Course Testing',       'Test User',    500000,  15),
('SQL Optimization Techniques','David Brown', 900000,  30);


--2. Cập nhật giá +15% cho khóa >30 giờ
UPDATE Course 
SET price = price * 1.15 
WHERE duration > 30;


--3. Xóa khóa học chứa "Demo"
DELETE FROM Course 
WHERE title ILIKE '%Demo%';


--4. Khóa học chứa "SQL" (không phân biệt hoa/thường)
SELECT * FROM Course 
WHERE title ILIKE '%SQL%';

--5. 3 khóa giá 500k-2M, sắp xếp giảm giá
SELECT * FROM Course 
WHERE price BETWEEN 500000 AND 2000000
ORDER BY price DESC
LIMIT 3;



