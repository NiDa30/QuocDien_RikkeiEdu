-- Tạo database EcommerceDB
CREATE DATABASE "EcommerceDB";

-- Tạo schema shop
CREATE SCHEMA IF NOT EXISTS shop;

-- tạo table users
CREATE TABLE shop."Users" (
    user_id   SERIAL PRIMARY KEY,
    username  VARCHAR(50)  NOT NULL UNIQUE,
    email     VARCHAR(100) NOT NULL UNIQUE,
    password  VARCHAR(100) NOT NULL,
    role      VARCHAR(20)
        CHECK (role IN ('Customer','Admin'))
);

-- tạo table categories
CREATE TABLE shop."Categories" (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- tạo table products
CREATE TABLE shop."Products" (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price        NUMERIC(10,2) CHECK (price > 0),
    stock        INT          CHECK (stock >= 0),
    category_id  INT          NOT NULL,
    CONSTRAINT fk_products_categories
        FOREIGN KEY (category_id)
        REFERENCES shop."Categories" (category_id)
);

-- tạo table orders
CREATE TABLE shop."Orders" (
    order_id   SERIAL PRIMARY KEY,
    user_id    INT NOT NULL,
    order_date DATE NOT NULL,
    status     VARCHAR(20)
        CHECK (status IN ('Pending','Shipped','Delivered','Cancelled')),
    CONSTRAINT fk_orders_users
        FOREIGN KEY (user_id)
        REFERENCES shop."Users" (user_id)
);

-- tạo table orderDetails
CREATE TABLE shop."OrderDetails" (
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT         CHECK (quantity > 0),
    price_each      NUMERIC(10,2) CHECK (price_each > 0),
    CONSTRAINT fk_orderdetails_orders
        FOREIGN KEY (order_id)
        REFERENCES shop."Orders" (order_id),
    CONSTRAINT fk_orderdetails_products
        FOREIGN KEY (product_id)
        REFERENCES shop."Products" (product_id)
);

-- tạo table payments
CREATE TABLE shop."Payments" (
    payment_id   SERIAL PRIMARY KEY,
    order_id     INT NOT NULL,
    amount       NUMERIC(10,2) CHECK (amount >= 0),
    payment_date DATE NOT NULL,
    method       VARCHAR(30)
        CHECK (method IN ('Credit Card','Momo','Bank Transfer','Cash')),
    CONSTRAINT fk_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES shop."Orders" (order_id)
);
