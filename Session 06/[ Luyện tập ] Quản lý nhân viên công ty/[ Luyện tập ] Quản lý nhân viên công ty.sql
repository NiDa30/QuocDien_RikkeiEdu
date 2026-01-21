CREATE TABLE Employee (
	id SERIAL PRIMARY KEY,
	full_name VARCHAR(100),
	department VARCHAR(50),
	salary NUMERIC(10,2),
	hire_date DATE

);

--1.
INSERT INTO Employee (full_name, department, salary, hire_date) VALUES
('Nguyễn Văn An',     'IT',      15000000, '2023-05-15'),
('Trần Thị Bình',    'HR',      12000000, '2022-03-10'),
('Lê Văn Cường',     'IT',      18000000, '2023-08-20'),
('Phạm Thị Dung',    'Finance', 8000000,  '2021-11-05'),
('Hoàng Văn Em',     'IT',      16000000, '2023-02-28'),
('Vũ Thị Phương An', 'Marketing', 7000000, '2024-01-12');

--2.
UPDATE Employee 
SET salary = salary * 1.10 
WHERE department = 'IT';

--3.
DELETE FROM Employee 
WHERE salary < 6000000;

--4.
SELECT * FROM Employee 
WHERE full_name ILIKE '%An%';

--5.
SELECT * FROM Employee 
WHERE hire_date BETWEEN '2023-01-01' AND '2023-12-31';

