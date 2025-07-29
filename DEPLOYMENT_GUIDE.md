# 🚀 VMUrugan Gold Trading Platform - On-Premises Deployment Guide

## 📋 **Overview**
This guide provides step-by-step instructions for deploying the VMUrugan Gold Trading Platform on your own servers, completely replacing Firebase with a self-hosted solution.

## 🎯 **Migration Summary**
- ✅ **Firebase Auth** → JWT Authentication with bcrypt
- ✅ **Firestore Database** → SQL Server with mssql package
- ✅ **Firebase Functions** → Node.js/Express RESTful API
- ✅ **Firebase Hosting** → Self-hosted with Nginx/IIS
- ✅ **Real-time Updates** → HTTP polling with auto-refresh
- ✅ **Security Rules** → API middleware and validation

---

## 🖥️ **SYSTEM REQUIREMENTS**

### **Minimum Hardware Requirements:**
- **CPU**: 4 cores (2.4 GHz or higher)
- **RAM**: 8 GB (16 GB recommended)
- **Storage**: 100 GB SSD (500 GB recommended)
- **Network**: 100 Mbps internet connection

### **Software Requirements:**
- **Operating System**: Windows Server 2019+ or Ubuntu 20.04+
- **Node.js**: Version 16.0 or higher
- **SQL Server**: 2019 Express or higher
- **Web Server**: Nginx (Linux) or IIS (Windows)
- **SSL Certificate**: Let's Encrypt or commercial certificate

---

## 🗄️ **SQL SERVER SETUP**

### **Windows Installation:**
```powershell
# Download SQL Server 2019 Express
# https://www.microsoft.com/en-us/sql-server/sql-server-downloads

# Install SQL Server Management Studio (SSMS)
# https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

# Enable SQL Server Authentication
# 1. Open SSMS
# 2. Connect to SQL Server instance
# 3. Right-click server → Properties → Security
# 4. Select "SQL Server and Windows Authentication mode"
# 5. Restart SQL Server service
```

### **Ubuntu Installation:**
```bash
# Import Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add Microsoft SQL Server repository
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"

# Install SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server

# Configure SQL Server
sudo /opt/mssql/bin/mssql-conf setup

# Install SQL Server command-line tools
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev

# Add tools to PATH
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

### **Database Setup:**
```sql
-- Create database user for API
CREATE LOGIN vmurugan_api_user WITH PASSWORD = 'YourSecurePassword123!';
CREATE USER vmurugan_api_user FOR LOGIN vmurugan_api_user;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER vmurugan_api_user;
ALTER ROLE db_datawriter ADD MEMBER vmurugan_api_user;
ALTER ROLE db_ddladmin ADD MEMBER vmurugan_api_user;

-- Create database (will be done by setup script)
-- CREATE DATABASE VMUruganGoldTrading;
```

---

## 🔧 **BACKEND API DEPLOYMENT**

### **1. Server Preparation:**

#### **Windows Server:**
```powershell
# Install Node.js
# Download from: https://nodejs.org/en/download/

# Install PM2 globally
npm install -g pm2

# Install Git
# Download from: https://git-scm.com/download/win

# Create application directory
mkdir C:\VMUrugan
cd C:\VMUrugan
```

#### **Ubuntu Server:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install Git
sudo apt install git -y

# Create application directory
sudo mkdir -p /opt/vmurugan
sudo chown $USER:$USER /opt/vmurugan
cd /opt/vmurugan
```

### **2. Application Deployment:**
```bash
# Clone the repository
git clone https://github.com/your-repo/vmurugan-gold-trading.git
cd vmurugan-gold-trading

# Switch to migration branch
git checkout onprem-backend-migration

# Navigate to server directory
cd server

# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env

# Edit environment variables
nano .env  # or notepad .env on Windows
```

### **3. Environment Configuration (.env):**
```env
# Server Configuration
PORT=3000
NODE_ENV=production
API_VERSION=v1

# SQL Server Database Configuration
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=VMUruganGoldTrading
DB_USER=vmurugan_api_user
DB_PASSWORD=YourSecurePassword123!
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=false

# JWT Configuration
JWT_SECRET=your_super_secure_jwt_secret_key_here_minimum_32_characters_long
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Business Configuration
BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMUrugan Gold Trading
ADMIN_DEFAULT_PASSWORD=VMURUGAN_ADMIN_2025

# Security Configuration
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=logs/api.log
```

### **4. Database Initialization:**
```bash
# Run database setup
npm run setup

# Expected output:
# ✅ Connected to SQL Server database
# ✅ Database created successfully
# ✅ Database schema created successfully
# ✅ Admin user created successfully
# ✅ Test customer created successfully
```

### **5. Start Application:**

#### **Development Mode:**
```bash
npm run dev
```

#### **Production Mode with PM2:**
```bash
# Start with PM2
pm2 start server-sqlserver.js --name "vmurugan-api"

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
pm2 startup

# Monitor application
pm2 monit
```

---

## 🌐 **WEB SERVER CONFIGURATION**

### **Nginx Setup (Ubuntu):**

#### **1. Install Nginx:**
```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### **2. Configure Nginx:**
```bash
# Create site configuration
sudo nano /etc/nginx/sites-available/vmurugan
```

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

    # API Proxy
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health Check
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin Portal
    location /admin {
        root /opt/vmurugan/vmurugan-gold-trading/admin_portal;
        try_files $uri $uri/ /backend_admin_portal.html;
        index backend_admin_portal.html;
    }

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    location /api/ {
        limit_req zone=api burst=20 nodelay;
    }
}
```

#### **3. Enable Site:**
```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/vmurugan /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### **IIS Setup (Windows):**

#### **1. Install IIS and URL Rewrite:**
```powershell
# Enable IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpLogging, IIS-RequestFiltering, IIS-StaticContent

# Install URL Rewrite Module
# Download from: https://www.iis.net/downloads/microsoft/url-rewrite

# Install Application Request Routing
# Download from: https://www.iis.net/downloads/microsoft/application-request-routing
```

#### **2. Configure IIS Site:**
```xml
<!-- web.config -->
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <!-- API Proxy -->
        <rule name="API Proxy" stopProcessing="true">
          <match url="^api/(.*)" />
          <action type="Rewrite" url="http://localhost:3000/api/{R:1}" />
        </rule>
        
        <!-- Health Check -->
        <rule name="Health Check" stopProcessing="true">
          <match url="^health$" />
          <action type="Rewrite" url="http://localhost:3000/health" />
        </rule>
        
        <!-- Admin Portal -->
        <rule name="Admin Portal" stopProcessing="true">
          <match url="^admin$" />
          <action type="Rewrite" url="/admin_portal/backend_admin_portal.html" />
        </rule>
      </rules>
    </rewrite>
    
    <!-- Security Headers -->
    <httpProtocol>
      <customHeaders>
        <add name="X-Frame-Options" value="DENY" />
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-XSS-Protection" value="1; mode=block" />
      </customHeaders>
    </httpProtocol>
  </system.webServer>
</configuration>
```

---

## 🔒 **SSL CERTIFICATE SETUP**

### **Let's Encrypt (Ubuntu):**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test automatic renewal
sudo certbot renew --dry-run

# Setup automatic renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### **Commercial Certificate (Windows):**
```powershell
# 1. Generate Certificate Signing Request (CSR) in IIS Manager
# 2. Submit CSR to Certificate Authority
# 3. Install received certificate in IIS Manager
# 4. Bind certificate to website
```

---

## 🔥 **FIREWALL CONFIGURATION**

### **Ubuntu (UFW):**
```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Node.js app (if direct access needed)
sudo ufw allow 3000/tcp

# Allow SQL Server (if remote access needed)
sudo ufw allow 1433/tcp

# Check status
sudo ufw status verbose
```

### **Windows Firewall:**
```powershell
# Allow HTTP
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

# Allow HTTPS
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Allow Node.js app
New-NetFirewallRule -DisplayName "VMUrugan API" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow

# Allow SQL Server
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

---

## 📱 **FLUTTER APP CONFIGURATION**

### **Update API Configuration:**
```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://yourdomain.com/api';
  // ... rest of configuration
}
```

### **Build and Deploy Flutter App:**
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release
```

---

## 🧪 **TESTING AND VALIDATION**

### **1. Backend API Testing:**
```bash
# Run unit tests
cd server
npm test

# Run with coverage
npm run test:coverage

# Import Postman collection
# File: server/tests/postman/VMUrugan_API_Tests.postman_collection.json
```

### **2. Health Checks:**
```bash
# Check API health
curl https://yourdomain.com/health

# Check database connection
curl https://yourdomain.com/api/admin/dashboard \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Check SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

### **3. Performance Testing:**
```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test API performance
ab -n 1000 -c 10 https://yourdomain.com/health

# Monitor with PM2
pm2 monit
```

---

## 📊 **MONITORING AND MAINTENANCE**

### **1. Log Management:**
```bash
# View API logs
pm2 logs vmurugan-api

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View SQL Server logs
sudo tail -f /var/opt/mssql/log/errorlog
```

### **2. Backup Strategy:**
```sql
-- Database backup script
BACKUP DATABASE VMUruganGoldTrading 
TO DISK = '/var/opt/mssql/backup/VMUrugan_backup.bak'
WITH FORMAT, INIT;

-- Schedule daily backups
-- Use SQL Server Agent or cron job
```

### **3. Update Process:**
```bash
# Update application
cd /opt/vmurugan/vmurugan-gold-trading
git pull origin onprem-backend-migration
cd server
npm install
pm2 restart vmurugan-api
```

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues:**

1. **Database Connection Failed:**
   - Check SQL Server service status
   - Verify connection string in .env
   - Check firewall rules for port 1433

2. **API Not Responding:**
   - Check PM2 status: `pm2 status`
   - View logs: `pm2 logs vmurugan-api`
   - Restart service: `pm2 restart vmurugan-api`

3. **SSL Certificate Issues:**
   - Verify certificate installation
   - Check certificate expiry
   - Test with SSL checker tools

4. **High Memory Usage:**
   - Monitor with `pm2 monit`
   - Adjust PM2 configuration
   - Optimize database queries

### **Support Contacts:**
- **Technical Issues**: Check server logs and API documentation
- **Database Issues**: Review SQL Server error logs
- **SSL Issues**: Verify certificate configuration
- **Performance Issues**: Monitor with PM2 and system tools

---

## ✅ **DEPLOYMENT CHECKLIST**

- [ ] SQL Server installed and configured
- [ ] Database schema created successfully
- [ ] Node.js application deployed
- [ ] Environment variables configured
- [ ] PM2 process manager setup
- [ ] Web server (Nginx/IIS) configured
- [ ] SSL certificate installed
- [ ] Firewall rules configured
- [ ] DNS records updated
- [ ] Admin portal accessible
- [ ] API endpoints tested
- [ ] Flutter app updated with new API URLs
- [ ] Backup strategy implemented
- [ ] Monitoring setup completed
- [ ] Documentation updated

---

**🎉 Congratulations! Your VMUrugan Gold Trading Platform is now fully migrated from Firebase to a self-hosted on-premises solution.**
