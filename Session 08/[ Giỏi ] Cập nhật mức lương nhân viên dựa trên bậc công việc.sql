DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100),
    job_level INT,
    salary NUMERIC
);

INSERT INTO employees (emp_name, job_level, salary)
VALUES 
    ('Alice', 1, 1000), 
    ('Bob', 2, 2000),  
    ('Charlie', 3, 3000), 
    ('David', 1, 1500); 

-- 2. Create Procedure
-- Viết Procedure adjust_salary(p_emp_id INT, OUT p_new_salary NUMERIC)
CREATE OR REPLACE PROCEDURE adjust_salary(
    IN p_emp_id INT,
    OUT p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_job_level INT;
    v_current_salary NUMERIC;
BEGIN
    -- a. Nhận emp_id (đã có từ tham số IN)
    SELECT job_level, salary INTO v_job_level, v_current_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    -- Kiểm tra nếu nhân viên không tồn tại
    IF v_current_salary IS NULL THEN
        RAISE EXCEPTION 'Nhân viên ID % không tồn tại', p_emp_id;
    END IF;

    -- b. Cập nhật lương theo quy tắc
    -- Level 1 -> tăng 5%
    -- Level 2 -> tăng 10%
    -- Level 3 -> tăng 15%
    IF v_job_level = 1 THEN
        p_new_salary := v_current_salary * 1.05;
    ELSEIF v_job_level = 2 THEN
        p_new_salary := v_current_salary * 1.10;
    ELSEIF v_job_level = 3 THEN
        p_new_salary := v_current_salary * 1.15;
    ELSE
        p_new_salary := v_current_salary; 
    END IF;
    UPDATE employees
    SET salary = p_new_salary
    WHERE emp_id = p_emp_id;
END;
$$;

-- 3. Gọi Procedure để kiểm tra hoạt động
DO $$
DECLARE
    v_new_salary NUMERIC;
BEGIN
    CALL adjust_salary(1, v_new_salary);
    RAISE NOTICE 'Lương mới của Alice (Level 1, cũ 1000): %', v_new_salary;

    CALL adjust_salary(2, v_new_salary);
    RAISE NOTICE 'Lương mới của Bob (Level 2, cũ 2000): %', v_new_salary;
    
    CALL adjust_salary(3, v_new_salary);
    RAISE NOTICE 'Lương mới của Charlie (Level 3, cũ 3000): %', v_new_salary;
END;
$$;