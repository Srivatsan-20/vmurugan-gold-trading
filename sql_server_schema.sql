-- =====================================================
-- VMUrugan Gold Trading Platform - SQL Server Schema
-- On-Premises Backend Migration
-- =====================================================

-- Create Database
CREATE DATABASE VMUruganGoldTrading;
GO

USE VMUruganGoldTrading;
GO

-- =====================================================
-- 1. USERS TABLE (Authentication & Profile)
-- =====================================================
CREATE TABLE users (
    user_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    phone NVARCHAR(15) NOT NULL UNIQUE,
    email NVARCHAR(255) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL, -- bcrypt hash
    name NVARCHAR(255) NOT NULL,
    role NVARCHAR(20) NOT NULL DEFAULT 'customer', -- 'customer', 'admin'
    is_active BIT NOT NULL DEFAULT 1,
    email_verified BIT NOT NULL DEFAULT 0,
    phone_verified BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    last_login_at DATETIME2 NULL,
    
    INDEX IX_users_phone (phone),
    INDEX IX_users_email (email),
    INDEX IX_users_role (role)
);

-- =====================================================
-- 2. CUSTOMERS TABLE (Business Customer Data)
-- =====================================================
CREATE TABLE customers (
    customer_id NVARCHAR(20) PRIMARY KEY, -- VM000001 format
    user_id UNIQUEIDENTIFIER NULL, -- FK to users table
    phone NVARCHAR(15) NOT NULL UNIQUE,
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    address NVARCHAR(500) NOT NULL,
    pan_card NVARCHAR(10) NOT NULL,
    device_id NVARCHAR(255) NULL,
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    data_type NVARCHAR(20) NOT NULL DEFAULT 'real_user',
    
    -- Portfolio Summary
    total_invested DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_gold DECIMAL(10,4) NOT NULL DEFAULT 0.00,
    transaction_count INT NOT NULL DEFAULT 0,
    
    -- Timestamps
    registration_date DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    last_transaction DATETIME2 NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX IX_customers_phone (phone),
    INDEX IX_customers_business_id (business_id),
    INDEX IX_customers_user_id (user_id)
);

-- =====================================================
-- 3. SCHEMES TABLE (Gold Investment Schemes)
-- =====================================================
CREATE TABLE schemes (
    scheme_id NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(20) NOT NULL,
    customer_phone NVARCHAR(15) NOT NULL,
    customer_name NVARCHAR(255) NOT NULL,
    
    -- Scheme Details
    scheme_type NVARCHAR(50) NOT NULL, -- 'monthly_sip', 'lump_sum', etc.
    monthly_amount DECIMAL(10,2) NOT NULL,
    duration_months INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Progress Tracking
    paid_months INT NOT NULL DEFAULT 0,
    remaining_months INT NOT NULL,
    gold_accumulated DECIMAL(10,4) NOT NULL DEFAULT 0.00,
    total_paid DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- Status
    status NVARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'completed', 'cancelled'
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    data_type NVARCHAR(20) NOT NULL DEFAULT 'real_scheme',
    
    -- Timestamps
    created_date DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX IX_schemes_customer_id (customer_id),
    INDEX IX_schemes_customer_phone (customer_phone),
    INDEX IX_schemes_status (status),
    INDEX IX_schemes_business_id (business_id)
);

-- =====================================================
-- 4. TRANSACTIONS TABLE (All Gold Transactions)
-- =====================================================
CREATE TABLE transactions (
    transaction_id NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(20) NULL,
    customer_phone NVARCHAR(15) NOT NULL,
    customer_name NVARCHAR(255) NOT NULL,
    
    -- Transaction Details
    type NVARCHAR(20) NOT NULL, -- 'BUY', 'SELL', 'SCHEME_PAYMENT'
    amount DECIMAL(15,2) NOT NULL,
    gold_grams DECIMAL(10,4) NOT NULL,
    gold_price_per_gram DECIMAL(10,2) NOT NULL,
    
    -- Payment Details
    payment_method NVARCHAR(50) NOT NULL, -- 'UPI', 'CARD', 'NET_BANKING', 'CASH'
    status NVARCHAR(20) NOT NULL, -- 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'
    gateway_transaction_id NVARCHAR(255) NULL,
    gateway_order_id NVARCHAR(255) NULL,
    
    -- Additional Info
    device_info NVARCHAR(500) NULL,
    location NVARCHAR(255) NULL,
    notes NVARCHAR(1000) NULL,
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    
    -- Fees
    transaction_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    gst DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_fees DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- Timestamps
    timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    completed_at DATETIME2 NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX IX_transactions_customer_phone (customer_phone),
    INDEX IX_transactions_type (type),
    INDEX IX_transactions_status (status),
    INDEX IX_transactions_timestamp (timestamp),
    INDEX IX_transactions_business_id (business_id)
);

-- =====================================================
-- 5. PRICE_HISTORY TABLE (Gold Price Tracking)
-- =====================================================
CREATE TABLE price_history (
    price_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    gold_type NVARCHAR(10) NOT NULL DEFAULT '22K', -- '22K', '24K'
    price_per_gram DECIMAL(10,2) NOT NULL,
    source NVARCHAR(100) NOT NULL DEFAULT 'metals.live',
    
    -- Price Change Info
    change_amount DECIMAL(10,2) NULL,
    change_percentage DECIMAL(5,2) NULL,
    trend NVARCHAR(10) NULL, -- 'UP', 'DOWN', 'STABLE'
    
    -- Timestamps
    timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_price_history_timestamp (timestamp),
    INDEX IX_price_history_gold_type (gold_type)
);

-- =====================================================
-- 6. ANALYTICS TABLE (Business Analytics)
-- =====================================================
CREATE TABLE analytics (
    analytics_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    event NVARCHAR(100) NOT NULL,
    data NVARCHAR(MAX) NOT NULL, -- JSON data
    user_id UNIQUEIDENTIFIER NULL,
    customer_id NVARCHAR(20) NULL,
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    
    -- Timestamps
    timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX IX_analytics_event (event),
    INDEX IX_analytics_timestamp (timestamp),
    INDEX IX_analytics_business_id (business_id)
);

-- =====================================================
-- 7. NOTIFICATIONS TABLE (User Notifications)
-- =====================================================
CREATE TABLE notifications (
    notification_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER NULL,
    customer_id NVARCHAR(20) NULL,
    
    -- Notification Details
    type NVARCHAR(50) NOT NULL, -- 'PRICE_ALERT', 'TRANSACTION', 'SCHEME', 'GENERAL'
    title NVARCHAR(255) NOT NULL,
    message NVARCHAR(1000) NOT NULL,
    data NVARCHAR(MAX) NULL, -- JSON data
    priority NVARCHAR(20) NOT NULL DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    
    -- Status
    is_read BIT NOT NULL DEFAULT 0,
    is_sent BIT NOT NULL DEFAULT 0,
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    
    -- Timestamps
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    read_at DATETIME2 NULL,
    sent_at DATETIME2 NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX IX_notifications_user_id (user_id),
    INDEX IX_notifications_type (type),
    INDEX IX_notifications_is_read (is_read),
    INDEX IX_notifications_created_at (created_at)
);

-- =====================================================
-- 8. COUNTERS TABLE (ID Generation)
-- =====================================================
CREATE TABLE counters (
    counter_name NVARCHAR(50) PRIMARY KEY,
    current_value INT NOT NULL DEFAULT 0,
    business_id NVARCHAR(50) NOT NULL DEFAULT 'VMURUGAN_001',
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

-- Initialize customer counter
INSERT INTO counters (counter_name, current_value, business_id) 
VALUES ('customer_id', 0, 'VMURUGAN_001');

-- =====================================================
-- 9. SESSIONS TABLE (JWT Session Management)
-- =====================================================
CREATE TABLE sessions (
    session_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER NOT NULL,
    token_hash NVARCHAR(255) NOT NULL,
    device_info NVARCHAR(500) NULL,
    ip_address NVARCHAR(45) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    last_used_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX IX_sessions_user_id (user_id),
    INDEX IX_sessions_token_hash (token_hash),
    INDEX IX_sessions_expires_at (expires_at)
);

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Generate unique customer ID
CREATE PROCEDURE sp_GenerateCustomerId
    @BusinessId NVARCHAR(50) = 'VMURUGAN_001',
    @CustomerId NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Counter INT;
    
    -- Get and increment counter
    UPDATE counters 
    SET current_value = current_value + 1,
        updated_at = GETUTCDATE()
    WHERE counter_name = 'customer_id' AND business_id = @BusinessId;
    
    -- Get the new counter value
    SELECT @Counter = current_value 
    FROM counters 
    WHERE counter_name = 'customer_id' AND business_id = @BusinessId;
    
    -- Generate customer ID with VM prefix and 6-digit number
    SET @CustomerId = 'VM' + RIGHT('000000' + CAST(@Counter AS VARCHAR(6)), 6);
END;
GO

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Users table trigger
CREATE TRIGGER tr_users_updated_at ON users
AFTER UPDATE AS
BEGIN
    UPDATE users SET updated_at = GETUTCDATE()
    WHERE user_id IN (SELECT user_id FROM inserted);
END;
GO

-- Customers table trigger  
CREATE TRIGGER tr_customers_updated_at ON customers
AFTER UPDATE AS
BEGIN
    UPDATE customers SET updated_at = GETUTCDATE()
    WHERE customer_id IN (SELECT customer_id FROM inserted);
END;
GO

-- Schemes table trigger
CREATE TRIGGER tr_schemes_updated_at ON schemes
AFTER UPDATE AS
BEGIN
    UPDATE schemes SET updated_at = GETUTCDATE()
    WHERE scheme_id IN (SELECT scheme_id FROM inserted);
END;
GO

-- Transactions table trigger
CREATE TRIGGER tr_transactions_updated_at ON transactions
AFTER UPDATE AS
BEGIN
    UPDATE transactions SET updated_at = GETUTCDATE()
    WHERE transaction_id IN (SELECT transaction_id FROM inserted);
END;
GO

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert admin user
INSERT INTO users (phone, email, password_hash, name, role, email_verified, phone_verified)
VALUES ('9999999999', 'admin@vmurugan.com', '$2b$10$example_hash_here', 'VMUrugan Admin', 'admin', 1, 1);

-- Insert test customer user
INSERT INTO users (phone, email, password_hash, name, role, email_verified, phone_verified)
VALUES ('9876543210', 'test@vmurugan.com', '$2b$10$example_hash_here', 'Test Customer', 'customer', 1, 1);

PRINT 'VMUrugan Gold Trading Database Schema Created Successfully!';
PRINT 'Database: VMUruganGoldTrading';
PRINT 'Tables: 9 tables created with proper relationships and indexes';
PRINT 'Stored Procedures: Customer ID generation';
PRINT 'Triggers: Auto-update timestamps';
GO
