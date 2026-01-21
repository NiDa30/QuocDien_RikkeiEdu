--1. tạo DB
CREATE DATABASE SalesDB;
--2.tạo schema sales
CREATE SCHEMA sales;
--3. tạo table customers
CREATE TABLE sales.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20)
);
--4.tạo table products
CREATE TABLE sales.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price NUMERIC NOT NULL,
    stock_quantity INT NOT NULL
);
--5. tạo table orders
CREATE TABLE sales.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES sales.customers(customer_id)
);
--6. tạo table orderItems
CREATE TABLE sales.orderitems (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 1),
    CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id)
        REFERENCES sales.orders(order_id),
    CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id)
        REFERENCES sales.products(product_id)
);

