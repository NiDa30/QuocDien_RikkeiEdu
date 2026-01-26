DROP TABLE IF EXISTS inventory;

CREATE TABLE inventory (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    quantity INT
);

INSERT INTO inventory (product_name, quantity)
VALUES 
    ('iPhone 15', 10),       
    ('Samsung Galaxy S23', 5); 

-- 1. Viết một Procedure có tên check_stock(p_id INT, p_qty INT) để:
CREATE OR REPLACE PROCEDURE check_stock(
    p_id INT, 
    p_qty INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN
    SELECT quantity INTO v_stock
    FROM inventory
    WHERE product_id = p_id;

    IF v_stock IS NULL THEN
         RAISE EXCEPTION 'Sản phẩm có ID % không tồn tại', p_id;
    END IF;
    IF v_stock < p_qty THEN
        RAISE EXCEPTION 'Không đủ hàng trong kho';
    ELSE
        RAISE NOTICE 'Đủ hàng! Kho có %, Yêu cầu %', v_stock, p_qty;
    END IF;
END;
$$;

-- 2. Gọi Procedure với các trường hợp:
DO $$
BEGIN
    RAISE NOTICE 'Kiểm tra ID 1 với số lượng 5:';
    CALL check_stock(1, 5);
    
    RAISE NOTICE 'Kiểm tra ID 2 với số lượng 10:';
    CALL check_stock(2, 10);
END;
$$;