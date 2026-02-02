CREATE TABLE Orders (
	order_id SERIAL PRIMARY KEY,
	customer_id INTEGER NOT NULL,
	order_date DATE NOT NULL,
	total_amount DECIMAL(10,2) NOT NULL
	

);

CREATE INDEX idx_orders_customer_id ON Orders (customer_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM Orders WHERE customer_id = 12345;

