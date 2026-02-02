CREATE TABLE accounts (
account_id SERIAL PRIMARY KEY,
ower_name VARCHAR(100),
balance NUMERIC(10,2)
);

INSERT INTO accounts( ower_name, balance)
VALUES ('A', 500.00), ('B', 300.00);

--1. Thực hiện giao dịch chuyển tiền hợp lệ
-- a) Dùng BEGIN để bắt đầu transaction
BEGIN;

-- b) Cập nhật giảm số dư của A đi 100.00
UPDATE accounts 
SET balance = balance - 100.00 
WHERE ower_name = 'A';

-- c) Cập nhật tăng số dư của B thêm 100.00
UPDATE accounts 
SET balance = balance + 100.00 
WHERE ower_name = 'B';

-- d) Dùng COMMIT để hoàn tất
COMMIT;

-- Kiểm tra số dư mới của cả hai tài khoản
SELECT * FROM accounts WHERE ower_name IN ('A', 'B');

--2. Mô phỏng lỗi và ROLLBACK
-- a) Lặp lại quy trình: Dùng BEGIN để bắt đầu transaction  
BEGIN;

-- b) Cập nhật giảm số dư của A đi 100.00
UPDATE accounts 
SET balance = balance - 100.00 
WHERE ower_name = 'A';

-- c) Lỗi: Nhập sai account_id của người nhận (999 không tồn tại)
UPDATE accounts 
SET balance = balance + 100.00 
WHERE account_id = 999;  

-- d) Gọi ROLLBACK khi xảy ra lỗi
ROLLBACK;

-- e) Kiểm tra lại số dư → Đảm bảo không có thay đổi
SELECT * FROM accounts WHERE ower_name IN ('A', 'B');

-- Transaction an toàn và kiểm tra
BEGIN;

DO $$
DECLARE
    v_balance_A NUMERIC;
BEGIN
    SELECT balance INTO v_balance_A FROM accounts WHERE ower_name = 'A';
    IF v_balance_A < 100.00 THEN
        RAISE EXCEPTION 'Số dư tài khoản A không đủ!';
    END IF;
END $$;

UPDATE accounts SET balance = balance - 100.00 WHERE ower_name = 'A';
UPDATE accounts SET balance = balance + 100.00 WHERE ower_name = 'B';

COMMIT;
