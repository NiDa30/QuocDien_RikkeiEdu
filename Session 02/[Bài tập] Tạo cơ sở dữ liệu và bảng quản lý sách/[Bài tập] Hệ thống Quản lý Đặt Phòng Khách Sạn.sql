-- Tạo database HotelDB 
CREATE DATABASE "HotelDB";

-- Tạo schema hotel
CREATE SCHEMA IF NOT EXISTS hotel;

-- tạo table roomtypes
CREATE TABLE hotel.RoomTypes (
    room_type_id    SERIAL PRIMARY KEY,
    type_name       VARCHAR(50) NOT NULL UNIQUE,
    price_per_night NUMERIC(10,2) CHECK (price_per_night > 0),
    max_capacity    INT CHECK (max_capacity > 0)
);

--tạo table rooms
CREATE TABLE hotel."Rooms" (
    room_id      SERIAL PRIMARY KEY,
    room_number  VARCHAR(10) NOT NULL UNIQUE,
    room_type_id INT NOT NULL,
    status       VARCHAR(20)
        CHECK (status IN ('Available','Occupied','Maintenance')),
    CONSTRAINT fk_rooms_roomtypes
        FOREIGN KEY (room_type_id)
        REFERENCES hotel."RoomTypes" (room_type_id)
);

-- tạo table customers
CREATE TABLE hotel."Customers" (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    phone       VARCHAR(15)  NOT NULL
);

-- tạo table bookings
CREATE TABLE hotel.Bookings (
    booking_id  SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    room_id     INT NOT NULL,
    check_in    DATE NOT NULL,
    check_out   DATE NOT NULL,
    status      VARCHAR(20)
        CHECK (status IN ('Pending','Confirmed','Cancelled')),
    CONSTRAINT fk_bookings_customers
        FOREIGN KEY (customer_id)
        REFERENCES hotel."Customers" (customer_id),
    CONSTRAINT fk_bookings_rooms
        FOREIGN KEY (room_id)
        REFERENCES hotel."Rooms" (room_id),
);

-- tạo table payment
CREATE TABLE hotel."Payments" (
    payment_id   SERIAL PRIMARY KEY,
    booking_id   INT NOT NULL,
    amount       NUMERIC(10,2) CHECK (amount >= 0),
    payment_date DATE NOT NULL,
    method       VARCHAR(20)
        CHECK (method IN ('Credit Card','Cash','Bank Transfer')),
    CONSTRAINT fk_payments_bookings
        FOREIGN KEY (booking_id)
        REFERENCES hotel."Bookings" (booking_id)
);

