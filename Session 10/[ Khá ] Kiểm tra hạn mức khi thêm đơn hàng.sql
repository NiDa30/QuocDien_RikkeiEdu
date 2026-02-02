CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    credit_limit DECIMAL(12,2) NOT NULL DEFAULT 10000000
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id),
    order_amount DECIMAL(10,2) NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE
);

INSERT INTO customers (name, credit_limit) VALUES 
('Nguyen Van A', 5000000),
('Tran Thi B', 20000000);

-- tạo trigger function
CREATE OR REPLACE FUNCTION check_credit_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_total_orders DECIMAL(12,2) := 0;
    v_credit_limit DECIMAL(12,2);
    v_customer_name VARCHAR(255);
BEGIN
    SELECT c.credit_limit, COALESCE(SUM(o.order_amount), 0), c.name
    INTO v_credit_limit, v_total_orders, v_customer_name
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id
    WHERE c.id = NEW.customer_id
    GROUP BY c.id, c.credit_limit, c.name;
    
    IF (v_total_orders + NEW.order_amount) > v_credit_limit THEN
        RAISE EXCEPTION 'Customer % (ID: %) vượt hạn mức! Hạn mức: %, Tổng đơn: %, Đơn mới: %', 
            v_customer_name, NEW.customer_id, v_credit_limit, v_total_orders, NEW.order_amount;
    END IF;
    
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql;

-- tạo trigger BEFORE INSERT
CREATE TRIGGER trg_check_credit
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION check_credit_limit();

--test trigger
INSERT INTO orders (customer_id, order_amount) VALUES (1, 2000000);

INSERT INTO orders (customer_id, order_amount) VALUES (1, 4000000);

INSERT INTO orders (customer_id, order_amount) VALUES (2, 15000000);

-- kiểm tra kết quả
SELECT c.name, c.credit_limit, 
       COALESCE(SUM(o.order_amount), 0) as total_orders
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.credit_limit
ORDER BY c.id;
