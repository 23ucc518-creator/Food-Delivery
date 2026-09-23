/*

These tables represent the cleaned, analytical layer used for
transactional analysis, seller performance, customer behavior,
and revenue reporting.

*/
create table customers(
customer_id INT PRIMARY KEY,
customer_name VARCHAR(25) NOT NULL,
reg_date DATE
);

create table restaurants(
restaurant_id INT PRIMARY KEY,
restaurant_name VARCHAR(25) NOT NULL,
city VARCHAR(25),
opening_hour VARCHAR(50)
);

create table riders(
rider_id INT PRIMARY KEY,
rider_name VARCHAR(25) NOT NULL,
sign_up DATE
);

create table orders(
order_id INT PRIMARY KEY,
customer_id INT,
restaurant_id INT,
order_item VARCHAR(25),
order_date DATE NOT NULL,
order_time TIME NOT NULL,
order_status VARCHAR(25) DEFAULT 'Pending',
total_amount DECIMAL(10,2) NOT NULL,
FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

create table deliveries(
delivery_id INT PRIMARY KEY,
order_id INT,
delivery_status VARCHAR(25) DEFAULT 'Pending',
delivery_time TIME,
rider_id INT,
FOREIGN KEY (order_id) REFERENCES orders(order_id),
FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
)
