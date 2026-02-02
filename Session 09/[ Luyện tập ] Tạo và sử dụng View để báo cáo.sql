CREATE TABLE Sales (
	sale_id SERIAL PRIMARY KEY,
	customer_id INTEGER NOT NULL,
	product_id INTEGER NOT NULL,
	sale_date DATE NOT NULL,
	amount DECIMAL(10,2) NOT NULL

);

--
CREATE VIEW CustomerSales AS
SELECT
	customer_id,
	COUNT(*) as total_orders,
	SUM(amount) as total_amount,
	AVG(amount) as avg_order_value,
	MIN(sale_date) as first_sale,
	MAX(sale_date) as last_sale
FROM Sales
GROUP BY customer_id;

--dùng view
SELECT * FROM CustomerSales
WHERE total_amount > 1000
ORDER BY total_amount DESC;

--thử cập nhật qua view
UPDATE CustomerSales
SET total_amount = 5000
WHERE customer_id = 123;