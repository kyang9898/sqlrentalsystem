DROP DATABASE IF EXISTS `rental_db`;
CREATE DATABASE `rental_db`;
USE `rental_db`;
 
-- Create `vehicles` table
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE `vehicles` (
   `veh_reg_no`  VARCHAR(8)    NOT NULL,
   `category`    ENUM('car', 'truck')  NOT NULL DEFAULT 'car',  
                 -- Enumeration of one of the items in the list
   `brand`       VARCHAR(30)   NOT NULL DEFAULT '',
   `desc`        VARCHAR(256)  NOT NULL DEFAULT '',
                 -- desc is a keyword (for descending) and must be back-quoted
   `photo`       BLOB          NULL,   -- binary large object of up to 64KB
                 -- to be implemented later
   `daily_rate`  DECIMAL(6,2)  NOT NULL DEFAULT 9999.99,
                 -- set default to max value
   PRIMARY KEY (`veh_reg_no`),
   INDEX (`category`)  -- Build index on this column for fast search
) ENGINE=InnoDB;
   -- MySQL provides a few ENGINEs.
   -- The InnoDB Engine supports foreign keys and transactions
DESC `vehicles`;
SHOW CREATE TABLE `vehicles`;
SHOW INDEX FROM `vehicles`;
 
-- Create `customers` table
DROP TABLE IF EXISTS `customers`;
CREATE TABLE `customers` (
   `customer_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                  -- Always use INT for AUTO_INCREMENT column to avoid run-over
   `name`         VARCHAR(30)   NOT NULL DEFAULT '',
   `address`      VARCHAR(80)   NOT NULL DEFAULT '',
   `phone`        VARCHAR(15)   NOT NULL DEFAULT '',
   `discount`     DOUBLE        NOT NULL DEFAULT 0.0,
   PRIMARY KEY (`customer_id`),
   UNIQUE INDEX (`phone`),  -- Build index on this unique-value column
   INDEX (`name`)           -- Build index on this column
) ENGINE=InnoDB;
DESC `customers`;
SHOW CREATE TABLE `customers`;
SHOW INDEX FROM `customers`;
 
-- Create `rental_records` table
DROP TABLE IF EXISTS `rental_records`;
CREATE TABLE `rental_records` (
   `rental_id`    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
   `veh_reg_no`   VARCHAR(8)    NOT NULL, 
   `customer_id`  INT UNSIGNED  NOT NULL,
   `start_date`   DATE          NOT NULL DEFAULT('0000-00-00'),
   `end_date`     DATE          NOT NULL DEFAULT('0000-00-00'),
   `lastUpdated`  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      -- Keep the created and last updated timestamp for auditing and security
   PRIMARY KEY (`rental_id`),
   FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`)
      ON DELETE RESTRICT ON UPDATE CASCADE,
      -- Disallow deletion of parent record if there are matching records here
      -- If parent record (customer_id) changes, update the matching records here
   FOREIGN KEY (`veh_reg_no`) REFERENCES `vehicles` (`veh_reg_no`)
      ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
DESC `rental_records`;
SHOW CREATE TABLE `rental_records`;
SHOW INDEX FROM `rental_records`;

-- Inserting test records
INSERT INTO `vehicles` VALUES
   ('SBA1111A', 'car', 'NISSAN SUNNY 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBB2222B', 'car', 'TOYOTA ALTIS 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBC3333C', 'car', 'HONDA CIVIC 1.8L',  '4 Door Saloon, Automatic', NULL, 119.99),
   ('GA5555E', 'truck', 'NISSAN CABSTAR 3.0L',  'Lorry, Manual ', NULL, 89.99),
   ('GA6666F', 'truck', 'OPEL COMBO 1.6L',  'Van, Manual', NULL, 69.99);
   -- No photo yet, set to NULL
SELECT * FROM `vehicles`;
 
INSERT INTO `customers` VALUES
   (1001, 'Angel', '8 Happy Ave', '88888888', 0.1),
   (NULL, 'Mohammed Ali', '1 Kg Java', '99999999', 0.15),
   (NULL, 'Kumar', '5 Serangoon Road', '55555555', 0),
   (NULL, 'Kevin Jones', '2 Sunset boulevard', '22222222', 0.2);
SELECT * FROM `customers`;
 
INSERT INTO `rental_records` VALUES
  (NULL, 'SBA1111A', 1001, '2012-01-01', '2012-01-21', NULL),
  (NULL, 'SBA1111A', 1001, '2012-02-01', '2012-02-05', NULL),
  (NULL, 'GA5555E',  1003, '2012-01-05', '2012-01-31', NULL),
  (NULL, 'GA6666F',  1004, '2012-01-20', '2012-02-20', NULL);
SELECT * FROM `rental_records`;

-- Q1
INSERT INTO rental_records (veh_reg_no, customer_id, start_date, end_date)
SELECT 'SBA1111A', customer_id, curdate(), date_add(curdate(), interval 10 day)
FROM customers
WHERE name = 'Angel';
-- Q2
INSERT INTO rental_records (veh_reg_no, customer_id, start_date, end_date)
SELECT 'GA5555E', customer_id, curdate(), date_add(curdate(), interval 3 month)
FROM customers
WHERE name = 'Angel'
-- Q3
SELECT start_date, end_date, rental_records.veh_reg_no, brand, name FROM rental_records
INNER JOIN customers using (customer_id)
INNER JOIN vehicles using (veh_reg_no)
order by category, start_date;
-- Q4
SELECT * FROM rental_records
WHERE end_date < curdate();
-- Q5
SELECT veh_reg_no, name, start_date, end_date FROM rental_records
INNER JOIN customers using (customer_id)
WHERE start_date < '2012-01-10' AND end_date > '2012-01-10';
-- Q6
SELECT veh_reg_no, name, start_date, end_date
FROM rental_records JOIN customers using (customer_id)
WHERE start_date <= curdate();
-- Q7
SELECT veh_reg_no, name, start_date, end_date
FROM rental_records JOIN customers using (customer_id)
WHERE (start_date BETWEEN '2012-01-03' AND '2012-01-18') OR 
(end_date BETWEEN '2012-01-03' AND '2012-01-18') OR
(start_date < '2012-01-03' AND end_date > '2012-01-18')
-- Q8
SELECT veh_reg_no, brand, vehicles.desc FROM vehicles
FROM vehicles WHERE NOT veh_reg_no IN (SELECT veh_reg_no FROM rental_records
WHERE '2012-01-10' BETWEEN start_date AND end_date);
-- Q9
SELECT veh_reg_no, brand, vehicles.desc FROM vehicles WHERE NOT veh_reg_no IN (
    SELECT veh_reg_no FROM rental_records WHERE (start_date BETWEEN '2012-01-03' AND '2012-01-18') OR
    (end_date BETWEEN '2012-01-03' AND '2012-01-18') OR 
    (start_date < '2012-01-03' AND end_date > '2012-01-18'));
-- Q10
SELECT veh_reg_no, brand, vehicles.desc FROM vehicles
WHERE veh_reg_no NOT IN (
    SELECT veh_reg_no FROM rental_records WHERE (
        start_date BETWEEN curdate() and date_add(curdate(), interval 10 day)) OR
        (end_date BETWEEN curdate() and date_add(curdate(), interval 10 day)) OR
        (start_date < curdate() and end_date > date_add(curdate(), interval 10 day))
);