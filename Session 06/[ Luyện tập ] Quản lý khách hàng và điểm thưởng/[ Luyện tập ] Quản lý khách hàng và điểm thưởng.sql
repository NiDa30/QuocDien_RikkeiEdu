CREATE TABLE Customer(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	email VARCHAR(100),
	phone VARCHAR(20),
	points INT

);

--1. thêm 7 khách hàng, có 1 người NULL email
INSERT INTO Customer (name, email, phone, points) VALUES
('Nguyễn Văn An',     'an@gmail.com',    '0901234567', 150),
('Trần Thị Bình',    'binh@outlook.com', '0912345678', 200),
('Lê Văn Cường',     'cuong@yahoo.com',  '0923456789', 180),
('Phạm Thị Dung',    NULL,               '0934567890', 120),
('Hoàng Văn Em',     'em@fpt.com',       '0945678901', 250),
('Vũ Thị Phương',    'phuong@vnn.vn',    '0956789012', 220),
('Nguyễn Văn An',    'an2@gmail.com',    '0967890123', 160);

--2. tên khách hàng duy nhất
SELECT DISTINCT name 
FROM Customer 
ORDER BY name;

--3. khách chưa có email
SELECT * FROM Customer 
WHERE email IS NULL;


--4. 3 khách hàng cao điểm thứ 2-4 (OFFSET 1, LIMIT 3)
SELECT * FROM Customer 
ORDER BY points DESC 
LIMIT 3 OFFSET 1;


--5. sắp xếp tên giảm dần
SELECT * FROM Customer 
ORDER BY name DESC;


