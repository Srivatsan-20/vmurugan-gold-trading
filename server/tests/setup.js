// =====================================================
// VMUrugan Gold Trading - Test Setup
// =====================================================

const { execSync } = require('child_process');
require('dotenv').config();

// Global test configuration
jest.setTimeout(30000);

// Setup test database before all tests
beforeAll(async () => {
  console.log('🧪 Setting up test environment...');
  
  try {
    // Ensure test database is set up
    console.log('📊 Initializing test database...');
    
    // You can add specific test database setup here if needed
    // For now, we'll use the same database as development
    
    console.log('✅ Test environment ready');
  } catch (error) {
    console.error('❌ Test setup failed:', error.message);
    throw error;
  }
});

// Cleanup after all tests
afterAll(async () => {
  console.log('🧹 Cleaning up test environment...');
  
  try {
    // Add any cleanup logic here
    console.log('✅ Test cleanup completed');
  } catch (error) {
    console.error('❌ Test cleanup failed:', error.message);
  }
});

// Global error handler for unhandled promises
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Suppress console.log during tests (optional)
// global.console = {
//   ...console,
//   log: jest.fn(),
//   debug: jest.fn(),
//   info: jest.fn(),
//   warn: jest.fn(),
//   error: jest.fn(),
// };
