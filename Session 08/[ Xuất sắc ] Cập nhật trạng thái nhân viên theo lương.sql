DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary NUMERIC(10, 2),
    bonus NUMERIC(10, 2) DEFAULT 0,
    status VARCHAR(20) 
);

-- Insert sample data
INSERT INTO employees (name, department, salary) VALUES 
    ('Nguyen Van A', 'HR', 4000),      
    ('Tran Thi B', 'IT', 6000),       
    ('Le Van C', 'Finance', 10500),   
    ('Pham Thi D', 'IT', 8000),       
    ('Do Van E', 'HR', 12000);        

-- 2. Create Procedure
-- Tạo procedure update_employee_status với yêu cầu sau:
CREATE OR REPLACE PROCEDURE update_employee_status(
    IN p_emp_id INT,
    OUT p_status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
BEGIN
    -- a. Kiểm tra nhân viên tồn tại và lấy lương
    SELECT salary INTO v_salary
    FROM employees
    WHERE id = p_emp_id;

    IF v_salary IS NULL THEN
        RAISE EXCEPTION 'Employee not found';
    END IF;

    -- b. Cập nhật status dựa trên lương
    IF v_salary < 5000 THEN
        p_status := 'Junior';
    ELSEIF v_salary >= 5000 AND v_salary <= 10000 THEN
        p_status := 'Mid-level';
    ELSE 
        p_status := 'Senior';
    END IF;

    -- c. Update status vào bảng employees
    UPDATE employees
    SET status = p_status
    WHERE id = p_emp_id;
    
    -- d. Trả ra p_status sau khi cập nhật (đã gán ở trên)
END;
$$;

DO $$
DECLARE
    v_status TEXT;
BEGIN
    CALL update_employee_status(1, v_status);
    RAISE NOTICE 'Trạng thái nhân viên 1: %', v_status;

    CALL update_employee_status(2, v_status);
    RAISE NOTICE 'Trạng thái nhân viên 2: %', v_status;
    
    CALL update_employee_status(3, v_status);
    RAISE NOTICE 'Trạng thái nhân viên 3: %', v_status;
    
    -- Case 4: Test Employee not found (Uncomment to test exception)
    -- CALL update_employee_status(999, v_status);
END;
$$;
