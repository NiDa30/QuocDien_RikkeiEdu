DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary NUMERIC(10, 2),
    bonus NUMERIC(10, 2) DEFAULT 0,
    status VARCHAR(20) 
);

INSERT INTO employees (name, department, salary) VALUES 
    ('Nguyen Van A', 'HR', 4000),      
    ('Tran Thi B', 'IT', 6000),       
    ('Le Van C', 'Finance', 10500),   
    ('Pham Thi D', 'IT', 8000),       
    ('Do Van E', 'HR', 12000);        

-- 2. Create Procedure
-- Tạo procedure calculate_bonus
CREATE OR REPLACE PROCEDURE calculate_bonus(
    IN p_emp_id INT,
    IN p_percent NUMERIC,
    OUT p_bonus NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
BEGIN
    -- Kiểm tra nhân viên tồn tại
    SELECT salary INTO v_salary
    FROM employees
    WHERE id = p_emp_id;

    -- Nếu nhân viên không tồn tại -> ném lỗi "Employee not found"
    IF v_salary IS NULL THEN
        RAISE EXCEPTION 'Employee not found';
    END IF;

    -- Nếu p_percent <= 0 -> không tính, p_bonus = 0
    IF p_percent <= 0 THEN
        p_bonus := 0;
    ELSE
        -- Tính thưởng = salary * p_percent / 100
        p_bonus := v_salary * p_percent / 100;
        
        -- Lưu vào cột bonus trong bảng employees
        UPDATE employees
        SET bonus = p_bonus
        WHERE id = p_emp_id;
    END IF;
END;
$$;

-- 3. Gọi thử
DO $$
DECLARE
    v_bonus NUMERIC;
BEGIN
    CALL calculate_bonus(1, 10, v_bonus);
    RAISE NOTICE 'Bonus nhân viên 1 (10%%): %', v_bonus;

    CALL calculate_bonus(2, -5, v_bonus);
    RAISE NOTICE 'Bonus nhân viên 2 (-5%%): %', v_bonus;
    
    CALL calculate_bonus(3, 20, v_bonus);
    RAISE NOTICE 'Bonus nhân viên 3 (20%%): %', v_bonus;

    -- Case 4: Test Employee Not Found (Uncomment to test)
    -- CALL calculate_bonus(999, 10, v_bonus);
END;
$$;
