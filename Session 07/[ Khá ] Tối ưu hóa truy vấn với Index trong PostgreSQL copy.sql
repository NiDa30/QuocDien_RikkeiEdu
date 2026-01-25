CREATE TABLE book(
	book_id SERIAL PRIMARY KEY,
	title VARCHAR(255),
	author VARCHAR(100),
	genre VARCHAR(50),
	price DECIMAL(10,2),
	description TEXT,
	create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);
--
INSERT INTO book (title, author, genre, price, description) 
SELECT 
    'Book ' || generate_series(1,1000),
    CASE 
        WHEN random() > 0.7 THEN 'J.K. Rowling'
        WHEN random() > 0.5 THEN 'J.R.R. Tolkien' 
        ELSE 'Author ' || (random()*100)::int
    END,
    CASE 
        WHEN random() > 0.6 THEN 'Fantasy'
        WHEN random() > 0.4 THEN 'Sci-Fi'
        ELSE 'Fiction'
    END,
    (random() * 500000 + 50000)::numeric(10,2),
    'Description for book ' || generate_series(1,1000)
FROM generate_series(1,1000);


-- Test 1: Tìm theo author (chậm)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM book WHERE author ILIKE '%Rowling%';

-- Test 2: Tìm theo genre (chậm hơn)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM book WHERE genre = 'Fantasy';



--1.
--SELECT * FROM book WHERE author ILIKE '%Rowling%';
--SELECT * FROM book WHERE genre = 'Fantasy';
-- Index 1: B-tree cho genre (equality + range queries)
CREATE INDEX idx_book_genre ON book(genre);

-- Index 2: B-tree cho author (phổ biến nhất)
CREATE INDEX idx_book_author ON book(author);

-- Index 3: GIN cho full-text search (ILIKE '%text%')
CREATE INDEX idx_book_author_trgm ON book USING gin(author gin_trgm_ops);

-- Index 4: Composite index (genre + author)
CREATE INDEX idx_book_genre_author ON book(genre, author);

-- Test lại - sẽ nhanh hơn rất nhiều!
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM book WHERE author ILIKE '%Rowling%';

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM book WHERE genre = 'Fantasy';



-- CLUSTER theo genre (sắp xếp vật lý dữ liệu)
CLUSTER book USING idx_book_genre;

-- VACUUM để cập nhật statistics
VACUUM ANALYZE book;

-- Test lại
EXPLAIN (ANALYZE) SELECT * FROM book WHERE genre = 'Fantasy';

--2.So sánh thời gian truy vấn trước và sau khi tạo Index (dùng EXPLAIN ANALYZE)

--3.Thử nghiệm các loại chỉ mục khác nhau:
--B-tree cho genre

--GIN cho title hoặc description (phục vụ tìm kiếm full-text)
--4.Tạo một Clustered Index (sử dụng lệnh CLUSTER) trên bảng book theo cột genre và kiểm tra sự khác biệt trong hiệu suất

--5. Viết báo cáo ngắn (5-7 dòng) giải thích:
--Loại chỉ mục nào hiệu quả nhất cho từng loại truy vấn?

--Khi nào Hash index không được khuyến khích trong PostgreSQL?
 