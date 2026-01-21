DROP TABLE IF EXISTS Employee CASCADE;
DROP TABLE IF EXISTS Department;
CREATE TABLE Department(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50)

);
CREATE TABLE Employee(
	id SERIAL PRIMARY KEY,
	full_name VARCHAR(100),
	department_id INT,
	salary NUMERIC(10,2)

);

-- Thêm dữ liệu Department
INSERT INTO Department (name) VALUES
('IT'), ('HR'), ('Finance'), ('Marketing');

-- Thêm dữ liệu Employee
INSERT INTO Employee (full_name, department_id, salary) VALUES
('Nguyễn Văn An',     1, 18000000),  -- IT
('Trần Thị Bình',    2, 12000000),  -- HR
('Lê Văn Cường',     1, 20000000),  -- IT
('Phạm Thị Dung',    3, 14000000),  -- Finance
('Hoàng Văn Em',     1, 16000000),  -- IT
('Vũ Thị Phương',    2, 13000000),  -- HR
('Nguyễn Văn Giang', NULL, 11000000);


--1. liệt kê NV cùng tên phòng ban
SELECT 
    e.id,
    e.full_name,
    d.name as department_name
FROM Employee e
INNER JOIN Department d ON e.department_id = d.id
ORDER BY e.id;


--2. tính lương trung bình của từng phòng ban
SELECT 
    d.name as department_name,
    ROUND(AVG(e.salary), 0) as avg_salary,
    COUNT(e.id) as employee_count
FROM Department d
LEFT JOIN Employee e ON d.id = e.department_id
GROUP BY d.id, d.name
ORDER BY avg_salary DESC;


--3. Hiển thị các phòng ban có lương trung bình > 10 triệu (HAVING)
SELECT 
    d.name as department_name,
    ROUND(AVG(e.salary), 0) as avg_salary
FROM Department d
INNER JOIN Employee e ON d.id = e.department_id
GROUP BY d.id, d.name
HAVING AVG(e.salary) > 10000000
ORDER BY avg_salary DESC;


--4. Liệt kê phòng ban không có nhân viên nào
--(LEFT JOIN + WHERE employee.id IS NULL)
SELECT d.name as department_name
FROM Department d
LEFT JOIN Employee e ON d.id = e.department_id
WHERE e.id IS NULL;

SELECT * FROM Department ORDER BY id;
SELECT * FROM Employee ORDER BY id;




