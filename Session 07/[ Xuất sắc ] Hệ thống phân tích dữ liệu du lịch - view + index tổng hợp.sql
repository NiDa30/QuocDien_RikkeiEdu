-- Xóa bảng cũ nếu tồn tại
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

-- Tạo bảng Patients
CREATE TABLE patients(
	patient_id SERIAL PRIMARY KEY,
	full_name VARCHAR(100),
	phone VARCHAR(20),
	city VARCHAR(50),
	symptoms TEXT[]
);

-- Tạo bảng Doctors
CREATE TABLE doctors(
	doctor_id SERIAL PRIMARY KEY,
	full_name VARCHAR(100),
	department VARCHAR(50)
);

-- Tạo bảng Appointments
CREATE TABLE appointments (
	appointment_id SERIAL PRIMARY KEY,
	patient_id INT REFERENCES patients(patient_id),
	doctor_id INT REFERENCES doctors(doctor_id),
	appointment_date DATE,
	diagnosis VARCHAR(200),
	fee NUMERIC(10,2)
);

--1.Chèn ít nhất 5 bệnh nhân, 5 bác sĩ và 10 cuộc hẹn
-- Patients
INSERT INTO patients (full_name, phone, city, symptoms) VALUES
('Nguyen Van A', '0901111111', 'Hanoi', ARRAY['fever', 'cough']),
('Tran Thi B', '0902222222', 'HCMC', ARRAY['headache', 'dizziness']),
('Le Van C', '0903333333', 'Danang', ARRAY['sore throat', 'fever']),
('Pham Thi D', '0904444444', 'Hanoi', ARRAY['back pain']),
('Hoang Van E', '0905555555', 'HCMC', ARRAY['cough', 'fatigue']);

-- Doctors
INSERT INTO doctors (full_name, department) VALUES
('Dr. Smith', 'Cardiology'),
('Dr. House', 'Internal Medicine'),
('Dr. Strange', 'Neurology'),
('Dr. Who', 'General Practice'),
('Dr. Watson', 'Surgery');

-- Appointments
INSERT INTO appointments (patient_id, doctor_id, appointment_date, diagnosis, fee) VALUES
(1, 2, '2024-01-10', 'Flu', 50.00),
(2, 3, '2024-01-12', 'Migraine', 120.00),
(3, 4, '2024-01-15', 'Tonsillitis', 40.00),
(4, 5, '2024-01-20', 'Spinal strain', 200.00),
(5, 1, '2024-02-01', 'Hypertension', 150.00),
(1, 4, '2024-02-05', 'Checkup', 30.00),
(2, 2, '2024-02-10', 'Follow up', 60.00),
(3, 1, '2024-02-15', 'Checkup', 80.00),
(1, 3, '2024-03-01', 'Headache', 100.00),
(2, 5, '2024-03-05', 'Surgery follow up', 180.00);


--2.Tạo Index để tăng tốc truy vấn:
--a.B-tree: tìm bệnh nhân theo số điện thoại (phone)
CREATE INDEX idx_patients_phone ON patients(phone);

--b.Hash: tìm bệnh nhân theo city
CREATE INDEX idx_patients_city_hash ON patients USING HASH (city);

--c.GIN: tìm bệnh nhân theo từ khóa trong mảng symptoms
CREATE INDEX idx_patients_symptoms_gin ON patients USING GIN (symptoms);

--d.GiST: tìm cuộc hẹn theo khoảng phí (fee)
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE INDEX idx_appointments_fee_gist ON appointments USING GIST (fee);

--3.Tạo Clustered Index trên bảng appointments theo ngày khám
CREATE INDEX idx_appointments_date ON appointments(appointment_date);

CLUSTER appointments USING idx_appointments_date;

--4.Thực hiện các truy vấn trên View:
--a.Tìm top 3 bệnh nhân có tổng phí khám cao nhất
CREATE OR REPLACE VIEW v_top_paying_patients AS
SELECT 
    p.full_name, 
    SUM(a.fee) AS total_fee
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.full_name
ORDER BY total_fee DESC
LIMIT 3;

SELECT * FROM v_top_paying_patients;


--b.Tính tổng số lượt khám theo bác sĩ
CREATE OR REPLACE VIEW v_doctor_appointments AS
SELECT 
    d.full_name, 
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.full_name;

SELECT * FROM v_doctor_appointments;


--5.Tạo View có thể cập nhật để thay đổi city của bệnh nhân:
CREATE VIEW v_patient_city AS 
SELECT patient_id, full_name, city FROM patients
WITH CHECK OPTION;
--a.Thử cập nhật thành phố của 1 bệnh nhân qua View và kiểm tra lại bảng patients
UPDATE v_patient_city
SET city = 'Can Tho'
WHERE full_name = 'Nguyen Van A';

SELECT * FROM patients WHERE full_name = 'Nguyen Van A';

