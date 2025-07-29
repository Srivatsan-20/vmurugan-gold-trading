// =====================================================
// Test Platform Fix - Verify Web Compatibility
// =====================================================

import 'package:flutter/material.dart';
import 'core/services/customer_service.dart';
import 'core/utils/platform_utils.dart';

class TestPlatformFix extends StatefulWidget {
  const TestPlatformFix({Key? key}) : super(key: key);

  @override
  State<TestPlatformFix> createState() => _TestPlatformFixState();
}

class _TestPlatformFixState extends State<TestPlatformFix> {
  Map<String, dynamic>? deviceInfo;
  Map<String, dynamic>? platformInfo;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _testPlatformFunctions();
  }

  Future<void> _testPlatformFunctions() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Test platform utils
      final pInfo = PlatformUtils.getPlatformInfo();
      
      // Test device info (this was causing the error before)
      final dInfo = await CustomerService.getDeviceInfo();
      
      setState(() {
        platformInfo = pInfo;
        deviceInfo = dInfo;
        isLoading = false;
      });
      
      print('✅ Platform test successful!');
      print('Platform: ${PlatformUtils.platformName}');
      print('Is Web: ${PlatformUtils.platformName == 'web'}');
      
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print('❌ Platform test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Fix Test'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Compatibility Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❌ Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(error!),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Platform Info Card
                      Card(
                        color: Colors.green.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✅ Platform Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (platformInfo != null)
                                ...platformInfo!.entries.map((entry) => 
                                  Text('${entry.key}: ${entry.value}')
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Device Info Card
                      Card(
                        color: Colors.blue.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✅ Device Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (deviceInfo != null)
                                ...deviceInfo!.entries.map((entry) => 
                                  Text('${entry.key}: ${entry.value}')
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Test Registration Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _testRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Test Registration (Device Info)', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testRegistration() async {
    try {
      print('🧪 Testing registration with device info...');
      
      // This should now work without Platform errors
      final deviceInfo = await CustomerService.getDeviceInfo();
      print('Device info for registration: $deviceInfo');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Device info collection successful! Registration would work.'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ Registration test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Registration test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
