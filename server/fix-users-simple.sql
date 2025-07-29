-- =====================================================
-- Simple Fix for Users Table
-- =====================================================

-- Drop foreign key constraint
ALTER TABLE customers DROP CONSTRAINT FK__customers__user___4316F928;

-- Drop and recreate users table
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

-- Update customers table
ALTER TABLE customers ALTER COLUMN user_id UNIQUEIDENTIFIER NOT NULL;

-- Recreate foreign key
ALTER TABLE customers ADD CONSTRAINT FK_customers_users 
    FOREIGN KEY (user_id) REFERENCES users(user_id);

PRINT 'Users table fixed successfully!';
