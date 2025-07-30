// =====================================================
// VMUrugan Gold Trading - Migration Service
// Handles transition from Firebase to Backend API
// =====================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_api_service.dart';
import '../config/api_config.dart';

class MigrationService {
  static const String _migrationStatusKey = 'migration_status';
  static const String _userMigrationKey = 'user_migration_status';
  
  // Migration phases
  static const String phaseFirebaseOnly = 'firebase_only';
  static const String phaseDualMode = 'dual_mode';
  static const String phaseBackendOnly = 'backend_only';
  
  static String _currentPhase = phaseBackendOnly;
  static bool _migrationInProgress = false;

  // Get current migration phase
  static String get currentPhase => _currentPhase;
  static bool get isFirebaseOnly => _currentPhase == phaseFirebaseOnly;
  static bool get isDualMode => _currentPhase == phaseDualMode;
  static bool get isBackendOnly => _currentPhase == phaseBackendOnly;
  static bool get migrationInProgress => _migrationInProgress;

  // Initialize migration service
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Force backend-only mode - no Firebase!
      _currentPhase = phaseBackendOnly;
      await prefs.setString(_migrationStatusKey, phaseBackendOnly);

      print('🔄 Migration Service Initialized');
      print('📊 Current Phase: $_currentPhase (FORCED BACKEND-ONLY)');

      // Check backend availability
      await _checkBackendAvailability();
    } catch (e) {
      print('❌ Migration service initialization failed: $e');
      _currentPhase = phaseBackendOnly;
    }
  }

  // Check if backend is available
  static Future<bool> _checkBackendAvailability() async {
    try {
      final healthCheck = await BackendApiService.checkServerHealth();
      final isAvailable = healthCheck['success'] == true;
      
      print('🏥 Backend Health Check: ${isAvailable ? 'HEALTHY' : 'UNAVAILABLE'}');
      
      if (!isAvailable && isBackendOnly) {
        print('⚠️ Backend unavailable but in backend-only mode. Falling back to dual mode.');
        await setMigrationPhase(phaseDualMode);
      }
      
      return isAvailable;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }

  // Set migration phase
  static Future<void> setMigrationPhase(String phase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_migrationStatusKey, phase);
      _currentPhase = phase;
      
      print('🔄 Migration phase changed to: $phase');
      
      // Log analytics
      await logMigrationEvent('phase_changed', {'new_phase': phase});
    } catch (e) {
      print('❌ Failed to set migration phase: $e');
    }
  }

  // Start migration process
  static Future<Map<String, dynamic>> startMigration() async {
    if (_migrationInProgress) {
      return {
        'success': false,
        'message': 'Migration already in progress',
      };
    }

    try {
      _migrationInProgress = true;
      print('🚀 Starting migration process...');

      // Phase 1: Check backend availability
      final backendAvailable = await _checkBackendAvailability();
      if (!backendAvailable) {
        return {
          'success': false,
          'message': 'Backend server is not available. Please ensure the server is running.',
          'instructions': [
            '1. Start the backend server (npm run dev)',
            '2. Check network connectivity',
            '3. Verify server configuration',
            '4. Try again',
          ],
        };
      }

      // Phase 2: Switch to dual mode
      await setMigrationPhase(phaseDualMode);

      // Phase 3: Test backend authentication
      final authTest = await _testBackendAuthentication();
      if (!authTest['success']) {
        return authTest;
      }

      // Phase 4: Migration successful
      print('✅ Migration completed successfully');
      await logMigrationEvent('migration_completed', {
        'timestamp': DateTime.now().toIso8601String(),
        'phase': _currentPhase,
      });

      return {
        'success': true,
        'message': 'Migration completed successfully',
        'phase': _currentPhase,
      };

    } catch (e) {
      print('❌ Migration failed: $e');
      return {
        'success': false,
        'message': 'Migration failed: $e',
      };
    } finally {
      _migrationInProgress = false;
    }
  }

  // Test backend authentication
  static Future<Map<String, dynamic>> _testBackendAuthentication() async {
    try {
      print('🔐 Testing backend authentication...');

      // Try to login with test credentials
      final testLogin = await BackendApiService.loginCustomer(
        phone: ApiConfig.testCustomer['phone'],
        password: 'test123', // Default test password
      );

      if (testLogin['success'] == true) {
        print('✅ Backend authentication test successful');
        await BackendApiService.logoutCustomer();
        return {'success': true};
      } else {
        print('❌ Backend authentication test failed');
        return {
          'success': false,
          'message': 'Backend authentication test failed',
          'details': testLogin['message'],
        };
      }
    } catch (e) {
      print('❌ Backend authentication test error: $e');
      return {
        'success': false,
        'message': 'Backend authentication test error: $e',
      };
    }
  }

  // Complete migration to backend-only
  static Future<Map<String, dynamic>> completeBackendMigration() async {
    try {
      print('🎯 Completing migration to backend-only mode...');

      // Final backend availability check
      final backendAvailable = await _checkBackendAvailability();
      if (!backendAvailable) {
        return {
          'success': false,
          'message': 'Cannot complete migration: Backend is not available',
        };
      }

      // Switch to backend-only mode
      await setMigrationPhase(phaseBackendOnly);

      print('✅ Migration to backend-only mode completed');
      await logMigrationEvent('backend_only_completed', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Successfully migrated to backend-only mode',
        'phase': phaseBackendOnly,
      };

    } catch (e) {
      print('❌ Failed to complete backend migration: $e');
      return {
        'success': false,
        'message': 'Failed to complete backend migration: $e',
      };
    }
  }

  // Rollback to Firebase
  static Future<Map<String, dynamic>> rollbackToFirebase() async {
    try {
      print('🔙 Rolling back to Firebase...');

      await setMigrationPhase(phaseFirebaseOnly);
      BackendApiService.clearAuth();

      print('✅ Rollback to Firebase completed');
      await logMigrationEvent('rollback_to_firebase', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Successfully rolled back to Firebase',
        'phase': phaseFirebaseOnly,
      };

    } catch (e) {
      print('❌ Rollback failed: $e');
      return {
        'success': false,
        'message': 'Rollback failed: $e',
      };
    }
  }

  // =====================================================
  // SERVICE ROUTING METHODS
  // =====================================================

  // Route customer registration (Backend-only)
  static Future<Map<String, dynamic>> registerCustomer({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    String? deviceId,
    String? password,
  }) async {
    // Always use backend API (Firebase removed)
    return await BackendApiService.registerCustomer(
      phone: phone,
      email: email,
      password: password ?? 'test123', // Default password for new users
      name: name,
      address: address,
      panCard: panCard,
      deviceId: deviceId,
    );
  }

  // Route customer validation (Backend-only)
  static Future<Map<String, dynamic>> validateCustomer(String phone) async {
    // Always use backend API (Firebase removed)
    return await BackendApiService.validateCustomer(phone);
  }

  // Route transaction creation (Backend-only)
  static Future<Map<String, dynamic>> createTransaction({
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String type,
    required double amount,
    required double goldGrams,
    required double goldPricePerGram,
    required String paymentMethod,
    String? gatewayTransactionId,
    String? deviceInfo,
    String? location,
  }) async {
    // Always use backend API (Firebase removed)
    return await BackendApiService.createTransaction(
      customerId: customerId,
      type: type,
      amount: amount,
      goldGrams: goldGrams,
      goldPricePerGram: goldPricePerGram,
      paymentMethod: paymentMethod,
      gatewayTransactionId: gatewayTransactionId,
      deviceInfo: deviceInfo,
      location: location,
    );
  }

  // Route analytics logging (Backend-only)
  static Future<void> logAnalytics({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    // Always use backend API (Firebase removed)
    await BackendApiService.logAnalytics(event: event, data: data);
  }

  // Log migration-specific events
  static Future<void> logMigrationEvent(String event, Map<String, dynamic> data) async {
    final migrationData = {
      ...data,
      'migration_phase': _currentPhase,
      'migration_in_progress': _migrationInProgress,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await logAnalytics(event: 'migration_$event', data: migrationData);
  }

  // Get migration status
  static Map<String, dynamic> getMigrationStatus() {
    return {
      'current_phase': _currentPhase,
      'migration_in_progress': _migrationInProgress,
      'is_firebase_only': isFirebaseOnly,
      'is_dual_mode': isDualMode,
      'is_backend_only': isBackendOnly,
      'backend_configured': BackendApiService.isConfigured,
      'firebase_configured': false, // Firebase removed
    };
  }
}
