create table flights (
flight_id SERIAL PRIMARY KEY,
flight_name VARCHAR(100),
available_seats INT
);
CREATE TABLE bookings(
booking_id SERIAL PRIMARY KEY,
flight_id INT REFERENCES flights(flight_id),
customer_name VARCHAR(100)
);

INSERT INTO flights (flight_name, available_seats)
VALUES ('VN123', 3), ('VN456', 2);

--1 
-- a) Bắt đầu Transaction
BEGIN;

-- b) Giảm số ghế chuyến bay VN123
UPDATE flights 
SET available_seats = available_seats - 1 
WHERE flight_name = 'VN123';

-- c) Thêm booking cho 'Nguyen Van A'
INSERT INTO bookings (flight_id, customer_name)
SELECT flight_id, 'Nguyen Van A'
FROM flights 
WHERE flight_name = 'VN123';

-- d) Kết thúc Transaction
COMMIT;

-- e) Kiểm tra dữ liệu
SELECT * FROM flights WHERE flight_name = 'VN123';

SELECT * FROM bookings WHERE customer_name = 'Nguyen Van A';


--2 Mô phỏng lỗi và ROLLBACK
-- a) Bắt đầu Transaction mới
BEGIN;

-- b) Giảm ghế chuyến bay VN123  
UPDATE flights 
SET available_seats = available_seats - 1 
WHERE flight_name = 'VN123';

-- c) LỖI: flight_id = 999 không tồn tại
INSERT INTO bookings (flight_id, customer_name)
VALUES (999, 'Tran Thi B');  

-- d) Hủy toàn bộ thay đổi
ROLLBACK;

-- e) Kiểm tra dữ liệu → KHÔNG thay đổi!
SELECT * FROM flights WHERE flight_name = 'VN123';

SELECT * FROM bookings WHERE customer_name = 'Tran Thi B';
