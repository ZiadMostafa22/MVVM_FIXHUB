-- ============================================
-- FIX-HUB DATABASE - MySQL Schema
-- Car Maintenance Management System
-- ============================================
-- Version: 1.0
-- Created: December 2024
-- ============================================

-- Create Database
CREATE DATABASE IF NOT EXISTS fixhub_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE fixhub_db;

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,                          -- Firebase UID or UUID
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role ENUM('customer', 'technician', 'admin', 'cashier') NOT NULL DEFAULT 'customer',
    profile_image_url VARCHAR(500) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    preferences JSON NULL,                               -- User preferences as JSON
    invite_code_id VARCHAR(36) NULL,                     -- FK to invite_codes
    invite_code VARCHAR(20) NULL,                        -- The actual code used
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_is_active (is_active),
    INDEX idx_users_invite_code_id (invite_code_id)
) ENGINE=InnoDB;

-- ============================================
-- 2. INVITE CODES TABLE
-- ============================================
CREATE TABLE invite_codes (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,                    -- 8-character unique code
    role ENUM('technician', 'cashier', 'admin') NOT NULL,
    max_uses INT NOT NULL DEFAULT 1,
    used_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(36) NOT NULL,                     -- FK to users (admin)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_invite_codes_code (code),
    INDEX idx_invite_codes_is_active (is_active),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Add FK constraint to users table after invite_codes is created
ALTER TABLE users
ADD CONSTRAINT fk_users_invite_code
FOREIGN KEY (invite_code_id) REFERENCES invite_codes(id) ON DELETE SET NULL;

-- ============================================
-- 3. INVITE CODE USAGE TABLE (Many-to-Many)
-- ============================================
CREATE TABLE invite_code_usage (
    id VARCHAR(36) PRIMARY KEY,
    invite_code_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_invite_user (invite_code_id, user_id),
    FOREIGN KEY (invite_code_id) REFERENCES invite_codes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 4. CARS TABLE
-- ============================================
CREATE TABLE cars (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,                        -- FK to users (owner)
    make VARCHAR(50) NOT NULL,                           -- Toyota, Honda, etc.
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    license_plate VARCHAR(20) NOT NULL,
    type ENUM('sedan', 'suv', 'hatchback', 'coupe', 'convertible', 'truck', 'van') NOT NULL DEFAULT 'sedan',
    vin VARCHAR(50) NULL,                                -- Vehicle Identification Number
    engine_type VARCHAR(50) NULL,
    mileage INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_cars_user_id (user_id),
    INDEX idx_cars_license_plate (license_plate),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 5. CAR IMAGES TABLE (One-to-Many)
-- ============================================
CREATE TABLE car_images (
    id VARCHAR(36) PRIMARY KEY,
    car_id VARCHAR(36) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_car_images_car_id (car_id),
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 6. SERVICES CATALOG TABLE
-- ============================================
CREATE TABLE services (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('part', 'labor', 'service') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT NULL,
    category VARCHAR(50) NULL,                           -- Oil Change, Brake Service, etc.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_services_type (type),
    INDEX idx_services_category (category),
    INDEX idx_services_is_active (is_active)
) ENGINE=InnoDB;

-- ============================================
-- 7. OFFERS TABLE
-- ============================================
CREATE TABLE offers (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    type ENUM('announcement', 'discount', 'promotion', 'news') NOT NULL,
    image_url VARCHAR(500) NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(36) NOT NULL,                     -- FK to users (admin)
    discount_percentage INT NULL CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    code VARCHAR(50) NULL UNIQUE,                        -- Offer code
    terms TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_offers_is_active (is_active),
    INDEX idx_offers_code (code),
    INDEX idx_offers_dates (start_date, end_date),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 8. BOOKINGS TABLE
-- ============================================
CREATE TABLE bookings (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,                        -- FK to users (customer)
    car_id VARCHAR(36) NOT NULL,                         -- FK to cars
    service_id VARCHAR(36) NULL,                         -- FK to services
    maintenance_type ENUM('regular', 'repair', 'inspection', 'emergency') NOT NULL,
    scheduled_date DATE NOT NULL,
    time_slot VARCHAR(50) NOT NULL,                      -- e.g., "09:00 AM - 10:00 AM"
    status ENUM('pending', 'confirmed', 'inProgress', 'completedPendingPayment', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    description TEXT NULL,
    notes TEXT NULL,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,                           -- When technician started
    completed_at TIMESTAMP NULL,                         -- When service completed
    
    -- Service/Invoice Details
    labor_cost DECIMAL(10, 2) NULL DEFAULT 0.00,
    tax DECIMAL(10, 2) NULL,
    total_cost DECIMAL(10, 2) NULL,                      -- Saved on payment
    technician_notes TEXT NULL,
    
    -- Discount/Offer
    offer_code VARCHAR(50) NULL,
    offer_title VARCHAR(200) NULL,
    discount_percentage INT NULL DEFAULT 0,
    
    -- Rating
    rating DECIMAL(2, 1) NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    rating_comment TEXT NULL,
    rated_at TIMESTAMP NULL,
    
    -- Payment
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    paid_at TIMESTAMP NULL,
    cashier_id VARCHAR(36) NULL,                         -- FK to users (cashier)
    payment_method ENUM('cash', 'card', 'digital') NULL,
    
    INDEX idx_bookings_user_id (user_id),
    INDEX idx_bookings_car_id (car_id),
    INDEX idx_bookings_status (status),
    INDEX idx_bookings_scheduled_date (scheduled_date),
    INDEX idx_bookings_is_paid (is_paid),
    INDEX idx_bookings_cashier_id (cashier_id),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    FOREIGN KEY (cashier_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- 9. BOOKING TECHNICIANS TABLE (Many-to-Many)
-- ============================================
CREATE TABLE booking_technicians (
    id VARCHAR(36) PRIMARY KEY,
    booking_id VARCHAR(36) NOT NULL,
    technician_id VARCHAR(36) NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_booking_technician (booking_id, technician_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 10. BOOKING SERVICE ITEMS TABLE (One-to-Many)
-- ============================================
CREATE TABLE booking_service_items (
    id VARCHAR(36) PRIMARY KEY,
    booking_id VARCHAR(36) NOT NULL,
    service_id VARCHAR(36) NULL,                         -- FK to services (optional)
    name VARCHAR(100) NOT NULL,
    type ENUM('part', 'labor', 'service') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    description TEXT NULL,
    category VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_booking_items_booking_id (booking_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- 11. REFUNDS TABLE
-- ============================================
CREATE TABLE refunds (
    id VARCHAR(36) PRIMARY KEY,
    booking_id VARCHAR(36) NOT NULL,                     -- FK to bookings
    original_amount DECIMAL(10, 2) NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    customer_notes TEXT NULL,
    status ENUM('requested', 'approved', 'rejected', 'processed') NOT NULL DEFAULT 'requested',
    requested_by VARCHAR(36) NOT NULL,                   -- FK to users (cashier)
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by VARCHAR(36) NULL,                        -- FK to users (admin)
    approved_at TIMESTAMP NULL,
    processed_at TIMESTAMP NULL,
    original_payment_method VARCHAR(50) NULL,
    refund_method VARCHAR(50) NULL,
    
    INDEX idx_refunds_booking_id (booking_id),
    INDEX idx_refunds_status (status),
    INDEX idx_refunds_requested_by (requested_by),
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE RESTRICT,
    FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- 12. INVENTORY TABLE
-- ============================================
CREATE TABLE inventory (
    id VARCHAR(36) PRIMARY KEY,
    service_item_id VARCHAR(36) NULL,                    -- FK to services
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,                     -- Stock Keeping Unit
    category ENUM('parts', 'supplies', 'tools') NOT NULL,
    current_stock INT NOT NULL DEFAULT 0,
    low_stock_threshold INT NOT NULL DEFAULT 10,
    reorder_point INT NOT NULL DEFAULT 15,
    unit_cost DECIMAL(10, 2) NOT NULL,                   -- Purchase price
    unit_price DECIMAL(10, 2) NOT NULL,                  -- Selling price
    location VARCHAR(100) NULL,
    supplier VARCHAR(100) NULL,
    supplier_contact VARCHAR(100) NULL,
    last_restocked TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_inventory_sku (sku),
    INDEX idx_inventory_category (category),
    INDEX idx_inventory_current_stock (current_stock),
    INDEX idx_inventory_is_active (is_active),
    
    FOREIGN KEY (service_item_id) REFERENCES services(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- 13. INVENTORY TRANSACTIONS TABLE
-- ============================================
CREATE TABLE inventory_transactions (
    id VARCHAR(36) PRIMARY KEY,
    inventory_item_id VARCHAR(36) NOT NULL,              -- FK to inventory
    type ENUM('in', 'out', 'adjustment') NOT NULL,       -- in=restock, out=usage
    quantity INT NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    booking_id VARCHAR(36) NULL,                         -- FK to bookings (for usage)
    technician_id VARCHAR(36) NULL,                      -- FK to users
    reason VARCHAR(200) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NOT NULL,                     -- FK to users
    
    INDEX idx_inv_trans_item_id (inventory_item_id),
    INDEX idx_inv_trans_type (type),
    INDEX idx_inv_trans_created_at (created_at),
    
    FOREIGN KEY (inventory_item_id) REFERENCES inventory(id) ON DELETE RESTRICT,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 14. LOW STOCK ALERTS TABLE
-- ============================================
CREATE TABLE low_stock_alerts (
    id VARCHAR(36) PRIMARY KEY,
    inventory_item_id VARCHAR(36) NOT NULL,              -- FK to inventory
    current_stock INT NOT NULL,
    threshold INT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_alerts_item_id (inventory_item_id),
    INDEX idx_alerts_is_resolved (is_resolved),
    
    FOREIGN KEY (inventory_item_id) REFERENCES inventory(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 15. USER NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE user_notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,                        -- FK to users
    type ENUM('push', 'inApp') NOT NULL DEFAULT 'inApp',
    category ENUM('booking', 'payment', 'reminder', 'system') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    booking_id VARCHAR(36) NULL,                         -- FK to bookings
    car_id VARCHAR(36) NULL,                             -- FK to cars
    metadata JSON NULL,
    
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_is_read (is_read),
    INDEX idx_notifications_sent_at (sent_at),
    INDEX idx_notifications_category (category),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- VIEWS
-- ============================================

-- View: Active Bookings with Customer and Car Info
CREATE VIEW v_active_bookings AS
SELECT 
    b.id,
    b.scheduled_date,
    b.time_slot,
    b.status,
    b.maintenance_type,
    b.is_paid,
    b.total_cost,
    u.name AS customer_name,
    u.phone AS customer_phone,
    c.make,
    c.model,
    c.year,
    c.license_plate,
    CONCAT(c.year, ' ', c.make, ' ', c.model) AS car_display_name
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN cars c ON b.car_id = c.id
WHERE b.status NOT IN ('completed', 'cancelled');

-- View: Daily Revenue Report
CREATE VIEW v_daily_revenue AS
SELECT 
    DATE(paid_at) AS payment_date,
    COUNT(*) AS transaction_count,
    SUM(total_cost) AS total_revenue,
    SUM(labor_cost) AS total_labor,
    SUM(CASE WHEN payment_method = 'cash' THEN total_cost ELSE 0 END) AS cash_total,
    SUM(CASE WHEN payment_method = 'card' THEN total_cost ELSE 0 END) AS card_total,
    SUM(CASE WHEN payment_method = 'digital' THEN total_cost ELSE 0 END) AS digital_total
FROM bookings
WHERE is_paid = TRUE AND paid_at IS NOT NULL
GROUP BY DATE(paid_at)
ORDER BY payment_date DESC;

-- View: Low Stock Items
CREATE VIEW v_low_stock_items AS
SELECT 
    i.id,
    i.name,
    i.sku,
    i.category,
    i.current_stock,
    i.low_stock_threshold,
    i.reorder_point,
    i.unit_cost,
    i.unit_price,
    i.supplier
FROM inventory i
WHERE i.current_stock <= i.low_stock_threshold
  AND i.is_active = TRUE;

-- View: Pending Refunds
CREATE VIEW v_pending_refunds AS
SELECT 
    r.id,
    r.booking_id,
    r.refund_amount,
    r.reason,
    r.status,
    r.requested_at,
    req.name AS requested_by_name,
    b.total_cost AS original_booking_total,
    cust.name AS customer_name
FROM refunds r
JOIN users req ON r.requested_by = req.id
JOIN bookings b ON r.booking_id = b.id
JOIN users cust ON b.user_id = cust.id
WHERE r.status IN ('requested', 'approved');

-- ============================================
-- TRIGGERS
-- ============================================

DELIMITER //

-- Trigger: Update invite code usage count
CREATE TRIGGER tr_invite_code_usage_insert
AFTER INSERT ON invite_code_usage
FOR EACH ROW
BEGIN
    UPDATE invite_codes 
    SET used_count = used_count + 1 
    WHERE id = NEW.invite_code_id;
END//

-- Trigger: Create low stock alert when inventory drops
CREATE TRIGGER tr_inventory_low_stock_alert
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.current_stock <= NEW.low_stock_threshold 
       AND OLD.current_stock > OLD.low_stock_threshold THEN
        INSERT INTO low_stock_alerts (id, inventory_item_id, current_stock, threshold)
        VALUES (UUID(), NEW.id, NEW.current_stock, NEW.low_stock_threshold);
    END IF;
END//

-- Trigger: Auto-resolve low stock alert when restocked
CREATE TRIGGER tr_inventory_resolve_alert
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.current_stock > NEW.low_stock_threshold 
       AND OLD.current_stock <= OLD.low_stock_threshold THEN
        UPDATE low_stock_alerts 
        SET is_resolved = TRUE, resolved_at = CURRENT_TIMESTAMP
        WHERE inventory_item_id = NEW.id AND is_resolved = FALSE;
    END IF;
END//

DELIMITER ;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert Admin User
INSERT INTO users (id, email, name, phone, role, is_active) VALUES
('admin-001', 'admin@fixhub.com', 'System Administrator', '+201234567890', 'admin', TRUE);

-- Insert Sample Services
INSERT INTO services (id, name, type, price, category, is_active) VALUES
(UUID(), 'Oil Change', 'service', 49.99, 'Oil Change', TRUE),
(UUID(), 'Brake Pad Replacement', 'part', 89.99, 'Brake Service', TRUE),
(UUID(), 'Engine Diagnostic', 'service', 75.00, 'Engine Service', TRUE),
(UUID(), 'Tire Rotation', 'service', 29.99, 'Tire Center', TRUE),
(UUID(), 'AC Recharge', 'service', 120.00, 'Air Conditioning', TRUE),
(UUID(), 'Battery Replacement', 'part', 150.00, 'Electrical', TRUE),
(UUID(), 'Labor - Per Hour', 'labor', 60.00, 'General Maintenance', TRUE);

-- ============================================
-- INDEXES SUMMARY
-- ============================================
-- All important indexes are defined inline with table creation
-- Additional composite indexes can be added based on query patterns

-- ============================================
-- END OF SCHEMA
-- ============================================
