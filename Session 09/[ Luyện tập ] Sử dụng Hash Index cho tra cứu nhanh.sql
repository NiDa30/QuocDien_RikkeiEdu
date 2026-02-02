CREATE TABLE Users(
	user_id SERIAL PRIMARY KEY,
	email VARCHAR(255) UNIQUE NOT NULL,
	username VARCHAR(100) NOT NULL

);

CREATE INDEX idx_users_email_hash ON Users USING HASH (email);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM Users WHERE email = 'example@example.com';