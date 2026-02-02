CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    total_spent DECIMAL(12,2) DEFAULT 0
);

CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customers(customer_id),
    total_amount DECIMAL(10,2) NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE
);

INSERT INTO Customers (name) VALUES 
('Nguyen Van A'), 
('Tran Thi B');

--
CREATE OR REPLACE PROCEDURE add_order_and_update_customer(
    p_customer_id INT,
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_name VARCHAR(255);
    v_new_total_spent DECIMAL(12,2);
    v_customer_exists BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS(SELECT 1 FROM Customers c WHERE c.customer_id = p_customer_id), 
           c.name 
    INTO v_customer_exists, v_customer_name
    FROM Customers c 
    WHERE c.customer_id = p_customer_id;
    
    IF NOT v_customer_exists THEN
        RAISE EXCEPTION 'Customer ID % không tồn tại trong hệ thống', p_customer_id;
    END IF;
    
    -- Thêm đơn hàng mới
    INSERT INTO Orders (customer_id, total_amount)
    VALUES (p_customer_id, p_amount);
    
    -- Cập nhật total_spent
    UPDATE Customers 
    SET total_spent = total_spent + p_amount
    WHERE customer_id = p_customer_id
    RETURNING total_spent INTO v_new_total_spent;
    
    RAISE NOTICE '✅ Đã thêm đơn %. Customer % (%) | Tổng chi: %', 
        p_amount, p_customer_id, v_customer_name, v_new_total_spent;
        
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ Lỗi thêm đơn hàng: %. Transaction đã ROLLBACK', SQLERRM;
END;
$$;

--Thành công
CALL add_order_and_update_customer(1, 1500000);
CALL add_order_and_update_customer(2, 2300000);

-- Lỗi customer không tồn tại
CALL add_order_and_update_customer(999, 500000);

-- Orders
SELECT * FROM Orders ORDER BY order_date DESC LIMIT 3;

-- Customers (total_spent đã cập nhật)
SELECT c.customer_id, c.name, c.total_spent FROM Customers c;
