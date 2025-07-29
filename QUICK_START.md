# 🚀 VMUrugan Gold Trading - Quick Start Guide

## **Option 1: One-Click Startup (Recommended)**

### **Windows**
```cmd
# Double-click or run in Command Prompt
run-local.bat
```

### **macOS/Linux**
```bash
# Make executable and run
chmod +x run-local.sh
./run-local.sh
```

---

## **Option 2: Manual Setup**

### **Prerequisites**
- **Node.js 16+**: Download from https://nodejs.org/
- **SQL Server**: Express Edition (free) or Docker

### **Step 1: Install SQL Server**

#### **Windows (SQL Server Express)**
1. Download: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Install SQL Server Express
3. Download SSMS: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
4. Enable SQL Server Authentication in SSMS

#### **Docker (All Platforms)**
```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
   -p 1433:1433 --name sqlserver \
   -d mcr.microsoft.com/mssql/server:2022-latest
```

### **Step 2: Setup Backend**
```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Setup environment
cp .env.local .env
# Edit .env and update DB_PASSWORD

# Setup database
npm run setup

# Start server
npm run dev
```

---

## **🌐 Access Your Application**

Once the server starts, you'll see:
```
🚀 VMUrugan Gold Trading API running on port 3000
📊 Environment: development
🏥 Health Check: http://localhost:3000/health
🔐 API Base URL: http://localhost:3000/api
```

### **Key URLs**
| Service | URL | Purpose |
|---------|-----|---------|
| **API Documentation** | http://localhost:3000/api-docs | Interactive API testing |
| **Health Check** | http://localhost:3000/health | Server status |
| **Admin Portal** | http://localhost:3000/admin | Admin dashboard |

### **Test Credentials**
| Account | Phone | Password | Role |
|---------|-------|----------|------|
| **Admin** | 9999999999 | VMURUGAN_ADMIN_2025 | admin |
| **Customer** | 9876543210 | test123 | customer |

---

## **🧪 Test Everything Works**

### **1. Health Check**
```bash
curl http://localhost:3000/health
```

### **2. Admin Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"9999999999","password":"VMURUGAN_ADMIN_2025"}'
```

### **3. Automated Tests**
```bash
cd server
npm run test-local
```

### **4. Swagger UI Testing**
1. Open http://localhost:3000/api-docs
2. Click "Authorize" 
3. Login to get JWT token
4. Test any endpoint interactively

---

## **📱 Flutter App Setup**

### **Update API Configuration**
```dart
// lib/core/config/api_config.dart
static String _getLocalUrl() {
  // Choose based on your platform:
  
  // Android Emulator
  return 'http://10.0.2.2:3000/api';
  
  // iOS Simulator / Web
  // return 'http://localhost:3000/api';
  
  // Physical Device (replace with your computer's IP)
  // return 'http://192.168.1.100:3000/api';
}
```

### **Find Your Computer's IP**
```bash
# Windows
ipconfig

# macOS/Linux  
ifconfig | grep inet
```

### **Run Flutter App**
```bash
# Start Flutter app
flutter run

# Or specific platform
flutter run -d chrome     # Web
flutter run -d android    # Android  
flutter run -d ios        # iOS
```

---

## **🔧 Troubleshooting**

### **Database Connection Issues**
```bash
# Check SQL Server status
# Windows: Services.msc → SQL Server (SQLEXPRESS)
# Docker: docker ps

# Test connection
sqlcmd -S localhost -U sa -P YourStrong@Passw0rd
```

### **Port Already in Use**
```bash
# Find process using port 3000
# Windows: netstat -ano | findstr :3000
# macOS/Linux: lsof -i :3000

# Change port in .env file
PORT=3001
```

### **CORS Issues**
```bash
# Add your device IP to .env
ALLOWED_ORIGINS=http://localhost:3000,http://10.0.2.2:3000,http://192.168.1.100:3000
```

### **JWT Token Issues**
- Ensure JWT_SECRET is at least 32 characters
- Copy token from login response
- Use in Authorization header: `Bearer <token>`

---

## **📊 Development Commands**

```bash
# Server commands (run from server/ directory)
npm run dev              # Start with auto-reload
npm run test            # Unit tests
npm run test-local      # Integration tests
npm run health          # Health check
npm run logs            # View server logs

# Database commands
npm run setup           # Setup database
node setup-sqlserver.js # Manual database setup

# Testing commands
npm run admin-login     # Test admin login
npm run test-customer   # Test customer login
```

---

## **🎯 What's Running**

When everything is set up correctly, you'll have:

✅ **Backend API Server** (Node.js/Express)
- REST API with 25+ endpoints
- JWT authentication
- SQL Server database
- Swagger documentation

✅ **Database** (SQL Server)
- Complete schema with 9 tables
- Admin and test user accounts
- Sample data for testing

✅ **Admin Portal** (Web)
- Real-time dashboard
- Customer management
- Transaction monitoring

✅ **API Documentation** (Swagger)
- Interactive testing interface
- Complete endpoint documentation
- Authentication support

---

## **🚀 Next Steps**

1. **Test the API** using Swagger UI
2. **Connect Flutter app** with updated API URLs
3. **Test admin portal** functionality
4. **Run integration tests** to verify everything works
5. **Start developing** new features!

---

## **🆘 Need Help?**

### **Check These First**
1. Server running: http://localhost:3000/health
2. Database connected: Check server logs
3. Environment configured: Verify .env file
4. Ports available: 3000 and 1433

### **Get Support**
- Check `LOCAL_TESTING_GUIDE.md` for detailed troubleshooting
- Review server logs in `server/logs/api.log`
- Test with Postman collection in `server/tests/postman/`
- Verify SQL Server is running and accessible

**Happy coding! 🎉**
