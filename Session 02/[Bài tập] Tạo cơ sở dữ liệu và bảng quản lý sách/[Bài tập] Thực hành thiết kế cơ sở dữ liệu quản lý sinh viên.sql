--1. tạo Schema
CREATE SCHEMA university;
--2. tạo table students trong university
CREATE TABLE university.students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    email VARCHAR(255) NOT NULL UNIQUE
);
--3. tạo courses
CREATE TABLE university.courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits INT
);
--4.
CREATE TABLE university.enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT,
    course_id INT,
    enroll_date DATE,
    CONSTRAINT fk_student
        FOREIGN KEY (student_id)
        REFERENCES university.students(student_id),
    CONSTRAINT fk_course
        FOREIGN KEY (course_id)
        REFERENCES university.courses(course_id)
);
SELECT datname FROM pg_database;
--5
SELECT schema_name
FROM information_schema.schemata;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'university'
  AND table_name = 'students';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'university'
  AND table_name = 'courses';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'university'
  AND table_name = 'enrollments';
