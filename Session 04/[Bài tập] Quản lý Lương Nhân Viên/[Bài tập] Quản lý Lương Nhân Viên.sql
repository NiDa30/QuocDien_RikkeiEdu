-- Tạo bảng employees
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    position VARCHAR(50),
    salary NUMERIC(10,2),
    bonus NUMERIC(10,2),
    join_year INTEGER
);

-- Chèn dữ liệu mẫu (7 dòng)
INSERT INTO employees (id, full_name, department, position, salary, bonus, join_year) VALUES
(1, 'Nguyễn Văn Huy', 'IT', 'Developer', 18000000, 1000000, 2021),
(2, 'Trần Thị Mai', 'HR', 'Recruiter', 12000000, NULL, 2020),
(3, 'Lê Quốc Trung', 'IT', 'Tester', 15000000, 800000, 2023),
(4, 'Nguyễn Văn Huy', 'IT', 'Developer', 18000000, 1000000, 2021),
(5, 'Phạm Ngọc Hân', 'Finance', 'Accountant', 14000000, NULL, 2019),
(6, 'Bùi Thị Lan', 'HR', 'HR Manager', 20000000, 3000000, 2018),
(7, 'Đặng Hữu Tài', 'IT', 'Developer', 17000000, NULL, 2022);

--1. chuẩn hóa dữ liệu
DELETE FROM employees 
WHERE id IN (
    SELECT id FROM (
        SELECT id, 
               ROW_NUMBER() OVER (
                   PARTITION BY full_name, department, position 
                   ORDER BY id
               ) as row_num
        FROM employees
    ) t 
    WHERE row_num > 1
);

--2. cập nhật lương thưởng
--a. Tăng 10% lương IT có salary < 18tr
UPDATE employees 
SET salary = salary * 1.10 
WHERE department = 'IT' AND salary < 18000000;
--b. Đặt bonus=500000 cho NULL
UPDATE employees 
SET bonus = 500000 
WHERE bonus IS NULL;

--3. truy vấn
--a. IT/HR, join >2020, tổng thu nhập >15tr
SELECT * FROM employees 
WHERE (department IN ('IT', 'HR') 
      AND join_year > 2020 
      AND (salary + COALESCE(bonus, 0)) > 15000000);

--b. Top 3 theo tổng thu nhập giảm dần
SELECT * FROM employees 
ORDER BY (salary + COALESCE(bonus, 0)) DESC 
LIMIT 3;

--4. truy vấn theo mã tên
SELECT * FROM employees 
WHERE full_name LIKE 'Nguyễn%' 
   OR full_name LIKE '%Hân';

--5. truy vấn đặc biệt
SELECT DISTINCT department 
FROM employees 
WHERE bonus IS NOT NULL;

--6. khoảng thời gian làm việc
SELECT * FROM employees 
WHERE join_year BETWEEN 2019 AND 2022;

SELECT * FROM employees ORDER BY id;

