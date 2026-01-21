DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id SERIAL PRIMARY KEY,  
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price NUMERIC(10,2),
    stock INTEGER,
    manufacturer VARCHAR(50)
);

INSERT INTO products (id, name, category, price, stock, manufacturer) VALUES
(2, 'Chuột Logitech M90', 'Phụ kiện', 150000, 50, 'Logitech'),
(3, 'Bàn phím cơ Razer', 'Phụ kiện', 2200000, 0, 'Razer'),
(4, 'Macbook Air M2', 'Laptop', 32000000, 7, 'Apple'),
(5, 'iPhone 14 Pro Max', 'Điện thoại', 35000000, 15, 'Apple'),
(6, 'Laptop Dell XPS 13', 'Laptop', 25000000, 12, 'Dell'),
(7, 'Tai nghe AirPods 3', 'Phụ kiện', 4500000, NULL, 'Apple');

--1. chèn dữ liệu mới
INSERT INTO products (name, category, price, stock, manufacturer)
VALUES ('Chuột không dây Logitech M170', 'Phụ kiện', 300000, 20, 'Logitech');

--2. cập nhật dữ liệu
UPDATE products 
SET price = price * 1.10 
WHERE manufacturer = 'Apple';

--3. xóa dữ liệu
DELETE FROM products 
WHERE stock = 0;

--4. lọc theo điều kiện
SELECT * FROM products 
WHERE price BETWEEN 1000000 AND 30000000;

--5. lọc giá trị NULL
SELECT * FROM products 
WHERE stock IS NULL;

--6. loại bỏ trùng
SELECT DISTINCT manufacturer 
FROM products 
ORDER BY manufacturer;

--7. sắp xếp dữ liệu
SELECT * FROM products 
ORDER BY price DESC, name ASC;

--8. Tìm kím like  và ILike
--ILike
SELECT * FROM products 
WHERE name ILIKE '%laptop%';
--like
SELECT * FROM products 
WHERE name LIKE '%Laptop%';


--9. giới hạn kết quả
SELECT * FROM products 
ORDER BY price DESC 
LIMIT 2;
