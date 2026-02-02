--PHẦN 1: TRANSACTION CƠ BẢN
--Bài 1.1: Vấn đề KHÔNG dùng Transaction

--KHÔNG dùng Transaction
UPDATE tai_khoan SET so_du = so_du - 1000000 WHERE id = 'TK001';  -- TK001: 5tr → 4tr
-- LỖI: Syntax error hoặc mất điện!

UPDAT tai_khoan SET so_du = so_du + 1000000 WHERE id = 'TK002';  -- LỖI!

-- KẾT QUẢ: TK001 mất 1tr, TK002 KHÔNG nhận → DỮ LIỆU SAI!
SELECT * FROM tai_khoan WHERE id IN ('TK001','TK002');

--Bài 1.2: Transaction AN TOÀN
-- AN TOÀN - Dùng Transaction
BEGIN;
-- Kiểm tra số dư
DO $$ 
BEGIN 
    IF (SELECT so_du FROM tai_khoan WHERE id='TK001') < 1000000 THEN
        RAISE EXCEPTION 'Không đủ tiền!';
    END IF; 
END $$;

-- Chuyển tiền
UPDATE tai_khoan SET so_du = so_du - 1000000 WHERE id = 'TK001';
UPDATE tai_khoan SET so_du = so_du + 1000000 WHERE id = 'TK002';

COMMIT;  -- TẤT CẢ thành công → Lưu

--PHẦN 2: STORED PROCEDURE
--Bài 2.1: Procedure chuyen_khoan_an_toan
CREATE OR REPLACE FUNCTION chuyen_khoan_an_toan(
    p_tk_nguoi_gui VARCHAR(10),
    p_tk_nguoi_nhan VARCHAR(10), 
    p_so_tien DECIMAL
) RETURNS VARCHAR 
LANGUAGE plpgsql
AS $$
DECLARE
    v_so_du_gui DECIMAL;
    v_trang_thai_gui VARCHAR(20);
    v_ton_tai_gui BOOLEAN;
    v_ton_tai_nhan BOOLEAN;
BEGIN
    SELECT so_du, trang_thai, EXISTS(SELECT 1) INTO v_so_du_gui, v_trang_thai_gui, v_ton_tai_gui
    FROM tai_khoan WHERE id = p_tk_nguoi_gui;
    
    SELECT EXISTS(SELECT 1) INTO v_ton_tai_nhan FROM tai_khoan WHERE id = p_tk_nguoi_nhan;
    
    -- Validation
    IF NOT v_ton_tai_gui THEN
        RETURN 'Tài khoản nguồn không tồn tại';
    END IF;
    IF NOT v_ton_tai_nhan THEN  
        RETURN 'Tài khoản đích không tồn tại';
    END IF;
    IF v_trang_thai_gui != 'ACTIVE' THEN
        RETURN 'Tài khoản nguồn bị khóa';
    END IF;
    IF v_so_du_gui < p_so_tien THEN
        RETURN 'Không đủ số dư';
    END IF;
    
    -- THỰC HIỆN GIAO DỊCH
    UPDATE tai_khoan SET so_du = so_du - p_so_tien WHERE id = p_tk_nguoi_gui;
    UPDATE tai_khoan SET so_du = so_du + p_so_tien WHERE id = p_tk_nguoi_nhan;
    
    -- Ghi log
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES (p_tk_nguoi_gui, p_tk_nguoi_nhan, p_so_tien, 'CHUYEN_KHOAN', 'COMPLETED');
    
    RETURN 'Chuyển khoản thành công: ' || p_so_tien || 'đ';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Lỗi: ' || SQLERRM;
END;
$$;

--Bài 2.2: Test cases
-- TH1:Thành công
SELECT chuyen_khoan_an_toan('TK001', 'TK002', 500000);

-- TH2:Không đủ tiền  
SELECT chuyen_khoan_an_toan('TK001', 'TK002', 10000000);

-- TH3: Tài khoản khóa
SELECT chuyen_khoan_an_toan('TK003', 'TK001', 100000);

-- TH4: TK không tồn tại
SELECT chuyen_khoan_an_toan('TK999', 'TK001', 100000);

--PHẦN 3: ISOLATION LEVELS
--Bài 3.1: Race Condition (OVERSell vé)
--Kết quả: so_luong_con = -1 (BÁN YẾU!)

--Hiện tượng: RACE CONDITION - 2 user cùng đọc stock=1 → cùng trừ → oversell

--Bài 3.2: Giải pháp SERIALIZABLE
-- USER A (Terminal 1)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC003';
SELECT pg_sleep(10);
UPDATE ve_phim SET so_luong_con = so_luong_con - 1 
WHERE suat_chieu_id = 'SC003' AND so_luong_con > 0;
COMMIT;

-- USER B (Terminal 2) → BỊ BLOCK → SERIALIZATION FAILURE!
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC003';
UPDATE ve_phim SET so_luong_con = so_luong_con - 1 
WHERE suat_chieu_id = 'SC003' AND so_luong_con > 0;
-- → LỖI: serialization failure → Auto ROLLBACK
COMMIT;

--PHẦN 4: SAVEPOINT
--Bài 4.1: Procedure phức tạp
CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN 'Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  -- Giữ phí, hủy mua vé
            RETURN 'Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  -- Hủy tất cả
            RETURN 'Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  -- Hủy toàn bộ
            RETURN 'Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;


CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN '✅ Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  -- Giữ phí, hủy mua vé
            RETURN '⚠️ Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  -- Hủy tất cả
            RETURN '❌ Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  -- Hủy toàn bộ
            RETURN '❌ Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;

CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN 'Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  -- Giữ phí, hủy mua vé
            RETURN '⚠️ Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  -- Hủy tất cả
            RETURN '❌ Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  -- Hủy toàn bộ
            RETURN '❌ Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;
CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN 'Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  -- Giữ phí, hủy mua vé
            RETURN 'Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  -- Hủy tất cả
            RETURN 'Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  -- Hủy toàn bộ
            RETURN 'Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;

CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN 'Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  
            RETURN 'Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  
            RETURN 'Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  -- Hủy toàn bộ
            RETURN 'Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;

CREATE OR REPLACE FUNCTION chuyen_tien_va_mua_ve() 
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    -- SAVEPOINT 1: Trước chuyển tiền
    SAVEPOINT sp_chuyen_tien;
    
    -- 1. Chuyển 1tr từ TK004 → TK001
    PERFORM chuyen_khoan_an_toan('TK004', 'TK001', 1000000);
    
    -- SAVEPOINT 2: Trước phí
    SAVEPOINT sp_phi;
    
    -- 2. Trừ phí 5k vào TK005
    UPDATE tai_khoan SET so_du = so_du + 5000 WHERE id = 'TK005';
    INSERT INTO giao_dich (tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, trang_thai)
    VALUES ('SYSTEM', 'TK005', 5000, 'PHI_GD', 'COMPLETED');
    
    -- SAVEPOINT 3: Trước mua vé
    SAVEPOINT sp_mua_ve;
    
    -- 3. Mua 2 vé Avengers (SC001)
    IF (SELECT so_luong_con FROM ve_phim WHERE suat_chieu_id = 'SC001') < 2 THEN
        RAISE EXCEPTION 'Không đủ vé!';
    END IF;
    
    UPDATE ve_phim SET so_luong_con = so_luong_con - 2 WHERE suat_chieu_id = 'SC001';
    
    RETURN 'Hoàn tất: Chuyển tiền + Phí + Mua vé thành công!';
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback theo mức độ lỗi
        IF SQLERRM LIKE '%Không đủ vé%' THEN
            ROLLBACK TO sp_mua_ve;  
            RETURN 'Mua vé thất bại, đã thu phí';
        ELSIF SQLERRM LIKE '%chuyen_khoan%' THEN
            ROLLBACK TO sp_chuyen_tien;  
            RETURN 'Chuyển tiền thất bại';
        ELSE
            ROLLBACK;  
            RETURN 'Lỗi hệ thống: ' || SQLERRM;
        END IF;
END;
$$;