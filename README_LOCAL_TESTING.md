# 🧪 VMUrugan Gold Trading - Local Testing Quick Start

## 🚀 **QUICK START (5 Minutes)**

### **Prerequisites**
- Node.js 16+ installed
- SQL Server (Express/Developer) or Docker

### **1. Clone & Setup**
```bash
git clone <your-repository>
cd vmurugan-gold-trading/server
```

### **2. Automated Setup**
```bash
# Run the automated setup script
node local-setup.js

# OR manual setup
npm install
cp .env.local .env
# Update DB_PASSWORD in .env
npm run setup
```

### **3. Start Server**
```bash
npm run dev
```

### **4. Test Everything**
```bash
# Run comprehensive API tests
npm run test-local

# OR test individual components
npm test                    # Unit tests
npm run health             # Health check
npm run admin-login        # Test admin login
```

---

## 🌐 **Access URLs**

| Service | URL | Credentials |
|---------|-----|-------------|
| **API Documentation** | http://localhost:3000/api-docs | - |
| **Health Check** | http://localhost:3000/health | - |
| **Admin Portal** | http://localhost:3000/admin | 9999999999 / VMURUGAN_ADMIN_2025 |
| **API Base** | http://localhost:3000/api | - |

---

## 📱 **Flutter App Configuration**

### **Update API URL**
```dart
// lib/core/config/api_config.dart
static String _getLocalUrl() {
  // Choose based on your testing platform:
  
  // Android Emulator
  return 'http://10.0.2.2:3000/api';
  
  // iOS Simulator / Web
  // return 'http://localhost:3000/api';
  
  // Physical Device (replace with your IP)
  // return 'http://192.168.1.100:3000/api';
}
```

### **Find Your IP Address**
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig | grep inet

# Use the IP in Flutter app for physical device testing
```

---

## 🧪 **Testing Scenarios**

### **1. API Testing with Swagger**
1. Open http://localhost:3000/api-docs
2. Click "Authorize" and enter JWT token
3. Test any endpoint interactively

### **2. Admin Portal Testing**
1. Open http://localhost:3000/admin
2. Login with: 9999999999 / VMURUGAN_ADMIN_2025
3. Verify dashboard, customers, transactions

### **3. Flutter App Testing**
```bash
# Start Flutter app
flutter run

# Test on different platforms
flutter run -d chrome     # Web
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### **4. Automated Testing**
```bash
# Full test suite
npm run test-all

# Individual tests
npm test                   # Unit tests
npm run test-local        # Integration tests
```

---

## 🔧 **Common Issues & Solutions**

### **Database Connection Failed**
```bash
# Check SQL Server status
# Windows: Services.msc → SQL Server
# Docker: docker ps

# Test connection
sqlcmd -S localhost -U sa -P YourPassword
```

### **Port 3000 Already in Use**
```bash
# Find and kill process
netstat -ano | findstr :3000  # Windows
lsof -i :3000                 # macOS/Linux

# OR change port in .env
PORT=3001
```

### **CORS Issues in Flutter**
```dart
// Add to ALLOWED_ORIGINS in .env
ALLOWED_ORIGINS=http://localhost:3000,http://10.0.2.2:3000,http://192.168.1.100:3000
```

### **JWT Token Issues**
```bash
# Check token in Swagger UI
# Copy token from login response
# Use in Authorization header: Bearer <token>
```

---

## 📊 **Test Credentials**

### **Admin Account**
- **Phone**: 9999999999
- **Password**: VMURUGAN_ADMIN_2025
- **Role**: admin

### **Test Customer**
- **Phone**: 9876543210
- **Password**: test123
- **Customer ID**: VM000001
- **Role**: customer

---

## 🎯 **Development Workflow**

### **1. Start Development**
```bash
cd server
npm run dev                # Start with auto-reload
```

### **2. Make Changes**
- Edit code files
- Server auto-reloads
- Test changes immediately

### **3. Test Changes**
```bash
npm run test-local         # Quick integration test
npm test                   # Unit tests
```

### **4. Debug Issues**
```bash
npm run logs               # View server logs
# Check browser console for frontend issues
# Use Swagger UI for API testing
```

---

## 📚 **Documentation**

| Document | Purpose |
|----------|---------|
| **LOCAL_TESTING_GUIDE.md** | Detailed setup instructions |
| **DEPLOYMENT_GUIDE.md** | Production deployment |
| **MIGRATION_COMPLETE.md** | Migration summary |
| **Swagger UI** | Interactive API docs |

---

## 🆘 **Getting Help**

### **Check These First**
1. **Server Running**: http://localhost:3000/health
2. **Database Connected**: Check server logs
3. **Environment**: Verify .env file
4. **Ports**: Ensure 3000 and 1433 are available

### **Debug Commands**
```bash
# Check server status
npm run health

# View detailed logs
npm run logs

# Test database connection
sqlcmd -S localhost -U sa -P YourPassword

# Restart everything
npm run clean && npm run local-setup
```

### **Common Solutions**
- **Restart SQL Server service**
- **Update .env with correct password**
- **Check firewall settings**
- **Verify Node.js version (16+)**

---

## ✅ **Success Checklist**

- [ ] SQL Server running and accessible
- [ ] Server starts without errors: `npm run dev`
- [ ] Health check passes: http://localhost:3000/health
- [ ] Swagger docs load: http://localhost:3000/api-docs
- [ ] Admin login works: 9999999999 / VMURUGAN_ADMIN_2025
- [ ] Test customer login works: 9876543210 / test123
- [ ] Admin portal loads: http://localhost:3000/admin
- [ ] Integration tests pass: `npm run test-local`
- [ ] Flutter app connects to API
- [ ] Database operations work correctly

---

## 🎉 **You're Ready!**

Once all tests pass, your local development environment is fully functional and ready for:

- **API Development**: Add new endpoints
- **Frontend Development**: Connect Flutter app
- **Testing**: Comprehensive test coverage
- **Debugging**: Full logging and monitoring
- **Production Prep**: Ready for deployment

**Happy coding! 🚀**
