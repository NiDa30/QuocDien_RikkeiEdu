CREATE TABLE post(
	post_id SERIAL PRIMARY KEY,
	user_id INT NOT NULL,
	content TEXT,
	tags TEXT[],
	create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	is_public BOOLEAN DEFAULT TRUE

);

CREATE TABLE post_like(
	user_id INT NOT NULL,
	post_id INT NOT NULL,
	like_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (user_id, post_id)

);

--1.Tối ưu hóa truy vấn tìm kiếm bài đăng công khai theo từ khóa:
--SELECT * FROM post
--WHERE is_public = TRUE AND content ILIKE '%du lịch%';
--a.Tạo Expression Index sử dụng LOWER(content) để tăng tốc tìm kiếm
SELECT *
FROM post
WHERE is_public = TRUE
  AND LOWER(content) LIKE '%du lịch%';

--b.So sánh hiệu suất trước và sau khi tạo chỉ mục
EXPLAIN ANALYZE
SELECT * FROM post
WHERE is_public = TRUE AND LOWER(content) = 'du lịch';

--2. 	Tối ưu hóa truy vấn lọc bài đăng theo thẻ (tags):
--SELECT * FROM post WHERE tags @> ARRAY['travel'];
--a.Tạo GIN Index cho cột tags
CREATE INDEX idx_post_tags_gin
ON post
USING GIN (tags);

--b. Phân tích hiệu suất bằng EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE tags @> ARRAY['travel'];


--3.Tối ưu hóa truy vấn tìm bài đăng mới trong 7 ngày gần nhất:
--a.Tạo Partial Index cho bài viết công khai gần đây:
--CREATE INDEX idx_post_recent_public
--ON post(create_at DESC)
--WHERE is_public = TRUE
-- Tạo Partial Index cho bài viết công khai
CREATE INDEX idx_post_recent_public
ON post (create_at DESC)
WHERE is_public = TRUE;

 
--b.Kiểm tra hiệu suất với truy vấn:
--SELECT * FROM post
--WHERE is_public = TRUE AND create_at >= NOW() - INTERVAL '7 days'
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE is_public = TRUE 
  AND create_at >= NOW() - INTERVAL '7 days';


--4.Phân tích chỉ mục tổng hợp (Composite Index):
--a.Tạo chỉ mục (user_id, created_at DESC)
-- Tạo index tổng hợp: user_id để lọc (=), create_at để sắp xếp
CREATE INDEX idx_post_user_recent
ON post (user_id, create_at DESC);

--b.Kiểm tra hiệu suất khi người dùng xem “bài đăng gần đây của bạn bè”
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE user_id IN (2, 5, 9, 15) -- Giả sử đây là ID bạn bè
ORDER BY create_at DESC
LIMIT 20;

