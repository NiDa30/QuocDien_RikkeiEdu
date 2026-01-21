CREATE TABLE OrderInfo(
	id SERIAL PRIMARY KEY,
	customer_id INT,
	order_date DATE,
	total NUMERIC(10,2),
	status VARCHAR(20)

);

--1. thêm 5 đơn mẫu
INSERT INTO OrderInfo (customer_id, order_date, total, status) VALUES
(1, '2024-10-05',  1200000, 'Pending'),
(2, '2024-10-12',  800000,  'Shipped'),
(3, '2024-10-18',  350000,  'Completed'),
(1, '2024-10-25',  2500000, 'Pending'),
(4, '2024-11-03',  650000,  'Shipped');

--2. đơn có tổng tiền > 500 000
SELECT * FROM OrderInfo 
WHERE total > 500000;

--3. đơn tháng 10/2024
SELECT * FROM OrderInfo 
WHERE order_date BETWEEN '2024-10-01' AND '2024-10-31';


--4. trạng thái khác "Completed"
SELECT * FROM OrderInfo 
WHERE status != 'Completed';

--5. 2 đơn mới nhất
SELECT * FROM OrderInfo 
ORDER BY order_date DESC 
LIMIT 2;



