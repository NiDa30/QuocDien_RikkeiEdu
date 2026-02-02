CREATE TABLE Products (
	product_id SERIAL PRIMARY KEY,
	category_id INTEGER NOT NULL,
	price DECIMAL(10,2) NOT NULL,
	stock_quantity INTEGER NOT NULL

);

CREATE INDEX idx_products_category_clustered ON Products (category_id);
CLUSTER Products USING idx_products_category_clustered;

CREATE INDEX idx_products_price ON Products (price);

--test 
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROME Products
WHERE category_id = 5
ORDER BY price;

--Giải thích: 
-- Clustered index: sắp xếp vật lý dữ liệu theo cột index
-- Non-clustered index: cấu trúc riêng biệt + con trỏ đến dữ liệu