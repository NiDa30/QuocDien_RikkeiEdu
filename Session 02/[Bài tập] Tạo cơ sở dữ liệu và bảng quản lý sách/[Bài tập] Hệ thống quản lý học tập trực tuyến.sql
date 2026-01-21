--1. tạo DB
CREATE DATABASE ElearningDB;
--2. tạo schema Elearning
CREATE SCHEMA elearning;
--3. tạo table students
CREATE TABLE elearning.students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);
--4. tạo table instructors
CREATE TABLE elearning.instructors (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);
--5. tạo courses
CREATE TABLE elearning.courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    instructor_id INT NOT NULL,
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id)
        REFERENCES elearning.instructors(instructor_id)
);
--6. tạo table enrollments
CREATE TABLE elearning.enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enroll_date DATE NOT NULL,
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id)
        REFERENCES elearning.students(student_id),
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id)
        REFERENCES elearning.courses(course_id)
);
--7. tạo table assignment
CREATE TABLE elearning.assignments (
    assignment_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    CONSTRAINT fk_assignments_course
        FOREIGN KEY (course_id)
        REFERENCES elearning.courses(course_id)
);
--8. tạo table submissions
CREATE TABLE elearning.submissions (
    submission_id SERIAL PRIMARY KEY,
    assignment_id INT NOT NULL,
    student_id INT NOT NULL,
    submission_date DATE NOT NULL,
    grade NUMERIC CHECK (grade BETWEEN 0 AND 100),
    CONSTRAINT fk_submissions_assignment
        FOREIGN KEY (assignment_id)
        REFERENCES elearning.assignments(assignment_id),
    CONSTRAINT fk_submissions_student
        FOREIGN KEY (student_id)
        REFERENCES elearning.students(student_id)
);
