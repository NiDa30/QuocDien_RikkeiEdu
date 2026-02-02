CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT
);

CREATE TABLE customers_log (
    log_id SERIAL PRIMARY KEY,
    customer_id INT,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_log_customer_time ON customers_log (customer_id, change_time DESC);
CREATE INDEX idx_customers_log_time ON customers_log (change_time DESC);

-- tạo Audit trigger function
CREATE OR REPLACE FUNCTION audit_customers_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO customers_log (customer_id, operation, new_data)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW));
        
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO customers_log (customer_id, operation, old_data, new_data)
        VALUES (OLD.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        
    
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO customers_log (customer_id, operation, old_data)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD));
    END IF;
    
    RETURN NULL;  
END;
$$ LANGUAGE plpgsql;

-- tạo trigger
CREATE TRIGGER trg_audit_customers
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION audit_customers_changes();

-- test
-- 1. INSERT khách hàng mới
INSERT INTO customers (name, email, phone, address) 
VALUES ('Nguyen Van A', 'a@example.com', '0123456789', 'HN');

-- 2. UPDATE thông tin
UPDATE customers 
SET phone = '0987654321', address = 'HCM' 
WHERE email = 'a@example.com';

-- 3. DELETE
DELETE FROM customers WHERE email = 'a@example.com';

-- 4. INSERT lại để test tiếp
INSERT INTO customers (name, email, phone) 
VALUES ('Tran Thi B', 'b@example.com', '0111222333');

-- kiểm tra Audit log
-- Xem toàn bộ lịch sử thay đổi
SELECT log_id, customer_id, operation, changed_by, change_time,
       old_data, new_data
FROM customers_log 
ORDER BY change_time DESC;

SELECT operation, change_time, changed_by,
       old_data->>'phone' as old_phone,
       new_data->>'phone' as new_phone
FROM customers_log 
WHERE customer_id = 1
ORDER BY change_time;
