DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price NUMERIC,
    discount_percent INT
);

INSERT INTO products (name, price, discount_percent)
VALUES 
    ('Laptop', 1000.00, 20),   
    ('Smartphone', 800.00, 60),
    ('Tablet', 500.00, 50);    

-- 2. Create Procedure
-- Viết Procedure calculate_discount(p_id INT, OUT p_final_price NUMERIC)
CREATE OR REPLACE PROCEDURE calculate_discount(
    IN p_id INT,
    OUT p_final_price NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price NUMERIC;
    v_discount INT;
BEGIN
    -- a. Lấy price và discount_percent của sản phẩm
    SELECT price, discount_percent INTO v_price, v_discount
    FROM products
    WHERE id = p_id;

    IF v_price IS NULL THEN
        RAISE EXCEPTION 'Sản phẩm ID % không tồn tại', p_id;
    END IF;

    -- c. Nếu phần trăm giảm giá > 50, thì giới hạn chỉ còn 50%
    IF v_discount > 50 THEN
        v_discount := 50;
    END IF;

    -- b. Tính giá sau giảm: p_final_price = price - (price * discount_percent / 100)
    p_final_price := v_price - (v_price * v_discount / 100);

    -- 2. Cập nhật lại cột price trong bảng products thành giá sau giảm
    UPDATE products
    SET price = p_final_price
    WHERE id = p_id;
    
END;
$$;

-- 3. 
DO $$
DECLARE
    v_final_price NUMERIC;
BEGIN
    CALL calculate_discount(1, v_final_price);
    RAISE NOTICE 'Giá sau giảm của Laptop (20%%): %', v_final_price;

    CALL calculate_discount(2, v_final_price);
    RAISE NOTICE 'Giá sau giảm của Smartphone (60%% -> 50%%): %', v_final_price;
    
    CALL calculate_discount(3, v_final_price);
    RAISE NOTICE 'Giá sau giảm của Tablet (50%%): %', v_final_price;
END;
$$;
