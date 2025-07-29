-- =====================================================
-- VMUrugan Gold Trading - Database Tables Creation
-- =====================================================

-- Create Users table
CREATE TABLE users (
    user_id NVARCHAR(50) PRIMARY KEY,
    phone NVARCHAR(15) UNIQUE NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    role NVARCHAR(20) DEFAULT 'customer',
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Create Customers table
CREATE TABLE customers (
    customer_id NVARCHAR(50) PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL,
    name NVARCHAR(255) NOT NULL,
    address NVARCHAR(500),
    pan_card NVARCHAR(20),
    aadhar_card NVARCHAR(20),
    bank_account NVARCHAR(50),
    ifsc_code NVARCHAR(20),
    bank_name NVARCHAR(255),
    kyc_status NVARCHAR(20) DEFAULT 'pending',
    total_invested DECIMAL(15,2) DEFAULT 0,
    total_gold DECIMAL(10,3) DEFAULT 0,
    registration_date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create Transactions table
CREATE TABLE transactions (
    transaction_id NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(50) NOT NULL,
    type NVARCHAR(10) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    gold_grams DECIMAL(10,3),
    gold_price_per_gram DECIMAL(10,2),
    payment_method NVARCHAR(50),
    gateway_transaction_id NVARCHAR(255),
    status NVARCHAR(20) DEFAULT 'PENDING',
    notes NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE(),
    completed_at DATETIME2,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create Schemes table
CREATE TABLE schemes (
    scheme_id NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(50) NOT NULL,
    scheme_type NVARCHAR(50) NOT NULL,
    monthly_amount DECIMAL(15,2) NOT NULL,
    duration_months INT NOT NULL,
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2,
    status NVARCHAR(20) DEFAULT 'active',
    total_paid DECIMAL(15,2) DEFAULT 0,
    total_gold DECIMAL(10,3) DEFAULT 0,
    paid_months INT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create Scheme Payments table
CREATE TABLE scheme_payments (
    payment_id NVARCHAR(50) PRIMARY KEY,
    scheme_id NVARCHAR(50) NOT NULL,
    transaction_id NVARCHAR(50),
    amount DECIMAL(15,2) NOT NULL,
    gold_grams DECIMAL(10,3),
    gold_price_per_gram DECIMAL(10,2),
    payment_date DATETIME2 DEFAULT GETDATE(),
    month_number INT NOT NULL,
    FOREIGN KEY (scheme_id) REFERENCES schemes(scheme_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

-- Create Gold Prices table
CREATE TABLE gold_prices (
    price_id NVARCHAR(50) PRIMARY KEY,
    price_per_gram DECIMAL(10,2) NOT NULL,
    price_date DATETIME2 DEFAULT GETDATE(),
    source NVARCHAR(100),
    is_active BIT DEFAULT 1
);

-- Create Analytics table
CREATE TABLE analytics (
    event_id NVARCHAR(50) PRIMARY KEY,
    event_name NVARCHAR(100) NOT NULL,
    event_data NVARCHAR(MAX),
    user_id NVARCHAR(50),
    customer_id NVARCHAR(50),
    timestamp DATETIME2 DEFAULT GETDATE(),
    ip_address NVARCHAR(50),
    user_agent NVARCHAR(500)
);

-- Create Business Settings table
CREATE TABLE business_settings (
    setting_id NVARCHAR(50) PRIMARY KEY,
    setting_key NVARCHAR(100) UNIQUE NOT NULL,
    setting_value NVARCHAR(MAX),
    setting_type NVARCHAR(50) DEFAULT 'string',
    description NVARCHAR(500),
    updated_at DATETIME2 DEFAULT GETDATE(),
    updated_by NVARCHAR(50)
);

-- Create Audit Log table
CREATE TABLE audit_log (
    log_id NVARCHAR(50) PRIMARY KEY,
    table_name NVARCHAR(100) NOT NULL,
    operation NVARCHAR(20) NOT NULL,
    record_id NVARCHAR(50),
    old_values NVARCHAR(MAX),
    new_values NVARCHAR(MAX),
    changed_by NVARCHAR(50),
    changed_at DATETIME2 DEFAULT GETDATE()
);

-- Insert default admin user
INSERT INTO users (user_id, phone, email, password_hash, role, is_active)
VALUES ('ADMIN_001', '9999999999', 'admin@vmurugan.com', '$2b$10$rQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHWKQVz7QGQrQZ8kHW', 'admin', 1);

-- Insert default business settings
INSERT INTO business_settings (setting_id, setting_key, setting_value, setting_type, description)
VALUES 
('SET_001', 'business_name', 'VMUrugan Gold Trading', 'string', 'Business name'),
('SET_002', 'business_id', 'VMURUGAN_001', 'string', 'Unique business identifier'),
('SET_003', 'current_gold_price', '6666.67', 'decimal', 'Current gold price per gram'),
('SET_004', 'min_transaction_amount', '100', 'decimal', 'Minimum transaction amount'),
('SET_005', 'max_transaction_amount', '1000000', 'decimal', 'Maximum transaction amount'),
('SET_006', 'scheme_min_duration', '6', 'integer', 'Minimum scheme duration in months'),
('SET_007', 'scheme_max_duration', '60', 'integer', 'Maximum scheme duration in months');

-- Insert current gold price
INSERT INTO gold_prices (price_id, price_per_gram, source, is_active)
VALUES ('PRICE_001', 6666.67, 'Manual Entry', 1);

PRINT 'Database tables created successfully!';
