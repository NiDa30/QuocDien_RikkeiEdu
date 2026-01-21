CREATE TABLE Orders(
	id SERIAL PRIMARY KEY,
	customer_id INT,
	order_date DATE,
	total_amount NUMERIC(10,2)

);

INSERT INTO Orders (customer_id, order_date, total_amount) VALUES
(1, '2023-03-15', 2500000),  -- 2023
(1, '2023-07-22', 1800000),  -- 2023
(2, '2023-11-10', 3200000),  -- 2023
(3, '2024-01-05', 1500000),  -- 2024
(3, '2024-04-18', 2200000),  -- 2024
(4, '2024-06-12', 800000),   -- 2024
(2, '2024-09-25', 2800000),  -- 2024
(5, '2024-12-01', 45000000); -- 2024

--1.Tổng doanh thu, số đơn, giá trị trung bình (SUM, COUNT, AVG + ALIAS)
SELECT 
    SUM(total_amount) as total_revenue,
    COUNT(*) as total_orders,
    ROUND(AVG(total_amount), 0) as average_order_value
FROM Orders;

--2. Nhóm theo năm đặt hàng (GROUP BY EXTRACT YEAR)
SELECT 
    EXTRACT(YEAR FROM order_date) as order_year,
    COUNT(*) as orders_per_year,
    SUM(total_amount) as revenue_per_year,
    ROUND(AVG(total_amount), 0) as avg_order_per_year
FROM Orders 
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;

--3. Năm có doanh thu > 50 triệu (HAVING)
SELECT 
    EXTRACT(YEAR FROM order_date) as order_year,
    SUM(total_amount) as revenue_per_year
FROM Orders 
GROUP BY EXTRACT(YEAR FROM order_date)
HAVING SUM(total_amount) > 50000000
ORDER BY revenue_per_year DESC;

--4. 5 đơn hàng giá trị cao nhất (ORDER BY + LIMIT)
SELECT * FROM Orders 
ORDER BY total_amount DESC 
LIMIT 5;




