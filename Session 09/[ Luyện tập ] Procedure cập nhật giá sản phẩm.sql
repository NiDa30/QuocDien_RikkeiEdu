CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER NOT NULL
);

INSERT INTO Products (name, price, category_id) VALUES
('Laptop Dell', 25000000, 1),
('iPhone 16', 30000000, 1),
('Samsung TV', 15000000, 2),
('iPad Pro', 22000000, 1);


CREATE OR REPLACE PROCEDURE update_product_price(
    p_category_id INT,
    p_increase_percent NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_price DECIMAL(10,2);
    v_new_price DECIMAL(10,2);
    v_product_count INT := 0;
BEGIN
    v_product_count := 0;
    
    FOR rec IN SELECT product_id, price FROM Products WHERE category_id = p_category_id LOOP
	
        v_current_price := rec.price;
        v_new_price := v_current_price * (1 + p_increase_percent / 100);
        
        UPDATE Products 
        SET price = v_new_price 
        WHERE product_id = rec.product_id;
        
        v_product_count := v_product_count + 1;
        
        RAISE NOTICE 'Cập nhật %: % → % (tăng %%)', 
            rec.product_id, v_current_price, v_new_price, p_increase_percent;
    END LOOP;
    
    RAISE NOTICE 'Đã cập nhật % sản phẩm category % tăng %%.', 
        v_product_count, p_category_id, p_increase_percent;
END;
$$;


-- Tăng 10% giá category 1 (Laptop, iPhone, iPad)
CALL update_product_price(1, 10.0);

-- Tăng 5% giá category 2 (TV)
CALL update_product_price(2, 5.0);

SELECT * FROM Products ORDER BY category_id, price;
