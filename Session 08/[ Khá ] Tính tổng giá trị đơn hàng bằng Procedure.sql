-- Cài đặt hàm
create function cong2so(a int, b int)
returns int as $$
begin
	return a+b;
end; $$ language plpgsql;

-- Gọi hàm
select cong2so(23,43) as "Tổng 2 số";

select * from lophoc;

-- Hàm lấy hết dữ liệu lớp học
create or replace function get_all_classes()
returns table(id int, ma_lop varchar(20), ten_lop varchar(100), khoa_id int)
as $$
begin
	return query
	select l.id, l.ma_lop,l.ten_lop, l.khoa_id
	from lophoc l;
end; $$ language plpgsql;

-- Gọi hàm
select * from get_all_classes();

-- Hàm lấy dữ liệu lớp học và sinh viên
create or replace function get_all_classe_students()
returns table(ma_lop varchar(20),ten_lop varchar(100),ma_sv varchar(20),ho_ten varchar(100),
email varchar(150), gioi_tinh varchar(10),que_quan varchar(100),ngay_sinh date) as $$
begin
	return query
	select lh.ma_lop,lh.ten_lop,sv.ma_sv,sv.ho_ten,sv.email,sv.gioi_tinh,sv.que_quan,sv.ngay_sinh
	from lophoc lh join sinhvien sv on lh.id = sv.lop_id;
end; $$ language plpgsql;

select * from sinhvien;

select * from get_all_classe_students();

-- Hàm lấy dữ liệu lớp học và sinh viên có phân trang
create or replace function get_all_classe_students_paging(page int, items int)
returns table(ma_lop varchar(20),ten_lop varchar(100),ma_sv varchar(20),ho_ten varchar(100),
email varchar(150), gioi_tinh varchar(10),que_quan varchar(100),ngay_sinh date) as $$
begin
	return query
	select lh.ma_lop,lh.ten_lop,sv.ma_sv,sv.ho_ten,sv.email,sv.gioi_tinh,sv.que_quan,sv.ngay_sinh
	from lophoc lh join sinhvien sv on lh.id = sv.lop_id 
	order by sv.ma_sv asc limit items offset (page-1)*items;
end; $$ language plpgsql;

-- Gọi hàm
select * from get_all_classe_students_paging(1,5);

-- Hàm lấy theo id
create or replace function get_all_classes_students_by_id(p_ma_lop varchar(20))
returns table(ma_lop varchar(20),ten_lop varchar(100),ma_sv varchar(20),ho_ten varchar(100),
email varchar(150), gioi_tinh varchar(10),que_quan varchar(100),ngay_sinh date) as $$
begin
	return query
	select lh.ma_lop,lh.ten_lop,sv.ma_sv,sv.ho_ten,sv.email,sv.gioi_tinh,sv.que_quan,sv.ngay_sinh
	from lophoc lh join sinhvien sv on lh.id = sv.lop_id
	where lh.ma_lop = p_ma_lop;
end; $$ language plpgsql;

-- call
select * from get_all_classes_students_by_id('CTK42');

-- Hàm lấy dữ liệu theo tên có phân trang
create or replace function get_all_classes_students_by_name_paging(class_name varchar(100),page int, items int)
returns table(ma_lop varchar(20),ten_lop varchar(100),ma_sv varchar(20),ho_ten varchar(100),
email varchar(150), gioi_tinh varchar(10),que_quan varchar(100),ngay_sinh date) as $$
begin
	declare
	return query
	select lh.ma_lop,lh.ten_lop,sv.ma_sv,sv.ho_ten,sv.email,sv.gioi_tinh,sv.que_quan,sv.ngay_sinh
	from lophoc lh join sinhvien sv on lh.id = sv.lop_id 
	where lh.ten_lop like concat('%',class_name,'%')
	order by sv.ma_sv asc limit items offset (page-1)*items;
end; $$ language plpgsql;

-- Gọi hàm
select * from get_all_classes_students_by_name_paging('Công',1,7);

select * from lophoc;

-- Tạo trigger để ghi log cho các hành động thêm, sửa, xoá dl với bảng bangdiem
-- Tạo bảng để ghi log
create table db_log(id serial primary key,
table_names varchar(100), action_name varchar(20), times timestamp default now());

--1. Tạo trigger function
create or replace function f_trigger_log_bangdiem()
returns trigger as $$
begin
	if tg_op = 'INSERT' then
		insert into db_log(table_names,action_name) values ('bangdiem','insert');
	elseif tg_op = 'UPDATE' then
		insert into db_log(table_names,action_name) values ('bangdiem','update');
	elseif tg_op = 'DELETE' then
		insert into db_log(table_names,action_name) values ('bangdiem','delete');
	end if;
	return null;
end; $$ language plpgsql;

-- Tạo trigger cho các hành động của bảng bangdiem
create or replace trigger tg_bangdiem
after insert or update or delete on bangdiem
for each row
execute function f_trigger_log_bangdiem();

-- Test
select * from bangdiem;

insert into bangdiem(sinh_vien_id,mon_hoc_id,diem_so,hoc_ky) values 
(4,3,7,'HK2');

select * from db_log;

delete from bangdiem where id = 24;

-- Cài đặt trigger không cho xoá các môn có điểm >=8
create function f_trigger_delete()
returns trigger as $$
begin
	if old.diem_so>=8 then
		raise exception 'Không được xoá kết quả với điểm số >=8';
	end if;
	return old;
end; $$ language plpgsql;

-- Tạo trigger
create or replace trigger tg_delete_bangdiem
before delete on bangdiem
for each row
execute function f_trigger_delete();

select * from bangdiem;

-- Test
delete from bangdiem where id = 18;

-- Demo trigger for xuatsac2:
create table products(
id serial primary key,
name varchar(100) not null,
stock int default 0 check(stock>=0)
);

create type order_status_type as enum('PENDING','CONFIRMED','DELIVERING','SUCCESS');

create table orders(
	id serial primary key,
	product_id int references products(id),
	quantity int check(quantity>0),
	order_status order_status_type default 'PENDING'
)

-- Sửa lỗi: Thêm từ khóa FUNCTION và viết logic xử lý
CREATE OR REPLACE FUNCTION f_update_order()
RETURNS TRIGGER AS $$
DECLARE
    delta int;
    current_stock int;
BEGIN
    -- Tính phần chênh lệch: Mới - Cũ
    -- Ví dụ: Cũ mua 2, Mới sửa thành 5 => delta = 3 (cần trừ thêm 3 trong kho)
    -- Ví dụ: Cũ mua 5, Mới sửa thành 2 => delta = -3 (trừ đi -3 là cộng lại 3 vào kho)
    delta := NEW.quantity - OLD.quantity;
    
    -- Nếu số lượng không đổi thì không làm gì cả
    IF delta = 0 THEN
        RETURN NEW;
    END IF;

    -- Lấy tồn kho hiện tại để kiểm tra
    SELECT stock INTO current_stock FROM products WHERE id = NEW.product_id;

    -- Nếu mua thêm (delta > 0) mà kho không đủ
    IF delta > 0 AND current_stock < delta THEN
        RAISE EXCEPTION 'Số lượng cập nhật vượt quá tồn kho hiện tại (còn %)', current_stock;
    END IF;

    -- Cập nhật kho
    UPDATE products 
    SET stock = stock - delta
    WHERE id = NEW.product_id;

    RETURN NEW;
END; $$ LANGUAGE plpgsql;

--
CREATE OR REPLACE TRIGGER tg_update_order
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION f_update_order();

-- test
insert into products(name,stock) values 
('Máy tính',10),
('Tủ lạnh',20),
('Tivi',50);

select * from products;
select * from orders;

insert into orders(product_id,quantity) values (1,2);

-- Khi chỉnh sửa đơn hàng: điều chỉnh tồn kho theo sự thay đổi số lượng
create or replace f_update_order()
returns trigger as $$
begin
	
end; $$ language plpgsql;