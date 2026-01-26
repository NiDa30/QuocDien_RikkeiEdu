-- =============================================
-- BÀI TẬP TỔNG HỢP: STORED PROCEDURE
-- Tình huống: Hệ thống ngân hàng "TECHMASTER BANK"
-- =============================================

-- =============================================
-- 1. SETUP DATABASE SCHEMA
-- =============================================

DROP TABLE IF EXISTS LichSuSoDu;
DROP TABLE IF EXISTS GiaoDich;
DROP TABLE IF EXISTS TaiKhoan;
DROP TABLE IF EXISTS KhachHang;
DROP TABLE IF EXISTS LogLoi;

-- Bảng khách hàng
CREATE TABLE KhachHang (
    id SERIAL PRIMARY KEY,
    ma_kh VARCHAR(20) UNIQUE NOT NULL,
    ho_ten VARCHAR(100) NOT NULL,
    so_du DECIMAL(15,2) DEFAULT 0.00,
    trang_thai VARCHAR(20) DEFAULT 'ACTIVE',
    loai_kh VARCHAR(20) DEFAULT 'STANDARD', -- Added for customer classification
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bảng tài khoản
CREATE TABLE TaiKhoan (
    id SERIAL PRIMARY KEY,
    ma_tk VARCHAR(20) UNIQUE NOT NULL,
    khach_hang_id INTEGER REFERENCES KhachHang(id),
    so_du DECIMAL(15,2) DEFAULT 0.00,
    loai_tk VARCHAR(50) DEFAULT 'THUONG',
    trang_thai VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bảng giao dịch
CREATE TABLE GiaoDich (
    id SERIAL PRIMARY KEY,
    ma_gd VARCHAR(30) UNIQUE NOT NULL,
    tai_khoan_id INTEGER REFERENCES TaiKhoan(id),
    loai_gd VARCHAR(20) NOT NULL, -- 'CHUYEN_TIEN', 'RUT_TIEN', 'GUI_TIEN'
    so_tien DECIMAL(15,2) NOT NULL,
    tai_khoan_doi_tac INTEGER, -- Dùng cho chuyển tiền
    noi_dung TEXT,
    trang_thai VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bảng lịch sử số dư
CREATE TABLE LichSuSoDu (
    id SERIAL PRIMARY KEY,
    tai_khoan_id INTEGER REFERENCES TaiKhoan(id),
    so_du_truoc DECIMAL(15,2),
    so_du_sau DECIMAL(15,2),
    thoi_gian TIMESTAMP DEFAULT NOW()
);

-- Bảng Log Lỗi
CREATE TABLE LogLoi (
    id SERIAL PRIMARY KEY,
    procedure_name VARCHAR(100),
    error_message TEXT,
    thoi_gian TIMESTAMP DEFAULT NOW()
);

-- INSERT SAMPLE DATA
INSERT INTO KhachHang (ma_kh, ho_ten, so_du) VALUES
('KH001', 'Nguyen Van A', 5000000),
('KH002', 'Tran Thi B', 150000000), -- Potential GOLD
('KH003', 'Le Van C', 2000000000); -- Potential VIP

INSERT INTO TaiKhoan (ma_tk, khach_hang_id, so_du) VALUES
('TK001', 1, 5000000),
('TK002', 2, 150000000),
('TK003', 3, 2000000000),
('TK004', 1, 100000); -- Khách hàng 1 có thêm tk phụ

-- =============================================
-- PHẦN 1: PROCEDURE CƠ BẢN
-- =============================================

-- 1.1 Procedure chuyển tiền
CREATE OR REPLACE PROCEDURE chuyen_tien(
    p_ma_tk_nguoi_gui VARCHAR,
    p_ma_tk_nguoi_nhan VARCHAR, 
    p_so_tien DECIMAL,
    p_noi_dung TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_gui INT;
    v_id_nhan INT;
    v_so_du_gui DECIMAL(15,2);
    v_msg TEXT;
BEGIN
    -- Kiểm tra tài khoản người gửi
    SELECT id, so_du INTO v_id_gui, v_so_du_gui
    FROM TaiKhoan WHERE ma_tk = p_ma_tk_nguoi_gui AND trang_thai = 'ACTIVE';
    
    IF v_id_gui IS NULL THEN
        RAISE EXCEPTION 'Tài khoản gửi % không tồn tại hoặc không hoạt động', p_ma_tk_nguoi_gui;
    END IF;

    -- Kiểm tra tài khoản người nhận
    SELECT id INTO v_id_nhan
    FROM TaiKhoan WHERE ma_tk = p_ma_tk_nguoi_nhan AND trang_thai = 'ACTIVE';
    
    IF v_id_nhan IS NULL THEN
        RAISE EXCEPTION 'Tài khoản nhận % không tồn tại hoặc không hoạt động', p_ma_tk_nguoi_nhan;
    END IF;

    -- Kiểm tra số dư
    IF v_so_du_gui < p_so_tien THEN
        RAISE EXCEPTION 'Số dư không đủ để thực hiện giao dịch';
    END IF;

    -- Thực hiện trừ tiền người gửi
    UPDATE TaiKhoan SET so_du = so_du - p_so_tien WHERE id = v_id_gui;
    
    -- Thực hiện cộng tiền người nhận
    UPDATE TaiKhoan SET so_du = so_du + p_so_tien WHERE id = v_id_nhan;

    -- Ghi lịch sử giao dịch (cho người gửi)
    INSERT INTO GiaoDich (ma_gd, tai_khoan_id, loai_gd, so_tien, tai_khoan_doi_tac, noi_dung, trang_thai)
    VALUES (
        'GD' || FLOOR(RANDOM() * 1000000)::TEXT, -- Giả lập mã GD
        v_id_gui, 
        'CHUYEN_TIEN', 
        p_so_tien, 
        v_id_nhan, 
        p_noi_dung, 
        'SUCCESS'
    );

    -- Ghi log lịch sử số dư (Simulate for sender)
    INSERT INTO LichSuSoDu (tai_khoan_id, so_du_truoc, so_du_sau)
    VALUES (v_id_gui, v_so_du_gui, v_so_du_gui - p_so_tien);

    RAISE NOTICE 'Chuyển tiền thành công từ % sang %: % VND', p_ma_tk_nguoi_gui, p_ma_tk_nguoi_nhan, p_so_tien;
    
    -- Transaction control is handled by caller or implicit commit
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
        RAISE EXCEPTION 'Lỗi giao dịch: %', v_msg;
        -- Rollback is automatic when exception creates a failure state
END;
$$;


-- 1.2 Procedure rút tiền
CREATE OR REPLACE PROCEDURE rut_tien(
    p_ma_tk VARCHAR,
    p_so_tien DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
    v_so_du DECIMAL(15,2);
BEGIN
    SELECT id, so_du INTO v_id, v_so_du
    FROM TaiKhoan WHERE ma_tk = p_ma_tk AND trang_thai = 'ACTIVE';

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Tài khoản % không tìm thấy', p_ma_tk;
    END IF;

    IF v_so_du < p_so_tien THEN
        RAISE EXCEPTION 'Số dư không đủ';
    END IF;

    UPDATE TaiKhoan SET so_du = so_du - p_so_tien WHERE id = v_id;

    INSERT INTO GiaoDich (ma_gd, tai_khoan_id, loai_gd, so_tien, noi_dung, trang_thai)
    VALUES ('RT' || FLOOR(RANDOM()*100000)::TEXT, v_id, 'RUT_TIEN', p_so_tien, 'Rút tiền mặt', 'SUCCESS');

    RAISE NOTICE 'Rút tiền thành công: % VND', p_so_tien;
END;
$$;

-- =============================================
-- PHẦN 2: PARAMETERS & BIẾN NÂNG CAO
-- =============================================

-- 2.1 Thông tin tài khoản (OUT parameters)
CREATE OR REPLACE PROCEDURE thong_tin_tai_khoan(
    p_ma_tk VARCHAR,
    OUT p_ho_ten VARCHAR,
    OUT p_so_du DECIMAL,
    OUT p_so_giao_dich INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tk_id INT;
BEGIN
    SELECT tk.id, kh.ho_ten, tk.so_du 
    INTO v_tk_id, p_ho_ten, p_so_du
    FROM TaiKhoan tk
    JOIN KhachHang kh ON tk.khach_hang_id = kh.id
    WHERE tk.ma_tk = p_ma_tk;

    IF v_tk_id IS NULL THEN
        RAISE EXCEPTION 'Tài khoản không tồn tại';
    END IF;

    -- Đếm số giao dịch
    SELECT COUNT(*) INTO p_so_giao_dich
    FROM GiaoDich WHERE tai_khoan_id = v_tk_id;
END;
$$;

-- 2.2 Tính lãi suất tháng
CREATE OR REPLACE PROCEDURE tinh_lai_suat_thang(
    p_thang INTEGER,
    p_nam INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_lai_suat DECIMAL(15,4) := 0.005; -- 0.5% / tháng
    v_tien_lai DECIMAL(15,2);
BEGIN
    -- Duyệt qua tất cả tài khoản active
    FOR rec IN SELECT * FROM TaiKhoan WHERE trang_thai = 'ACTIVE' LOOP
        v_tien_lai := rec.so_du * v_lai_suat;
        
        -- Cập nhật số dư
        UPDATE TaiKhoan 
        SET so_du = so_du + v_tien_lai 
        WHERE id = rec.id;
        
        RAISE NOTICE 'TK %: Cộng lãi % VND', rec.ma_tk, v_tien_lai;
    END LOOP;
END;
$$;


-- =============================================
-- PHẦN 3: ĐIỀU KIỆN & LOGIC PHỨC TẠP
-- =============================================

-- 3.1 Phân loại khách hàng
CREATE OR REPLACE PROCEDURE phan_loai_khach_hang()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_loai_moi VARCHAR(20);
BEGIN
    FOR rec IN SELECT * FROM KhachHang LOOP
        -- Logic phân loại dựa trên tổng số dư các tài khoản
        -- (Ở đây giả sử so_du trong bảng KhachHang là tổng, hoặc tính đè lên)
        -- Ta sẽ tính tổng từ bảng TaiKhoan cho chuẩn
        DECLARE
            v_tong_so_du DECIMAL(15,2);
        BEGIN
            SELECT SUM(so_du) INTO v_tong_so_du FROM TaiKhoan WHERE khach_hang_id = rec.id;
            IF v_tong_so_du IS NULL THEN v_tong_so_du := 0; END IF;

            IF v_tong_so_du > 1000000000 THEN -- > 1 tỷ
                v_loai_moi := 'VIP';
            ELSEIF v_tong_so_du > 100000000 THEN -- > 100 triệu
                v_loai_moi := 'GOLD';
            ELSEIF v_tong_so_du > 10000000 THEN -- > 10 triệu
                v_loai_moi := 'SILVER';
            ELSE
                v_loai_moi := 'STANDARD';
            END IF;

            -- Update nếu khác
            IF rec.loai_kh IS DISTINCT FROM v_loai_moi THEN
                UPDATE KhachHang SET loai_kh = v_loai_moi WHERE id = rec.id;
                RAISE NOTICE 'Khách hàng % (%): Cập nhật lên %', rec.ho_ten, rec.ma_kh, v_loai_moi;
            END IF;
        END;
    END LOOP;
END;
$$;

-- 3.2 Áp dụng phí giao dịch
CREATE OR REPLACE PROCEDURE ap_dung_phi_giao_dich(
    p_ma_gd VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_gd RECORD;
    v_phi DECIMAL(15,2) := 0;
    v_ngay_tao TIMESTAMP;
    v_is_weekend BOOLEAN;
BEGIN
    SELECT * INTO v_gd FROM GiaoDich WHERE ma_gd = p_ma_gd;
    
    IF v_gd.id IS NULL THEN
        RAISE EXCEPTION 'Giao dịch không tồn tại';
    END IF;

    -- Logic tính phí
    v_ngay_tao := v_gd.created_at;
    -- Kiểm tra cuối tuần (Extract DOW: 0=Sun, 6=Sat)
    v_is_weekend := EXTRACT(ISODOW FROM v_ngay_tao) IN (6, 7);

    IF v_gd.loai_gd = 'CHUYEN_TIEN' THEN
        v_phi := 1000;
        IF v_is_weekend THEN
             v_phi := v_phi * 1.5; -- Tăng 50% cuối tuần
        END IF;
    ELSIF v_gd.loai_gd = 'RUT_TIEN' THEN
        v_phi := 3000;
    END IF;

    -- Trừ phí vào tài khoản thực hiện
    IF v_phi > 0 THEN
        UPDATE TaiKhoan SET so_du = so_du - v_phi WHERE id = v_gd.tai_khoan_id;
        RAISE NOTICE 'Giao dịch %: Đã trừ phí % VND', p_ma_gd, v_phi;
    END IF;
END;
$$;

-- =============================================
-- PHẦN 4: VÒNG LẶP & XỬ LÝ HÀNG LOẠT
-- =============================================

-- 4.1 Sao kê tự động (Mô phỏng)
CREATE OR REPLACE PROCEDURE tao_sao_ke_thang(
    p_thang INTEGER,
    p_nam INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    tk RECORD;
    gd RECORD;
BEGIN
    FOR tk IN SELECT * FROM TaiKhoan WHERE trang_thai = 'ACTIVE' LOOP
        RAISE NOTICE '---------------------------------------------------';
        RAISE NOTICE 'SAO KÊ TÀI KHOẢN: % (Tháng %/%)', tk.ma_tk, p_thang, p_nam;
        RAISE NOTICE 'Số dư hiện tại: %', tk.so_du;
        RAISE NOTICE 'Lịch sử giao dịch:';
        
        FOR gd IN SELECT * FROM GiaoDich 
                  WHERE tai_khoan_id = tk.id 
                  AND EXTRACT(MONTH FROM created_at) = p_thang 
                  AND EXTRACT(YEAR FROM created_at) = p_nam
        LOOP
            RAISE NOTICE '  - [%] %: % VND (Nội dung: %)', gd.created_at, gd.loai_gd, gd.so_tien, gd.noi_dung;
        END LOOP;
    END LOOP;
END;
$$;

-- 4.2 Khóa tài khoản không hoạt động
CREATE OR REPLACE PROCEDURE khoa_tk_khong_hoat_dong(
    p_so_thang INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_last_active TIMESTAMP;
BEGIN
    FOR rec IN SELECT * FROM TaiKhoan WHERE trang_thai = 'ACTIVE' LOOP
        -- Lấy giao dịch gần nhất
        SELECT MAX(created_at) INTO v_last_active FROM GiaoDich WHERE tai_khoan_id = rec.id;
        
        -- Nếu không có gd hoặc gd quá cũ
        IF v_last_active IS NULL OR v_last_active < NOW() - (p_so_thang || ' months')::INTERVAL THEN
            UPDATE TaiKhoan SET trang_thai = 'LOCKED' WHERE id = rec.id;
            RAISE NOTICE 'Đã khóa tài khoản % do không hoạt động quá % tháng', rec.ma_tk, p_so_thang;
        END IF;
    END LOOP;
END;
$$;

-- =============================================
-- PHẦN 5: XỬ LÝ LỖI CHUYÊN NGHIỆP
-- =============================================

-- 5.2 Ghi log lỗi
CREATE OR REPLACE PROCEDURE ghi_log_loi(
    p_procedure_name VARCHAR,
    p_error_message TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO LogLoi(procedure_name, error_message)
    VALUES (p_procedure_name, p_error_message);
    COMMIT; -- Ghi log ngay lập tức (Trong procedure có thể commit)
END;
$$;

-- 5.1 Gửi tiền an toàn (Exception Handling)
CREATE OR REPLACE PROCEDURE gui_tien_an_toan(
    p_ma_tk VARCHAR,
    p_so_tien DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    -- Validation
    IF p_so_tien <= 0 THEN
        RAISE EXCEPTION 'Số tiền gửi phải lớn hơn 0';
    END IF;

    SELECT id INTO v_id FROM TaiKhoan WHERE ma_tk = p_ma_tk;
    
    IF v_id IS NULL THEN
         RAISE EXCEPTION 'Tài khoản không tồn tại';
    END IF;

    -- Thực hiện cộng tiền
    UPDATE TaiKhoan SET so_du = so_du + p_so_tien WHERE id = v_id;

    -- Ghi giao dịch
    INSERT INTO GiaoDich (ma_gd, tai_khoan_id, loai_gd, so_tien, noi_dung, trang_thai)
    VALUES ('GT' || FLOOR(RANDOM()*100000)::TEXT, v_id, 'GUI_TIEN', p_so_tien, 'Gửi tiền tại quầy', 'SUCCESS');

    RAISE NOTICE 'Gửi tiền thành công % vào TK %', p_so_tien, p_ma_tk;

EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        -- Lưu ý: Trong block EXCEPTION, transaction đã bị abort, transaction commands (COMMIT/ROLLBACK) không được phép trực tiếp nếu ta muốn rollback to savepoint, nhưng PL/pgSQL tự động rollback block này.
        -- Để ghi log, ta thường cần context khác hoặc chấp nhận log chỉ hiện trong output nếu không commit được.
        -- Tuy nhiên, Postgres Procedure hỗ trợ transaction management ngoài exception block.
        -- Ở đây ta chỉ in lỗi và rollback logic (tự động).
        RAISE NOTICE 'Lỗi xảy ra: %', SQLERRM;
        -- CALL ghi_log_loi('gui_tien_an_toan', SQLERRM); -- Cẩn thận gọi procedure có commit trong exception block
        ROLLBACK; -- Explicit rollback
END;
$$;

-- =============================================
-- KIỂM THỬ (TESTING)
-- =============================================
-- Chạy đoạn này riêng lẻ để test
DO $$
DECLARE
    v_name VARCHAR;
    v_bal DECIMAL;
    v_tx_count INT;
BEGIN
    -- 1. Test chuyển tiền
    RAISE NOTICE '--- TEST CHUYỂN TIỀN ---';
    CALL chuyen_tien('TK001', 'TK004', 50000, 'Test chuyen tien');
    
    -- 2. Test thông tin (OUT params)
    CALL thong_tin_tai_khoan('TK001', v_name, v_bal, v_tx_count);
    RAISE NOTICE 'Info TK001: Tên=%, Dư=%, Số GD=%', v_name, v_bal, v_tx_count;

    -- 3. Test phân loại
    RAISE NOTICE '--- TEST PHÂN LOẠI ---';
    CALL phan_loai_khach_hang();

    -- 4. Test tính lãi
    RAISE NOTICE '--- TEST TÍNH LÃI ---';
    CALL tinh_lai_suat_thang(10, 2023);

    -- 5. Test sao kê
    RAISE NOTICE '--- TEST SAO KÊ ---';
    CALL tao_sao_ke_thang(EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT);
    
    -- 6. Test gửi tiền an toàn (và lỗi)
    RAISE NOTICE '--- TEST GỬI TIỀN ---';
    CALL gui_tien_an_toan('TK001', 100000);
    -- Test lỗi
    -- CALL gui_tien_an_toan('TK_FAKE', 100000); 
END;
$$;
