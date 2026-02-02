CREATE TABLE Sale(
	sale_id SERIAL PRIMARY KEY,
	customer_id INTEGER NOT NULL,
	amount DECIMAL(10,2) NOT NULL,
	sale_date DATE NOT NULL

);

CREATE OR REPLACE PROCEDURE calculate_total_sales(
	start_date DATE,
	end_date DATE,
	OUT total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
	SELECT COAL.ESCE(SUM(amount),0) INTO total
	FROM Sales
	WHERE sale_date BETWEEN start_date AND end_date;
	
	RAISE NOTICE 'tổng doanh thu từ % đến %: %', 
			start_date, end_date, total;
END;
$$;

-- gọi procedure 1
CALL calculate_total_sales('2026-01-01', '2026-01-31', NULL);

--2
DO $$
DECLARE 
	doanh_thu NUMERIC;
BEGIN
	CALL calculate_total_sales('2026-01-01', '2026-01-31', doanh_thu);
	RAISE NOTICE 'doanh thu tháng 1/2026: %VND' doanh_thu;
END
$$;