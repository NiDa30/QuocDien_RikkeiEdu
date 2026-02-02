CREATE TABLE accounts(
account_id SERIAL PRIMARY KEY,
owner_name VARCHAR(100),
balance NUMERIC(12,2),
status VARCHAR(10) DEFAULT 'ACTIVE'
);
CREATE TABLE transactions(
trans_id SERIAL PRIMARY KEY,
from_account INT REFERENCES accounts(account_id),
to_account INT REFERENCES accounts(account_id),
amount(NUMERIC(12,2),
status VARCHAR(20) DEFAULT 'PENDING',
create_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO accounts (owner_name, balance, status) VALUES 
('Nguyen Van A', 1000.00, 'ACTIVE'),
('Tran Thi B', 500.00, 'ACTIVE');


--1 Transaction thành công
-- SERIALIZABLE + Lock theo thứ tự account_id tăng dần (ngăn deadlock)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;

-- a) LOCK tài khoản theo thứ tự ID: A(1) → B(2)
SELECT * FROM accounts WHERE account_id IN (1,2) FOR UPDATE ORDER BY account_id;

-- b) Kiểm tra điều kiện: ACTIVE + đủ tiền
DO $$
DECLARE
    v_balance_A NUMERIC;
    v_status_A VARCHAR;
BEGIN
    SELECT balance, status INTO v_balance_A, v_status_A 
    FROM accounts WHERE account_id = 1;
    
    IF v_status_A != 'ACTIVE' THEN
        RAISE EXCEPTION 'Tài khoản A bị khóa!';
    END IF;
    IF v_balance_A < 500.00 THEN
        RAISE EXCEPTION 'Tài khoản A không đủ 500!';
    END IF;
END $$;

-- c) Thực hiện chuyển tiền
UPDATE accounts SET balance = balance - 500.00 WHERE account_id = 1;  
UPDATE accounts SET balance = balance + 500.00 WHERE account_id = 2;  

-- d) Ghi transaction log
INSERT INTO transactions (from_account, to_account, amount, status)
VALUES (1, 2, 500.00, 'COMPLETED');

-- e) COMMIT
COMMIT;


--2. tài khoản locked và tự động ROLLBACK
BEGIN;
SELECT * FROM accounts WHERE account_id IN (1,2) FOR UPDATE ORDER BY account_id;

DO $$ BEGIN
    IF (SELECT status FROM accounts WHERE account_id = 1) != 'ACTIVE' THEN
        RAISE EXCEPTION 'Tài khoản A bị LOCKED!';
    END IF;
END $$;

-- Auto ROLLBACK khi exception
-- Tài khoản KHÔNG thay đổi, KHÔNG có transaction log

