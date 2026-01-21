CREATE TABLE Product (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	category VARCHAR(50),
	price NUMERIC(10,2),
	stock INT

);
--1. thêm 5 products
INSERT INTO Product (name, category, price, stock) VALUES
('Laptop Dell XPS 13',    'Điện tử', 25000000, 5),
('Chuột Logitech M90',    'Phụ kiện', 150000,   30),
('Tai nghe Bluetooth',    'Điện tử', 800000,    20),
('Tivi Samsung 50 inch',  'Điện tử', 9000000,   10),
('Bàn phím cơ Razer',     'Phụ kiện', 2200000,  15);

--2. hiển thị toàn bộ sản phẩm
SELECT * FROM Product;

--3. hiển thị ba sản phẩm giá cao nhất
SELECT * FROM Product
ORDER BY price DESC
LIMIT 3;

--4.Sản phẩm “Điện tử” giá < 10,000,000
SELECT * FROM Product
WHERE category = 'Điện tử'
  AND price < 10000000;

--5. sắp xếp theo tồn kho tăng dần
SELECT * FROM Product
ORDER BY stock ASC;
