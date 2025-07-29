# 🧪 VMUrugan Gold Trading - Local Testing Guide

## 📋 **Overview**
This guide helps you set up and test the VMUrugan Gold Trading Platform locally on your development machine without requiring a public IP address or domain.

---

## 🖥️ **LOCAL DEVELOPMENT SETUP**

### **Prerequisites**
- **Node.js**: Version 16.0 or higher
- **SQL Server**: Express Edition (free) or Developer Edition
- **Git**: For cloning the repository
- **Postman**: For API testing (optional)
- **VS Code**: Recommended IDE

### **System Requirements**
- **RAM**: 8 GB minimum (16 GB recommended)
- **Storage**: 10 GB free space
- **OS**: Windows 10/11, macOS, or Ubuntu 20.04+

---

## 🗄️ **SQL SERVER LOCAL SETUP**

### **Windows (SQL Server Express)**
```powershell
# Download SQL Server 2022 Express (free)
# https://www.microsoft.com/en-us/sql-server/sql-server-downloads

# Download SQL Server Management Studio (SSMS)
# https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

# After installation, enable SQL Server Authentication:
# 1. Open SSMS
# 2. Connect to (local)\SQLEXPRESS
# 3. Right-click server → Properties → Security
# 4. Select "SQL Server and Windows Authentication mode"
# 5. Restart SQL Server service in Services.msc
```

### **macOS (Docker)**
```bash
# Install Docker Desktop for Mac
# https://www.docker.com/products/docker-desktop

# Run SQL Server in Docker
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
   -p 1433:1433 --name sqlserver --hostname sqlserver \
   -d mcr.microsoft.com/mssql/server:2022-latest

# Connect using Azure Data Studio (free)
# https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio
```

### **Ubuntu (Docker)**
```bash
# Install Docker
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl start docker
sudo systemctl enable docker

# Run SQL Server in Docker
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
   -p 1433:1433 --name sqlserver --hostname sqlserver \
   -d mcr.microsoft.com/mssql/server:2022-latest

# Install SQL Server command-line tools
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🚀 **APPLICATION SETUP**

### **1. Clone and Setup Repository**
```bash
# Clone the repository
git clone <your-repository-url>
cd vmurugan-gold-trading

# Switch to migration branch
git checkout onprem-backend-migration

# Navigate to server directory
cd server

# Install dependencies
npm install
```

### **2. Environment Configuration**
```bash
# Copy environment template
cp .env.example .env

# Edit the .env file with local settings
```

**Local .env Configuration:**
```env
# Server Configuration
PORT=3000
NODE_ENV=development
API_VERSION=v1

# SQL Server Database Configuration (Local)
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=VMUruganGoldTrading
DB_USER=sa
DB_PASSWORD=YourStrong@Passw0rd
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# JWT Configuration
JWT_SECRET=local_development_jwt_secret_key_minimum_32_characters_long_for_testing
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Business Configuration
BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMUrugan Gold Trading
ADMIN_DEFAULT_PASSWORD=VMURUGAN_ADMIN_2025

# Security Configuration (Relaxed for local testing)
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000

# CORS Configuration (Allow all for local testing)
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000

# Logging Configuration
LOG_LEVEL=debug
LOG_FILE=logs/api.log
```

### **3. Database Initialization**
```bash
# Create logs directory
mkdir -p logs

# Run database setup
npm run setup

# Expected output:
# ✅ Connected to SQL Server database
# ✅ Database created successfully
# ✅ Database schema created successfully
# ✅ Admin user created successfully
# ✅ Test customer created successfully
```

### **4. Start the Server**
```bash
# Development mode with auto-reload
npm run dev

# Expected output:
# 🚀 VMUrugan Gold Trading API running on port 3000
# 📊 Environment: development
# 🏥 Health Check: http://localhost:3000/health
# 🔐 API Base URL: http://localhost:3000/api
```

---

## 📚 **API DOCUMENTATION & TESTING**

### **Swagger UI (Interactive Documentation)**
Once the server is running, access the interactive API documentation:

**URL**: http://localhost:3000/api-docs

**Features**:
- Complete API documentation
- Interactive testing interface
- Request/response examples
- Authentication testing
- Schema validation

### **Quick API Tests**

#### **1. Health Check**
```bash
curl http://localhost:3000/health
```

Expected Response:
```json
{
  "status": "OK",
  "timestamp": "2025-07-29T12:00:00.000Z",
  "service": "VMUrugan Gold Trading API",
  "version": "2.0.0",
  "database": "Connected",
  "environment": "development"
}
```

#### **2. Admin Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9999999999",
    "password": "VMURUGAN_ADMIN_2025"
  }'
```

#### **3. Test Customer Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "password": "test123"
  }'
```

#### **4. Customer Registration**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543000",
    "email": "test@local.com",
    "password": "test123",
    "name": "Local Test User",
    "address": "Local Test Address, Chennai, Tamil Nadu",
    "panCard": "ABCDE0000F"
  }'
```

---

## 🧪 **TESTING PROCEDURES**

### **1. Unit Tests**
```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- auth.test.js
```

### **2. Postman Collection Testing**
```bash
# Import the collection
# File: server/tests/postman/VMUrugan_API_Tests.postman_collection.json

# Update collection variables for local testing:
# baseUrl: http://localhost:3000/api
# healthUrl: http://localhost:3000/health
```

### **3. Manual Testing Checklist**

#### **Authentication Flow**
- [ ] Admin login with default credentials
- [ ] Customer registration with valid data
- [ ] Customer login with registered credentials
- [ ] Invalid login attempts (wrong password/phone)
- [ ] Token validation and expiry
- [ ] Logout functionality

#### **Customer Operations**
- [ ] Get customer profile
- [ ] Validate customer by phone
- [ ] Customer data integrity

#### **Transaction Operations**
- [ ] Create BUY transaction
- [ ] Update transaction status to SUCCESS
- [ ] Update transaction status to FAILED
- [ ] Get customer transactions with pagination
- [ ] Get transaction by ID

#### **Scheme Operations**
- [ ] Create investment scheme
- [ ] Process scheme payment
- [ ] Get customer schemes
- [ ] Cancel scheme

#### **Admin Operations**
- [ ] Access admin dashboard
- [ ] Get all customers with pagination
- [ ] Get all transactions with filters
- [ ] Get all schemes

---

## 📱 **FLUTTER APP LOCAL TESTING**

### **Update API Configuration**
```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  // For Android emulator, use: 'http://10.0.2.2:3000/api'
  // For iOS simulator, use: 'http://localhost:3000/api'
  // For physical device, use your computer's IP: 'http://192.168.1.100:3000/api'
}
```

### **Network Configuration**

#### **Android Emulator**
```dart
// Use this URL for Android emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

#### **iOS Simulator**
```dart
// Use this URL for iOS simulator
static const String baseUrl = 'http://localhost:3000/api';
```

#### **Physical Device**
```bash
# Find your computer's IP address
# Windows
ipconfig

# macOS/Linux
ifconfig

# Use your computer's IP address
# Example: http://192.168.1.100:3000/api
```

### **Flutter Testing Commands**
```bash
# Run Flutter app
flutter run

# Run on specific device
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS

# Hot reload during development
# Press 'r' in terminal or use IDE hot reload
```

---

## 🌐 **ADMIN PORTAL LOCAL TESTING**

### **Access Admin Portal**
**URL**: http://localhost:3000/admin

**Default Credentials**:
- **Phone**: 9999999999
- **Password**: VMURUGAN_ADMIN_2025

### **Admin Portal Features to Test**
- [ ] Login with admin credentials
- [ ] Dashboard statistics display
- [ ] Customer management interface
- [ ] Transaction monitoring
- [ ] Scheme management
- [ ] Real-time data updates
- [ ] Logout functionality

---

## 🔧 **TROUBLESHOOTING**

### **Common Issues**

#### **1. Database Connection Failed**
```bash
# Check SQL Server status
# Windows: Services.msc → SQL Server (SQLEXPRESS)
# Docker: docker ps

# Test connection
sqlcmd -S localhost -U sa -P YourStrong@Passw0rd
```

#### **2. Port Already in Use**
```bash
# Find process using port 3000
# Windows
netstat -ano | findstr :3000

# macOS/Linux
lsof -i :3000

# Kill process or change port in .env
```

#### **3. CORS Issues**
```javascript
// Update CORS configuration in server-sqlserver.js
app.use(cors({
  origin: '*', // Allow all origins for local testing
  credentials: true
}));
```

#### **4. Flutter Network Issues**
```dart
// Add network permissions for Android
// android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />

// For iOS, add to Info.plist for HTTP (not HTTPS) connections
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

---

## 📊 **MONITORING & DEBUGGING**

### **Server Logs**
```bash
# View real-time logs
tail -f logs/api.log

# View server console output
# Available in terminal where npm run dev is running
```

### **Database Monitoring**
```sql
-- Check active connections
SELECT * FROM sys.dm_exec_sessions WHERE is_user_process = 1;

-- Check recent transactions
SELECT TOP 10 * FROM transactions ORDER BY timestamp DESC;

-- Check customer count
SELECT COUNT(*) as total_customers FROM customers;
```

### **Performance Testing**
```bash
# Install Apache Bench (optional)
# Windows: Download from Apache website
# macOS: brew install httpd
# Ubuntu: sudo apt install apache2-utils

# Test API performance
ab -n 100 -c 10 http://localhost:3000/health
```

---

## ✅ **LOCAL TESTING CHECKLIST**

### **Setup Verification**
- [ ] SQL Server running and accessible
- [ ] Database schema created successfully
- [ ] Node.js server starting without errors
- [ ] Health endpoint responding correctly
- [ ] Swagger documentation accessible
- [ ] Admin and test user accounts created

### **API Testing**
- [ ] All authentication endpoints working
- [ ] Customer operations functional
- [ ] Transaction operations working
- [ ] Scheme operations functional
- [ ] Admin operations accessible
- [ ] Error handling working correctly

### **Integration Testing**
- [ ] Flutter app connecting to local API
- [ ] Admin portal working with local backend
- [ ] Database operations completing successfully
- [ ] JWT authentication working
- [ ] Data persistence verified

### **Performance Testing**
- [ ] API response times acceptable
- [ ] Database queries optimized
- [ ] Memory usage within limits
- [ ] No memory leaks detected

---

## 🎯 **NEXT STEPS**

Once local testing is complete:

1. **Prepare for Production**:
   - Update environment variables for production
   - Configure production database
   - Set up SSL certificates
   - Configure reverse proxy

2. **Deploy to Server**:
   - Follow the deployment guide
   - Update DNS records
   - Configure firewall rules
   - Set up monitoring

3. **Update Mobile App**:
   - Change API URLs to production
   - Test with production backend
   - Submit to app stores

---

**🎉 Your local development environment is ready for testing!**

**Key URLs**:
- **API Health**: http://localhost:3000/health
- **API Documentation**: http://localhost:3000/api-docs
- **Admin Portal**: http://localhost:3000/admin
- **API Base**: http://localhost:3000/api
