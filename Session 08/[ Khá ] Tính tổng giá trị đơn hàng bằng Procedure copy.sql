DROP TABLE IF EXISTS order_detail;

CREATE TABLE order_detail (
    id SERIAL PRIMARY KEY,
    order_id INT,
    product_name VARCHAR(100),
    quantity INT,
    unit_price NUMERIC
);

INSERT INTO order_detail (order_id, product_name, quantity, unit_price)
VALUES 
    (101, 'Laptop', 1, 1500.00),
    (101, 'Mouse', 2, 25.50),
    (102, 'Keyboard', 1, 45.00),
    (102, 'Monitor', 2, 150.00);

--1. Viết một Stored Procedure có tên calculate_order_total
--(order_id_input INT, OUT total NUMERIC)
CREATE OR REPLACE PROCEDURE calculate_order_total(
    IN order_id_input INT, 
    OUT total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT SUM(quantity * unit_price)
    INTO total
    FROM order_detail
    WHERE order_id = order_id_input;

    IF total IS NULL THEN
        total := 0;
    END IF;
END;
$$;

--3. Gọi Procedure để kiểm tra hoạt động với một order_id cụ thể
DO $$
DECLARE
    order_total NUMERIC;
BEGIN
    CALL calculate_order_total(101, order_total);
    RAISE NOTICE 'Tổng giá trị đơn hàng 101 là: %', order_total;

    CALL calculate_order_total(102, order_total);
    RAISE NOTICE 'Tổng giá trị đơn hàng 102 là: %', order_total;
END;
$$;