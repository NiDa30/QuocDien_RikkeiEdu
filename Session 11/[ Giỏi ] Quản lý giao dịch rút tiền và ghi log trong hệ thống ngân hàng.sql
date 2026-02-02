CREATE TABLE accounts(
    account_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    balance NUMERIC(12,2)
);

CREATE TABLE transactions (
    trans_id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts( account_id),
    amount NUMERIC(12,2),
    trans_type VARCHAR(20),
    create_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO accounts (customer_name, balance) VALUES 
('Nguyen Van A', 1000.00),
('Tran Thi B', 500.00);

--1. Transactio rút tiền
-- a) Bắt đầu Transaction
BEGIN;

-- b) Kiểm tra số dư trước khi rút
UPDATE accounts 
SET balance = balance - 200.00 
WHERE customer_name = 'Nguyen Van A' 
AND balance >= 200.00;

-- c) Ghi log giao dịch WITHDRAWAL
INSERT INTO transactions (account_id, amount, trans_type)
SELECT account_id, 200.00, 'WITHDRAWAL'
FROM accounts 
WHERE customer_name = 'Nguyen Van A';

-- d) COMMIT - Lưu cả account và transaction log
COMMIT;

-- kiểm tra
SELECT * FROM accounts WHERE customer_name = 'Nguyen Van A';

SELECT * FROM transactions WHERE trans_type = 'WITHDRAWAL' ORDER BY create_at DESC;

--2. Transaction ROLLBACK
SELECT * FROM accounts WHERE customer_name = 'Nguyen Van A';

SELECT * FROM transactions WHERE trans_type = 'WITHDRAWAL' ORDER BY create_at DESC;

--4. Transaction nạp tiền
BEGIN;

-- Nạp 300 vào tài khoản B
UPDATE accounts 
SET balance = balance + 300.00 
WHERE customer_name = 'Tran Thi B';

INSERT INTO transactions (account_id, amount, trans_type)
SELECT account_id, 300.00, 'DEPOSIT'
FROM accounts WHERE customer_name = 'Tran Thi B';

COMMIT;

--6. xem lại lịch sử 
SELECT 
    a.customer_name,
    t.amount,
    t.trans_type,
    t.create_at,
    a.balance as current_balance
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
ORDER BY t.create_at DESC;
