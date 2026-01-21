CREATE TABLE Product(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	category VARCHAR(50),
	price NUMERIC(10,2)

);

CREATE TABLE OrderDetail(
	id SERIAL PRIMARY KEY,
	order_id INT, 
	product_id INT,
	quantity INT

);

-- Sản phẩm (7 sp, 3 category)
INSERT INTO Product (name, category, price) VALUES
('Laptop Dell XPS', 'Laptop', 25000000),
('iPhone 15 Pro',   'Điện thoại', 30000000),
('Tai nghe Sony',   'Phụ kiện', 2500000),
('MacBook Air M3',  'Laptop', 35000000),
('Samsung Galaxy S24','Điện thoại', 22000000),
('Chuột Logitech',  'Phụ kiện', 300000),
('Bàn phím cơ',     'Phụ kiện', 2000000);

-- OrderDetail
INSERT INTO OrderDetail (order_id, product_id, quantity) VALUES
(1, 1, 2), 
(1, 3, 5), 
(2, 2, 1), 
(3, 4, 1),  
(4, 5, 3),  
(5, 6, 10); 

--1.Tính tổng doanh thu từng sản phẩm, hiển thị product_name, 
--total_sales (SUM(price * quantity))
SELECT 
    p.name as product_name,
    SUM(p.price * od.quantity) as total_sales,
    SUM(od.quantity) as total_quantity
FROM Product p
LEFT JOIN OrderDetail od ON p.id = od.product_id
GROUP BY p.id, p.name
ORDER BY total_sales DESC NULLS LAST;

--2. Tính doanh thu trung bình theo từng loại sản phẩm (GROUP BY category)
SELECT 
    p.category,
    COUNT(DISTINCT p.id) as product_count,
    ROUND(AVG(p.price * COALESCE(od.quantity, 0)), 0) as avg_sales_per_product
FROM Product p
LEFT JOIN OrderDetail od ON p.id = od.product_id
GROUP BY p.category
ORDER BY avg_sales_per_product DESC;

--3. Chỉ hiển thị các loại sản phẩm có doanh thu trung bình > 20 triệu (HAVING)
SELECT 
    p.category,
    ROUND(SUM(p.price * od.quantity), 0) as total_category_sales
FROM Product p
INNER JOIN OrderDetail od ON p.id = od.product_id
GROUP BY p.category
HAVING SUM(p.price * od.quantity) > 20000000
ORDER BY total_category_sales DESC;

--4. Hiển thị tên sản phẩm có doanh thu cao hơn doanh thu trung bình 
--toàn bộ sản phẩm (dùng Subquery)
SELECT 
    p.name,
    SUM(p.price * od.quantity) as product_sales
FROM Product p
JOIN OrderDetail od ON p.id = od.product_id
GROUP BY p.id, p.name
HAVING SUM(p.price * od.quantity) > (
    SELECT AVG(product_total) 
    FROM (
        SELECT SUM(p2.price * od2.quantity) as product_total
        FROM Product p2
        JOIN OrderDetail od2 ON p2.id = od2.product_id
        GROUP BY p2.id
    ) avg_sales
)
ORDER BY product_sales DESC;

--5. Liệt kê toàn bộ sản phẩm và số lượng bán được (nếu có) 
--kể cả sản phẩm chưa có đơn hàng (LEFT JOIN)
SELECT 
    p.name,
    p.category,
    COALESCE(SUM(od.quantity), 0) as total_sold,
    COALESCE(SUM(p.price * od.quantity), 0) as total_revenue
FROM Product p
LEFT JOIN OrderDetail od ON p.id = od.product_id
GROUP BY p.id, p.name, p.category
ORDER BY total_revenue DESC NULLS LAST;

SELECT * FROM Product ORDER BY id;
SELECT * FROM OrderDetail ORDER BY id;
