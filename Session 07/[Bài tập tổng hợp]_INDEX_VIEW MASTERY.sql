-- 0.1 Tạo Bảng (Clean start)
DROP MATERIALIZED VIEW IF EXISTS mv_thong_ke_toan_truong;
DROP VIEW IF EXISTS v_sinh_vien_ca_nhan, v_giang_vien, v_bao_cao_diem CASCADE;
DROP TABLE IF EXISTS BangDiem, SinhVien, LopHoc, MonHoc CASCADE;

CREATE TABLE MonHoc (
    id SERIAL PRIMARY KEY,
    ma_mon VARCHAR(20) UNIQUE,
    ten_mon VARCHAR(100)
);

CREATE TABLE LopHoc (
    id SERIAL PRIMARY KEY,
    ma_lop VARCHAR(20) UNIQUE,
    ten_lop VARCHAR(100),
    khoa_id INTEGER
);

CREATE TABLE SinhVien (
    id SERIAL PRIMARY KEY,
    ma_sv VARCHAR(20) UNIQUE,
    ho_ten VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    gioi_tinh VARCHAR(10),
    que_quan VARCHAR(100),
    ngay_sinh DATE,
    lop_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE BangDiem (
    id SERIAL PRIMARY KEY,
    sinh_vien_id INTEGER,
    mon_hoc_id INTEGER,
    diem_so DECIMAL(4,2),
    hoc_ky VARCHAR(10),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 0.2 Sinh dữ liệu giả (Dùng generate_series)
-- Sinh 200 môn học
INSERT INTO MonHoc (ma_mon, ten_mon)
SELECT 'MH' || id, 'Mon Hoc ' || id FROM generate_series(1, 200) id;

-- Sinh 500 lớp học
INSERT INTO LopHoc (ma_lop, ten_lop, khoa_id)
SELECT 'LOP' || id, 'Lop Hoc ' || id, (random() * 10)::int + 1 FROM generate_series(1, 500) id;

-- Sinh 1 triệu Sinh Viên (Giảm xuống 1tr để demo nhanh hơn, nhưng đủ để test index)
-- Nếu muốn 3 triệu, sửa 1000000 thành 3000000
INSERT INTO SinhVien (ma_sv, ho_ten, email, gioi_tinh, que_quan, ngay_sinh, lop_id)
SELECT 
    'SV' || id, 
    'Nguyen Van ' || (id % 100), 
    'sv' || id || '@techmaster.edu.vn', -- Email unique giả định
    CASE WHEN random() > 0.5 THEN 'Nam' ELSE 'Nu' END,
    (ARRAY['Ha Noi', 'HCMC', 'Da Nang', 'Can Tho', 'Hai Phong'])[floor(random()*5)+1],
    '2000-01-01'::date + (random() * 365 * 2)::int,
    (random() * 499 + 1)::int
FROM generate_series(1, 1000000) id;

-- Thêm SV test cụ thể
INSERT INTO SinhVien (ma_sv, ho_ten, email, gioi_tinh, que_quan, lop_id) 
VALUES ('SVTEST', 'Nam Nguyen', 'nam.nguyen@techmaster.edu.vn', 'Nam', 'Ha Noi', 1);

-- Sinh 5 triệu điểm (mỗi SV khoảng 5 điểm)
INSERT INTO BangDiem (sinh_vien_id, mon_hoc_id, diem_so, hoc_ky)
SELECT 
    (random() * 1000000 + 1)::int,
    (random() * 199 + 1)::int,
    (random() * 10)::numeric(4,2),
    '2024-1'
FROM generate_series(1, 5000000) id;


--PHẦN 1: INDEX OPTIMIZATION 
--1.1. Phân tích hiện trạng:
-- Câu query đang chạy rất chậm (10-15 giây)
EXPLAIN ANALYZE 
SELECT * FROM SinhVien WHERE email = 'nam.nguyen@techmaster.edu.vn';
--Kết quả: Seq Scan on SinhVien - Full Table Scan!

--1.2. Tạo các Index cần thiết:
--Index cho email (tìm kiếm nhanh)
CREATE INDEX idx_sv_email ON SinhVien(email);

--Index cho khóa ngoại lop_id (JOIN nhanh)
CREATE INDEX idx_sv_lop_id ON SinhVien(lop_id);
CREATE INDEX idx_bangdiem_sv_id ON BangDiem(sinh_vien_id);

--Index cho que_quan (báo cáo theo địa phương)
CREATE INDEX idx_sv_que_quan ON SinhVien(que_quan);

--Index composite cho (gioi_tinh, que_quan) (báo cáo kết hợp)
CREATE INDEX idx_sv_gioitinh_quequan ON SinhVien(gioi_tinh, que_quan);

--1.3. So sánh hiệu năng:
--Dùng EXPLAIN ANALYZE để chứng minh sự cải thiện từ 15 giây → 0.01 giây!

 
--PHẦN 2: VIEW DESIGN 
--2.1. Tạo View cho báo cáo điểm tổng hợp:
-- View phức tạp: Thông tin SV + Lớp + Điểm TB
CREATE VIEW v_bao_cao_diem AS
SELECT sv.ma_sv, sv.ho_ten, sv.email, l.ten_lop,
    COUNT(bd.id) as so_mon_hoc,
    AVG(bd.diem_so) as diem_trung_binh
FROM SinhVien sv
JOIN LopHoc l ON sv.lop_id = l.id
JOIN BangDiem bd ON sv.id = bd.sinh_vien_id
GROUP BY sv.id, sv.ma_sv, sv.ho_ten, sv.email, l.ten_lop;

--2.2. Tạo View cho thống kê lớp học:
--Sĩ số từng lớp
--Điểm trung bình lớp
--Phân loại học lực
CREATE OR REPLACE VIEW v_thong_ke_lop AS
SELECT 
    l.ten_lop,
    COUNT(sv.id) as si_so,
    AVG(bd.diem_so) as diem_tb_lop,
    SUM(CASE WHEN bd.diem_so >= 8 THEN 1 ELSE 0 END) as so_gioi,
    SUM(CASE WHEN bd.diem_so < 5 THEN 1 ELSE 0 END) as so_yeu
FROM LopHoc l
JOIN SinhVien sv ON l.id = sv.lop_id
LEFT JOIN BangDiem bd ON sv.id = bd.sinh_vien_id
GROUP BY l.id, l.ten_lop;


--2.3. Tạo Materialized View cho báo cáo:
-- Dùng Materialized View cho báo cáo tổng hợp toàn trường
CREATE MATERIALIZED VIEW mv_thong_ke_toan_truong AS
SELECT que_quan, gioi_tinh,
    COUNT(*) as so_luong,
    AVG(diem_trung_binh) as diem_tb_tinh
FROM v_bao_cao_diem
GROUP BY que_quan, gioi_tinh;
 
--PHẦN 3: PERFORMANCE ANALYSIS 
--3.1. Phân tích query plans:
--So sánh EXPLAIN trước và sau khi tạo Index
--Phân tích chi phí (cost) và thời gian thực thi

--3.2. Đánh giá trade-off:
--Đo lường thời gian INSERT/UPDATE trước và sau Index
EXPLAIN ANALYZE 
SELECT * FROM SinhVien WHERE gioi_tinh = 'Nam' AND que_quan = 'Ha Noi';

--Phân tích dung lượng Index chiếm bao nhiêu % database
SELECT 
    pg_size_pretty(pg_relation_size('SinhVien')) as table_size,
    pg_size_pretty(pg_indexes_size('SinhVien')) as index_size;

	
--PHẦN 4: SECURITY WITH VIEW 
--4.1. Tạo View bảo mật:
-- View cho sinh viên - chỉ xem được thông tin của mình
CREATE VIEW v_sinh_vien_ca_nhan AS
SELECT ma_sv, ho_ten, email, ten_lop, diem_trung_binh
FROM v_bao_cao_diem
WHERE email = CURRENT_USER;  

-- View cho giảng viên - ẩn thông tin nhạy cảm
CREATE VIEW v_giang_vien AS
SELECT ma_sv, ho_ten, ten_lop, diem_trung_binh
FROM v_bao_cao_diem;