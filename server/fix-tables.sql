-- =====================================================
-- Fix Database Tables for VMUrugan Gold Trading
-- =====================================================

-- Drop foreign key constraints first
ALTER TABLE customers DROP CONSTRAINT FK__customers__user___3C69FB99;
ALTER TABLE analytics DROP CONSTRAINT FK__analytics__user___5441852A;

-- Drop and recreate users table with proper structure
DROP TABLE users;

CREATE TABLE users (
    user_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    phone NVARCHAR(15) UNIQUE NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    name NVARCHAR(255) NOT NULL,
    role NVARCHAR(20) DEFAULT 'customer',
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Update customers table structure
ALTER TABLE customers ALTER COLUMN user_id UNIQUEIDENTIFIER NOT NULL;

-- Recreate foreign key constraints
ALTER TABLE customers ADD CONSTRAINT FK_customers_users 
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- Insert admin user with proper structure
INSERT INTO users (user_id, phone, email, password_hash, name, role, is_active)
VALUES ('11111111-1111-1111-1111-111111111111', '9999999999', 'admin@vmurugan.com', 
        '$2b$10$rQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHW', 
        'VMUrugan Admin', 'admin', 1);

-- Insert test user
INSERT INTO users (user_id, phone, email, password_hash, name, role, is_active)
VALUES ('22222222-2222-2222-2222-222222222222', '9876543210', 'test@vmurugan.com', 
        '$2b$10$rQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHW', 
        'Test Customer', 'customer', 1);

-- Update customer records
UPDATE customers SET user_id = '11111111-1111-1111-1111-111111111111' WHERE customer_id = 'VM000000';
UPDATE customers SET user_id = '22222222-2222-2222-2222-222222222222' WHERE customer_id = 'VM000001';

PRINT 'Tables fixed successfully!';
