-- ecommerce_schema.sql
-- MySQL schema for a simple but complete E-commerce Store
-- Includes: customers (one-to-one with profiles), addresses, products, categories,
-- product_categories (many-to-many), suppliers (many-to-many with products),
-- inventory, orders, order_items, payments, coupons, product_reviews.
-- Uses InnoDB for referential integrity.

-- 1) Create database
CREATE DATABASE IF NOT EXISTS ecommerce_store
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE ecommerce_store;

-- 2) Enable strict mode recommended settings if not already (optional)
-- SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_IN_DATE,NO_ZERO_DATE';

-- 3) Customers and one-to-one profiles
CREATE TABLE customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash CHAR(60) NOT NULL,
  phone VARCHAR(30),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customer_profiles (
  customer_id BIGINT UNSIGNED PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100),
  date_of_birth DATE,
  gender ENUM('male','female','other') DEFAULT NULL,
  bio TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4) Addresses (one customer can have many addresses)
CREATE TABLE addresses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(50) DEFAULT 'home', -- e.g., home, work
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX (customer_id),
  INDEX (country)
) ENGINE=InnoDB;

-- 5) Categories (hierarchy via parent_id)
CREATE TABLE categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  slug VARCHAR(150) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT UNSIGNED DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6) Suppliers
CREATE TABLE suppliers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  contact_email VARCHAR(255),
  contact_phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 7) Products
CREATE TABLE products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  short_description VARCHAR(512),
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  weight_kg DECIMAL(6,3) DEFAULT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 8) Many-to-many: products <-> categories
CREATE TABLE product_categories (
  product_id BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, category_id),
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 9) Many-to-many: products <-> suppliers (with supplier SKU and lead time)
CREATE TABLE product_suppliers (
  product_id BIGINT UNSIGNED NOT NULL,
  supplier_id INT UNSIGNED NOT NULL,
  supplier_sku VARCHAR(200),
  lead_time_days INT UNSIGNED DEFAULT 0,
  cost_price DECIMAL(10,2) DEFAULT NULL CHECK (cost_price >= 0),
  PRIMARY KEY (product_id, supplier_id),
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 10) Inventory table (tracks stock per product / location)
CREATE TABLE inventory (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  location VARCHAR(100) NOT NULL DEFAULT 'main_warehouse',
  quantity INT NOT NULL DEFAULT 0,
  reserved INT NOT NULL DEFAULT 0, -- quantity reserved for orders
  last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY product_location_unique (product_id, location),
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 11) Coupons / discounts
CREATE TABLE coupons (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  discount_type ENUM('percent','fixed') NOT NULL,
  discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
  min_order_total DECIMAL(10,2) DEFAULT 0 CHECK (min_order_total >= 0),
  valid_from DATETIME DEFAULT NULL,
  valid_until DATETIME DEFAULT NULL,
  usage_limit INT UNSIGNED DEFAULT NULL, -- null = unlimited
  used_count INT UNSIGNED NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 12) Orders (one-to-many: customer -> orders). One-to-one-ish: order -> payment (not strictly enforced here).
CREATE TABLE orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id BIGINT UNSIGNED NOT NULL,
  billing_address_id BIGINT UNSIGNED,
  shipping_address_id BIGINT UNSIGNED,
  status ENUM('pending','paid','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  shipping_cost DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  coupon_id INT UNSIGNED DEFAULT NULL,
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (coupon_id) REFERENCES coupons(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX (customer_id),
  INDEX (order_number)
) ENGINE=InnoDB;

-- 13) Order items (one-to-many: order -> order_items)
CREATE TABLE order_items (
  order_id BIGINT UNSIGNED NOT NULL,
  item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  sku VARCHAR(100),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  PRIMARY KEY (order_id, item_id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  INDEX (product_id)
) ENGINE=InnoDB;

-- 14) Payments (one order can have multiple payment attempts / records)
CREATE TABLE payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(100) NOT NULL, -- e.g., stripe, paypal, mpesa
  provider_payment_id VARCHAR(255),
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  paid_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX (order_id),
  INDEX (provider_payment_id)
) ENGINE=InnoDB;

-- 15) Product reviews (customer can review product) - one-to-many
CREATE TABLE product_reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED DEFAULT NULL,
  rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(200),
  body TEXT,
  approved TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX (product_id),
  INDEX (customer_id)
) ENGINE=InnoDB;

-- 16) Purchase orders (to supplier) - for restocking (optional)
CREATE TABLE purchase_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  po_number VARCHAR(50) NOT NULL UNIQUE,
  supplier_id INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expected_delivery DATE,
  status ENUM('draft','placed','received','cancelled') NOT NULL DEFAULT 'draft',
  total_cost DECIMAL(12,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  INDEX (supplier_id)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_items (
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  unit_cost DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0),
  PRIMARY KEY (purchase_order_id, item_id),
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 17) Audit / stock movements (simple log)
CREATE TABLE stock_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  movement_type ENUM('in','out','reserved','unreserved','adjustment') NOT NULL,
  quantity INT NOT NULL,
  location VARCHAR(100) NOT NULL DEFAULT 'main_warehouse',
  reference VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX (product_id),
  INDEX (movement_type)
) ENGINE=InnoDB;

