// =====================================================
// VMUrugan Gold Trading - Local Testing Script
// =====================================================

const axios = require('axios');
const colors = require('colors');

const BASE_URL = 'http://localhost:3000';
const API_URL = `${BASE_URL}/api`;

let adminToken = null;
let customerToken = null;
let customerId = null;
let transactionId = null;
let schemeId = null;

console.log('🧪 VMUrugan Gold Trading - Local API Testing'.cyan.bold);
console.log('=============================================='.cyan);

async function runTests() {
  try {
    console.log('\n📋 Starting comprehensive API tests...\n');

    // Test 1: Health Check
    await testHealthCheck();

    // Test 2: Admin Authentication
    await testAdminLogin();

    // Test 3: Customer Registration
    await testCustomerRegistration();

    // Test 4: Customer Login
    await testCustomerLogin();

    // Test 5: Customer Profile
    await testCustomerProfile();

    // Test 6: Customer Validation
    await testCustomerValidation();

    // Test 7: Transaction Creation
    await testTransactionCreation();

    // Test 8: Transaction Status Update
    await testTransactionStatusUpdate();

    // Test 9: Get Customer Transactions
    await testGetCustomerTransactions();

    // Test 10: Scheme Creation
    await testSchemeCreation();

    // Test 11: Scheme Payment
    await testSchemePayment();

    // Test 12: Admin Dashboard
    await testAdminDashboard();

    // Test 13: Analytics Logging
    await testAnalyticsLogging();

    // Test 14: Logout
    await testLogout();

    console.log('\n🎉 All tests completed successfully!'.green.bold);
    console.log('\n📊 Test Summary:'.cyan.bold);
    console.log('✅ Health Check');
    console.log('✅ Admin Authentication');
    console.log('✅ Customer Registration');
    console.log('✅ Customer Login');
    console.log('✅ Customer Profile');
    console.log('✅ Customer Validation');
    console.log('✅ Transaction Management');
    console.log('✅ Scheme Management');
    console.log('✅ Admin Dashboard');
    console.log('✅ Analytics Logging');
    console.log('✅ Logout');

    console.log('\n🌐 Access URLs:'.cyan.bold);
    console.log(`Health Check:    ${BASE_URL}/health`.white);
    console.log(`API Docs:        ${BASE_URL}/api-docs`.white);
    console.log(`Admin Portal:    ${BASE_URL}/admin`.white);

  } catch (error) {
    console.error('\n❌ Test failed:'.red.bold, error.message);
    process.exit(1);
  }
}

async function testHealthCheck() {
  console.log('1️⃣ Testing Health Check...'.yellow);
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    if (response.data.status === 'OK') {
      console.log('   ✅ Health check passed'.green);
      console.log(`   📊 Service: ${response.data.service}`.gray);
      console.log(`   🔢 Version: ${response.data.version}`.gray);
      console.log(`   🗄️  Database: ${response.data.database}`.gray);
    } else {
      throw new Error('Health check failed');
    }
  } catch (error) {
    console.error('   ❌ Health check failed:'.red, error.message);
    throw error;
  }
}

async function testAdminLogin() {
  console.log('\n2️⃣ Testing Admin Login...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      phone: '9999999999',
      password: 'VMURUGAN_ADMIN_2025'
    });

    if (response.data.success && response.data.data.role === 'admin') {
      adminToken = response.data.data.accessToken;
      console.log('   ✅ Admin login successful'.green);
      console.log(`   👤 User: ${response.data.data.name}`.gray);
      console.log(`   🔑 Role: ${response.data.data.role}`.gray);
    } else {
      throw new Error('Admin login failed');
    }
  } catch (error) {
    console.error('   ❌ Admin login failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testCustomerRegistration() {
  console.log('\n3️⃣ Testing Customer Registration...'.yellow);
  try {
    const testPhone = `987654${Date.now().toString().slice(-4)}`;
    const response = await axios.post(`${API_URL}/auth/register`, {
      phone: testPhone,
      email: `test${Date.now()}@local.com`,
      password: 'test123',
      name: 'Local Test User',
      address: 'Local Test Address, Chennai, Tamil Nadu',
      panCard: 'ABCDE0000F'
    });

    if (response.data.success) {
      customerId = response.data.data.customerId;
      console.log('   ✅ Customer registration successful'.green);
      console.log(`   🆔 Customer ID: ${customerId}`.gray);
      console.log(`   📱 Phone: ${testPhone}`.gray);
    } else {
      throw new Error('Customer registration failed');
    }
  } catch (error) {
    console.error('   ❌ Customer registration failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testCustomerLogin() {
  console.log('\n4️⃣ Testing Customer Login...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      phone: '9876543210',
      password: 'test123'
    });

    if (response.data.success && response.data.data.role === 'customer') {
      customerToken = response.data.data.accessToken;
      if (!customerId) customerId = response.data.data.customerId;
      console.log('   ✅ Customer login successful'.green);
      console.log(`   👤 Customer: ${response.data.data.name}`.gray);
      console.log(`   🆔 Customer ID: ${response.data.data.customerId}`.gray);
    } else {
      throw new Error('Customer login failed');
    }
  } catch (error) {
    console.error('   ❌ Customer login failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testCustomerProfile() {
  console.log('\n5️⃣ Testing Customer Profile...'.yellow);
  try {
    const response = await axios.get(`${API_URL}/customers/profile`, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Customer profile retrieved'.green);
      console.log(`   📊 Total Invested: ₹${response.data.data.total_invested}`.gray);
      console.log(`   🥇 Total Gold: ${response.data.data.total_gold}g`.gray);
    } else {
      throw new Error('Failed to get customer profile');
    }
  } catch (error) {
    console.error('   ❌ Customer profile failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testCustomerValidation() {
  console.log('\n6️⃣ Testing Customer Validation...'.yellow);
  try {
    const response = await axios.get(`${API_URL}/customers/validate/9876543210`);

    if (response.data.success) {
      console.log('   ✅ Customer validation successful'.green);
      console.log(`   🆔 Found Customer: ${response.data.data.customer_id}`.gray);
    } else {
      throw new Error('Customer validation failed');
    }
  } catch (error) {
    console.error('   ❌ Customer validation failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testTransactionCreation() {
  console.log('\n7️⃣ Testing Transaction Creation...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/transactions`, {
      customerId: customerId,
      type: 'BUY',
      amount: 5000.00,
      goldGrams: 0.75,
      goldPricePerGram: 6666.67,
      paymentMethod: 'UPI',
      gatewayTransactionId: `TEST_${Date.now()}`,
      notes: 'Local test transaction'
    }, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      transactionId = response.data.data.transactionId;
      console.log('   ✅ Transaction created successfully'.green);
      console.log(`   🆔 Transaction ID: ${transactionId}`.gray);
      console.log(`   💰 Amount: ₹${response.data.data.amount}`.gray);
    } else {
      throw new Error('Transaction creation failed');
    }
  } catch (error) {
    console.error('   ❌ Transaction creation failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testTransactionStatusUpdate() {
  console.log('\n8️⃣ Testing Transaction Status Update...'.yellow);
  try {
    const response = await axios.put(`${API_URL}/transactions/${transactionId}/status`, {
      status: 'SUCCESS',
      gatewayTransactionId: `SUCCESS_${Date.now()}`
    }, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Transaction status updated'.green);
      console.log(`   📊 Status: ${response.data.data.status}`.gray);
    } else {
      throw new Error('Transaction status update failed');
    }
  } catch (error) {
    console.error('   ❌ Transaction status update failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testGetCustomerTransactions() {
  console.log('\n9️⃣ Testing Get Customer Transactions...'.yellow);
  try {
    const response = await axios.get(`${API_URL}/transactions/customer/${customerId}?limit=5`, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Customer transactions retrieved'.green);
      console.log(`   📊 Transaction Count: ${response.data.data.transactions.length}`.gray);
    } else {
      throw new Error('Failed to get customer transactions');
    }
  } catch (error) {
    console.error('   ❌ Get customer transactions failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testSchemeCreation() {
  console.log('\n🔟 Testing Scheme Creation...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/schemes`, {
      customerId: customerId,
      schemeType: 'monthly_sip',
      monthlyAmount: 3000.00,
      durationMonths: 12,
      startDate: new Date().toISOString()
    }, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      schemeId = response.data.data.schemeId;
      console.log('   ✅ Scheme created successfully'.green);
      console.log(`   🆔 Scheme ID: ${schemeId}`.gray);
      console.log(`   💰 Monthly Amount: ₹${response.data.data.monthlyAmount}`.gray);
    } else {
      throw new Error('Scheme creation failed');
    }
  } catch (error) {
    console.error('   ❌ Scheme creation failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testSchemePayment() {
  console.log('\n1️⃣1️⃣ Testing Scheme Payment...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/schemes/${schemeId}/payment`, {
      amount: 3000.00,
      goldGrams: 0.45,
      goldPricePerGram: 6666.67,
      paymentMethod: 'UPI',
      gatewayTransactionId: `SCHEME_${Date.now()}`
    }, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Scheme payment processed'.green);
      console.log(`   📊 Paid Months: ${response.data.data.paidMonths}`.gray);
      console.log(`   🥇 Gold Accumulated: ${response.data.data.goldAccumulated}g`.gray);
    } else {
      throw new Error('Scheme payment failed');
    }
  } catch (error) {
    console.error('   ❌ Scheme payment failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testAdminDashboard() {
  console.log('\n1️⃣2️⃣ Testing Admin Dashboard...'.yellow);
  try {
    const response = await axios.get(`${API_URL}/admin/dashboard`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Admin dashboard data retrieved'.green);
      console.log(`   👥 Total Customers: ${response.data.data.stats.total_customers}`.gray);
      console.log(`   💰 Total Revenue: ₹${response.data.data.stats.total_revenue}`.gray);
    } else {
      throw new Error('Admin dashboard failed');
    }
  } catch (error) {
    console.error('   ❌ Admin dashboard failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testAnalyticsLogging() {
  console.log('\n1️⃣3️⃣ Testing Analytics Logging...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/analytics`, {
      event: 'local_test_event',
      data: {
        test_type: 'automated_local_test',
        timestamp: new Date().toISOString(),
        success: true
      }
    }, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Analytics event logged'.green);
    } else {
      throw new Error('Analytics logging failed');
    }
  } catch (error) {
    console.error('   ❌ Analytics logging failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testLogout() {
  console.log('\n1️⃣4️⃣ Testing Logout...'.yellow);
  try {
    const response = await axios.post(`${API_URL}/auth/logout`, {}, {
      headers: { Authorization: `Bearer ${customerToken}` }
    });

    if (response.data.success) {
      console.log('   ✅ Logout successful'.green);
    } else {
      throw new Error('Logout failed');
    }
  } catch (error) {
    console.error('   ❌ Logout failed:'.red, error.response?.data?.message || error.message);
    throw error;
  }
}

// Run tests
runTests().catch(error => {
  console.error('\n💥 Test suite failed:'.red.bold, error.message);
  console.log('\n🔧 Troubleshooting:'.yellow.bold);
  console.log('1. Ensure the server is running: npm run dev');
  console.log('2. Check database connection');
  console.log('3. Verify .env configuration');
  console.log('4. Check server logs for errors');
  process.exit(1);
});
