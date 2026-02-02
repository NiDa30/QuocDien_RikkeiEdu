CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    salary DECIMAL(10,2) NOT NULL
);

CREATE TABLE employees_log (
    log_id SERIAL PRIMARY KEY,
    employee_id INT,
    operation VARCHAR(10) NOT NULL,  
    old_data JSONB,
    new_data JSONB,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tạo Audit trigger function
CREATE OR REPLACE FUNCTION audit_employees_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employees_log (employee_id, operation, new_data)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW));
        
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employees_log (employee_id, operation, old_data, new_data)
        VALUES (OLD.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employees_log (employee_id, operation, old_data)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD));
    END IF;
    
    RETURN NULL;  
END;
$$ LANGUAGE plpgsql;

-- tạo trigger cho 3 sự kiện
CREATE TRIGGER trg_audit_employees
    AFTER INSERT OR UPDATE OR DELETE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION audit_employees_changes();

-- test trigger
-- 1. INSERT mới
INSERT INTO employees (name, position, salary) 
VALUES ('Nguyen Van A', 'Developer', 15000000);

-- 2. UPDATE lương
UPDATE employees 
SET salary = 18000000 
WHERE name = 'Nguyen Van A';

-- 3. DELETE
DELETE FROM employees WHERE name = 'Nguyen Van A';

INSERT INTO employees (name, position, salary) 
VALUES ('Tran Thi B', 'Manager', 25000000);

-- kiểm tra 
SELECT log_id, employee_id, operation, change_time,
       old_data, new_data
FROM employees_log 
ORDER BY change_time DESC;
