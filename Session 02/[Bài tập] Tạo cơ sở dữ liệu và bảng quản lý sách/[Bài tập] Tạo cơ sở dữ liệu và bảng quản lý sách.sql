--1. tạo database
CREATE DATABASE "LibraryDB";
-- 2. tạo schema
CREATE SCHEMA library;
--3. trong schema libray, tạo table Books
CREATE TABLE library.Books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(50) NOT NULL,
    published_year INT,
    price NUMERIC
);
--4. xem tất cả DB
SELECT datname FROM pg_database;
-- xem tất cả Schema trong DB đang use
SELECT schema_name
FROM information_schema.schemata;

-- xem cấu trúc table Book
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'library'
  AND table_name = 'books';
