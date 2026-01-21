CREATE TABLE order_detail (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_name VARCHAR(100),
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) 
);

INSERT INTO order_detail (order_id, product_name, quantity, unit_price) VALUES
(1, 'Laptop Dell', 2, 15000.00),
(1, 'Mouse Logitech', 1, 500.00),
(2, 'Keyboard', 3, 800.00);

--1.
CREATE OR REPLACE PROCEDURE calculate_order_total(
    order_id_input INT,
    OUT total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(SUM(quantity * "unit_price"), 0) INTO total
    FROM order_detail
    WHERE "order_id" = order_id_input;
END;
$$;

--3.
CALL calculate_order_total(1, NULL);
