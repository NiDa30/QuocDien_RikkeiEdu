CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customers(customer_id),
    amount DECIMAL(10,2) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE
);

INSERT INTO Customers (name, email) VALUES 
('Nguyen Van A', 'a@example.com'),
('Tran Thi B', 'b@example.com');

CREATE OR REPLACE PROCEDURE add_order(
    p_customer_id INT,
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_exists INT;
BEGIN
 
    SELECT COUNT(*) INTO v_customer_exists
    FROM Customers 
    WHERE customer_id = p_customer_id;
    
    IF v_customer_exists = 0 THEN
        RAISE EXCEPTION 'Customer ID % không tồn tại trong hệ thống', p_customer_id;
    END IF;
    
    INSERT INTO Orders (customer_id, amount, order_date)
    VALUES (p_customer_id, p_amount, CURRENT_DATE);
    
    RAISE NOTICE 'Đã thêm đơn hàng cho customer % với số tiền %', p_customer_id, p_amount;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Lỗi khi thêm đơn hàng: %', SQLERRM;
    
END;
$$;

CALL add_order(1, 1500000);  -- Customer tồn tại

CALL add_order(999, 2000000);  -- Customer KHÔNG tồn tại

SELECT * FROM Orders ORDER BY order_date DESC;
